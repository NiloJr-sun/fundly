-- Shared spaces C0 prototype (docs/SHARED_SPACES_C0_PLAN.md). Disposable,
-- local only: applied by the C0 local stack in this folder. Creates c0_*
-- stand-ins for spaces, memberships and records; nothing here is Fundly's
-- real schema.

create schema if not exists c0_private;
revoke all on schema c0_private from public, anon;
grant usage on schema c0_private to authenticated;

create table public.c0_spaces (
  id uuid primary key,
  name text not null check (char_length(btrim(name)) between 1 and 40),
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- PowerSync needs an `id` per synced row, so memberships have their own.
create table public.c0_space_members (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.c0_spaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner', 'editor', 'viewer')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (space_id, user_id)
);
create index c0_space_members_user on public.c0_space_members(user_id);

create table public.c0_entries (
  id uuid primary key,
  space_id uuid not null references public.c0_spaces(id) on delete cascade,
  label text not null check (char_length(label) between 1 and 60),
  amount_minor bigint not null check (amount_minor > 0),
  created_by uuid not null references auth.users(id),
  updated_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revision bigint not null default 1 check (revision > 0)
);
create index c0_entries_space on public.c0_entries(space_id);

-- Backend only: never published, never readable by clients.
create table public.c0_receipts (
  actor uuid not null,
  batch_id uuid not null,
  space_id uuid not null,
  applied_at timestamptz not null default now(),
  primary key (actor, batch_id)
);

-- The caller's role in a space, or null. SECURITY DEFINER so policies on
-- c0_space_members can use it without recursing into their own RLS.
create function c0_private.role_in(p_space uuid)
returns text language sql stable security definer set search_path = '' as $$
  select role from public.c0_space_members
  where space_id = p_space and user_id = (select auth.uid());
$$;
revoke all on function c0_private.role_in(uuid) from public, anon;
grant execute on function c0_private.role_in(uuid) to authenticated;

alter table public.c0_spaces enable row level security;
alter table public.c0_space_members enable row level security;
alter table public.c0_entries enable row level security;
alter table public.c0_receipts enable row level security;
create policy c0_read_member on public.c0_spaces for select to authenticated
  using (c0_private.role_in(id) is not null);
create policy c0_read_member on public.c0_space_members for select to authenticated
  using (c0_private.role_in(space_id) is not null);
create policy c0_read_member on public.c0_entries for select to authenticated
  using (c0_private.role_in(space_id) is not null);
revoke all on public.c0_spaces, public.c0_space_members, public.c0_entries,
  public.c0_receipts from anon, authenticated;
grant select on public.c0_spaces, public.c0_space_members, public.c0_entries
  to authenticated;

create function c0_private.require_owner(p_space uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if c0_private.role_in(p_space) is distinct from 'owner' then
    raise exception 'Only an owner can do this' using errcode = '42501';
  end if;
end;
$$;
revoke all on function c0_private.require_owner(uuid) from public, anon, authenticated;

-- Creates a space owned by the caller.
create function public.c0_create_space(p_id uuid, p_name text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := (select auth.uid());
begin
  if actor is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  insert into public.c0_spaces(id, name, created_by) values (p_id, btrim(p_name), actor);
  insert into public.c0_space_members(space_id, user_id, role) values (p_id, actor, 'owner');
end;
$$;

-- Adds a member or changes their role (owner only). A space keeps an owner.
create function public.c0_set_member(p_space uuid, p_user uuid, p_role text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform c0_private.require_owner(p_space);
  perform pg_advisory_xact_lock(hashtextextended('c0:' || p_space::text, 0));
  insert into public.c0_space_members(space_id, user_id, role)
  values (p_space, p_user, p_role)
  on conflict (space_id, user_id)
  do update set role = excluded.role, updated_at = now();
  if not exists (select 1 from public.c0_space_members
                 where space_id = p_space and role = 'owner') then
    raise exception 'A space needs an owner' using errcode = '23514';
  end if;
end;
$$;

-- Removes a member (owner), or the caller leaves. A space keeps an owner.
create function public.c0_remove_member(p_space uuid, p_user uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if p_user is distinct from (select auth.uid()) then
    perform c0_private.require_owner(p_space);
  elsif c0_private.role_in(p_space) is null then
    raise exception 'Not a member' using errcode = '42501';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('c0:' || p_space::text, 0));
  delete from public.c0_space_members where space_id = p_space and user_id = p_user;
  if not exists (select 1 from public.c0_space_members
                 where space_id = p_space and role = 'owner') then
    raise exception 'A space needs an owner' using errcode = '23514';
  end if;
end;
$$;

-- Deletes a space and everything in it (owner only); used by check cleanup.
create function public.c0_delete_space(p_space uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform c0_private.require_owner(p_space);
  delete from public.c0_spaces where id = p_space;
end;
$$;

-- One atomic upload batch into one space. Owners and editors only. Writes to
-- a space are serialized; a batch already applied for this caller is a no-op.
-- p_ops: [{"op": "PUT"|"PATCH"|"DELETE", "id": uuid, "data": {...},
--          "old": {"revision": n}}]
create function public.c0_apply_batch(p_batch_id uuid, p_space_id uuid, p_ops jsonb)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_actor uuid := (select auth.uid());
  operation jsonb;
  data jsonb;
  affected integer;
begin
  if v_actor is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_ops is null or jsonb_typeof(p_ops) <> 'array'
     or jsonb_array_length(p_ops) not between 1 and 100 then
    raise exception 'Expected 1-100 operations' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('c0:' || p_space_id::text, 0));
  if exists (select 1 from public.c0_receipts
             where actor = v_actor and batch_id = p_batch_id) then
    return;
  end if;
  if c0_private.role_in(p_space_id) is null
     or c0_private.role_in(p_space_id) not in ('owner', 'editor') then
    raise exception 'Not allowed to write to this space' using errcode = '42501';
  end if;

  for operation in select value from jsonb_array_elements(p_ops) loop
    data := coalesce(operation->'data', '{}'::jsonb);
    case operation->>'op'
      when 'PUT' then
        insert into public.c0_entries(id, space_id, label, amount_minor,
                                      created_by, updated_by)
        values ((operation->>'id')::uuid, p_space_id, data->>'label',
                (data->>'amount_minor')::bigint, v_actor, v_actor);
      when 'PATCH' then
        update public.c0_entries set
          label = coalesce(data->>'label', label),
          amount_minor = coalesce((data->>'amount_minor')::bigint, amount_minor),
          updated_by = v_actor, updated_at = now(), revision = revision + 1
        where id = (operation->>'id')::uuid and space_id = p_space_id
          and revision = (operation->'old'->>'revision')::bigint;
        get diagnostics affected = row_count;
        if affected <> 1 then
          raise exception 'Missing entry or revision conflict' using errcode = '40001';
        end if;
      when 'DELETE' then
        delete from public.c0_entries
        where id = (operation->>'id')::uuid and space_id = p_space_id
          and revision = (operation->'old'->>'revision')::bigint;
        get diagnostics affected = row_count;
        if affected <> 1 then
          raise exception 'Missing entry or revision conflict' using errcode = '40001';
        end if;
      else
        raise exception 'Unsupported operation' using errcode = '22023';
    end case;
  end loop;
  insert into public.c0_receipts(actor, batch_id, space_id)
  values (v_actor, p_batch_id, p_space_id);
end;
$$;

revoke all on function public.c0_create_space(uuid, text),
  public.c0_set_member(uuid, uuid, text), public.c0_remove_member(uuid, uuid),
  public.c0_delete_space(uuid), public.c0_apply_batch(uuid, uuid, jsonb)
  from public, anon;
grant execute on function public.c0_create_space(uuid, text),
  public.c0_set_member(uuid, uuid, text), public.c0_remove_member(uuid, uuid),
  public.c0_delete_space(uuid), public.c0_apply_batch(uuid, uuid, jsonb)
  to authenticated;

