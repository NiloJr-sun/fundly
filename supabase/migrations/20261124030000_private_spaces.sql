-- Shared spaces C2.1 (docs/SHARED_SPACES_C2_PLAN.md): private spaces.
--
-- 1. owner_id becomes Personal-only (Decision C2-1): for a Personal space's
--    records it stays the user's id; for any other space it is null. The
--    existing stream (WHERE owner_id = auth.user_id()) therefore keeps sending
--    apps 1.2.x exactly their Personal records and never another space's.
-- 2. Online-only RPCs to create and rename spaces (Decisions C2-3, C2-5, C2-6).
-- 3. spaces and space_members are readable by the PowerSync replication role
--    and published (powersync/publication.sql) for the new opt-in streams.
-- Write protocol 1 is unchanged.

-- 1. Personal-only owner_id -------------------------------------------------

-- The legacy owner_id of a record in `space`: the Personal space's user, or
-- null for any other space.
create function fundly_private.legacy_owner(space uuid)
returns uuid language sql stable set search_path = '' as $$
  select s.personal_of from public.spaces s where s.id = space
$$;

create or replace function fundly_private.bridge_space_owner()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  writer uuid := nullif(current_setting('fundly.actor', true), '')::uuid;
  personal uuid;
begin
  if tg_op = 'INSERT' then
    new.space_id := coalesce(new.space_id, new.owner_id);
    -- A user's first record creates their Personal space (C1.1).
    if new.owner_id is not null and new.space_id = new.owner_id then
      perform fundly_private.ensure_personal_space(new.owner_id);
    end if;
    personal := fundly_private.legacy_owner(new.space_id);
    if new.owner_id is not null and new.owner_id is distinct from personal then
      raise exception 'owner_id must be the Personal space''s user or null' using errcode = '23514';
    end if;
    new.owner_id := personal;
    new.created_by := coalesce(new.created_by, writer, personal);
    new.updated_by := coalesce(new.updated_by, new.created_by);
  else
    new.updated_by := coalesce(writer, new.updated_by);
  end if;
  return new;
end;
$$;

do $$
declare table_name text;
begin
  foreach table_name in array array[
    'custom_account_types', 'accounts', 'categories', 'transactions', 'monthly_plans'
  ] loop
    execute format('alter table public.%I drop constraint %I, alter column owner_id drop not null,
      add constraint %I check (owner_id is null or owner_id = space_id)',
      table_name, table_name || '_owner_is_space', table_name || '_owner_is_personal');
  end loop;
end;
$$;

-- Tombstones of a non-Personal space's records have no owner.
alter table public.fundly_deleted_records alter column owner_id drop not null;

-- 2. Creating and renaming spaces -------------------------------------------

-- A space name: trimmed, 1-40 UTF-16 units (the account-name rule).
create function fundly_private.space_name(value text)
returns text language plpgsql immutable set search_path = '' as $$
declare name text := fundly_private.trim_text(value);
begin
  if name is null or name = '' or fundly_private.utf16_length(name) > 40 then
    raise exception 'invalid_name' using errcode = 'P0001';
  end if;
  return name;
end;
$$;

-- Refuses when `actor` already owns another space with this name, ignoring
-- ASCII case (Decision C2-6).
create function fundly_private.check_space_name(actor uuid, candidate text, except_space uuid)
returns void language plpgsql stable set search_path = '' as $$
begin
  if exists (select 1 from public.spaces s join public.space_members m
      on m.space_id = s.id and m.user_id = actor and m.role = 'owner'
    where s.id is distinct from except_space
      and fundly_private.import_name_key(s.name) = fundly_private.import_name_key(candidate)) then
    raise exception 'name_taken' using errcode = 'P0001';
  end if;
end;
$$;

create function fundly_private.space_wire(value public.spaces)
returns jsonb language sql stable strict set search_path = '' as $$
  select jsonb_build_object('id', value.id, 'name', value.name, 'personal', value.personal_of is not null,
    'revision', value.revision::text)
$$;

-- Creates a space owned by the caller (online only). Retrying the same id and
-- name returns the space; another use of the id is refused. At most 10 owned
-- spaces, Personal included (Decision C2-5).
create function public.fundly_create_space(space_id uuid, name text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := auth.uid();
  space_name text;
  existing public.spaces;
  created public.spaces;
begin
  if actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  if space_id is null then raise exception 'invalid_request' using errcode = '22023'; end if;
  space_name := fundly_private.space_name(name);
  -- One space change per user at a time keeps the limit and names exact.
  perform pg_advisory_xact_lock(hashtextextended('fundly:spaces:' || actor::text, 0));
  perform fundly_private.ensure_personal_space(actor);
  select * into existing from public.spaces s where s.id = fundly_create_space.space_id;
  if found then
    if existing.created_by = actor and existing.personal_of is null and existing.name = space_name then
      return fundly_private.space_wire(existing);
    end if;
    raise exception 'space_id_unavailable' using errcode = 'P0001';
  end if;
  if (select count(*) from public.space_members m where m.user_id = actor and m.role = 'owner') >= 10 then
    raise exception 'space_limit_reached' using errcode = 'P0001';
  end if;
  perform fundly_private.check_space_name(actor, space_name, null);
  insert into public.spaces(id, name, created_by) values (fundly_create_space.space_id, space_name, actor)
    returning * into created;
  insert into public.space_members(space_id, user_id, role)
    values (fundly_create_space.space_id, actor, 'owner');
  return fundly_private.space_wire(created);
end;
$$;

-- Renames a space (owners only), checked against the revision the caller saw.
create function public.fundly_rename_space(space_id uuid, name text, expected_revision text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := auth.uid();
  space_name text;
  member_role text;
  previous public.spaces;
  renamed public.spaces;
begin
  if actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  if space_id is null then raise exception 'invalid_request' using errcode = '22023'; end if;
  space_name := fundly_private.space_name(name);
  perform pg_advisory_xact_lock(hashtextextended('fundly:spaces:' || actor::text, 0));
  member_role := fundly_private.space_role(fundly_rename_space.space_id, actor);
  if member_role is null then
    raise exception 'not_space_member' using errcode = 'P0001';
  elsif member_role <> 'owner' then
    raise exception 'space_owner_only' using errcode = 'P0001';
  end if;
  select * into previous from public.spaces s where s.id = fundly_rename_space.space_id for update;
  if previous.revision <> fundly_private.positive_bigint(to_jsonb(expected_revision)) then
    raise exception 'revision_conflict' using errcode = 'P0001',
      detail = jsonb_build_object('current_revision', previous.revision::text)::text;
  end if;
  perform fundly_private.check_space_name(actor, space_name, previous.id);
  update public.spaces s set name = space_name, updated_at = clock_timestamp(), revision = s.revision + 1
    where s.id = previous.id returning * into renamed;
  return fundly_private.space_wire(renamed);
end;
$$;

revoke all on function public.fundly_create_space(uuid, text), public.fundly_rename_space(uuid, text, text)
  from public, anon;
grant execute on function public.fundly_create_space(uuid, text), public.fundly_rename_space(uuid, text, text)
  to authenticated;

-- 3. Replication ---------------------------------------------------------------

-- The hosted PowerSync replication role (its name is per instance) gets the
-- same read access to the two space tables as to the record tables. No such
-- role exists locally, so this does nothing there.
do $$
declare replication_role text;
begin
  for replication_role in select rolname from pg_catalog.pg_roles
      where rolname like 'powersync\_%' and rolreplication loop
    execute format('grant select on public.spaces, public.space_members to %I', replication_role);
  end loop;
end;
$$;

revoke all on all functions in schema fundly_private from public, anon, authenticated, service_role;
