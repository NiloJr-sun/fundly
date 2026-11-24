-- Shared spaces C3.1 (docs/SHARED_SPACES_C3_PLAN.md): sharing.
--
-- Invites bound to an email (the owner shares the link; the app sends no
-- email), members' names and emails visible to each other, owners managing
-- roles and members, anyone leaving, owners deleting a space. Personal is
-- never shared or deleted. Every refusal is P0001 with a message: a final
-- rejection the apps log and move past (never 42501, which would block
-- their queue). Membership changes take the space's write lock, so they
-- serialize with that space's writes.

-- Members see each other's name and email (Decision C3-3) -------------------

alter table public.space_members add column email text, add column display_name text;

-- Copied from the member's sign-in when they join.
create function fundly_private.fill_member_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.email is null or new.display_name is null then
    select coalesce(new.email, lower(u.email)),
      coalesce(new.display_name, nullif(btrim(coalesce(u.raw_user_meta_data->>'full_name',
        u.raw_user_meta_data->>'name', '')), ''))
      into new.email, new.display_name
    from auth.users u where u.id = new.user_id;
  end if;
  return new;
end;
$$;
create trigger space_members_profile before insert on public.space_members
  for each row execute function fundly_private.fill_member_profile();

update public.space_members m set email = lower(u.email),
  display_name = nullif(btrim(coalesce(u.raw_user_meta_data->>'full_name',
    u.raw_user_meta_data->>'name', '')), '')
from auth.users u where u.id = m.user_id;

-- Invites (backend only) ---------------------------------------------------------

create table public.space_invites (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.spaces(id) on delete cascade,
  email text not null,
  role text not null,
  -- SHA-256 of the secret in the link; the secret itself is never stored.
  token_hash bytea not null unique,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  accepted_by uuid references auth.users(id) on delete set null,
  accepted_at timestamptz,
  declined_at timestamptz,
  revoked_at timestamptz,
  constraint space_invites_role check (role in ('editor', 'viewer')),
  constraint space_invites_email check (email = lower(btrim(email)) and email like '%_@_%'
    and char_length(email) <= 254),
  constraint space_invites_hash check (octet_length(token_hash) = 32)
);
create index space_invites_space on public.space_invites(space_id);
alter table public.space_invites enable row level security;
revoke all on public.space_invites from public, anon, authenticated, service_role;

-- Helpers --------------------------------------------------------------------------

-- Locks [space] for a membership change, refuses Personal and, unless
-- [any_member], anyone but an owner. Returns the caller's role.
create function fundly_private.manage_space(space uuid, actor uuid, any_member boolean default false)
returns text language plpgsql set search_path = '' as $$
declare member_role text;
begin
  if actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  if space is null then raise exception 'invalid_request' using errcode = '22023'; end if;
  perform pg_advisory_xact_lock(hashtextextended('fundly:' || space::text, 0));
  member_role := fundly_private.space_role(space, actor);
  if member_role is null then
    raise exception 'not_space_member' using errcode = 'P0001';
  end if;
  if fundly_private.legacy_owner(space) is not null then
    raise exception 'personal_space' using errcode = 'P0001';
  end if;
  if not any_member and member_role <> 'owner' then
    raise exception 'space_owner_only' using errcode = 'P0001';
  end if;
  return member_role;
end;
$$;

-- Refuses unless another owner would remain after [member] stops being one.
create function fundly_private.require_other_owner(space uuid, member uuid)
returns void language plpgsql stable set search_path = '' as $$
begin
  if not exists (select 1 from public.space_members m
      where m.space_id = space and m.role = 'owner' and m.user_id <> member) then
    raise exception 'last_owner' using errcode = 'P0001';
  end if;
end;
$$;

create function fundly_private.invite_hash(secret text)
returns bytea language plpgsql stable set search_path = '' as $$
begin
  if secret is null or secret !~ '^[0-9a-f]{64}$' then
    raise exception 'invite_unavailable' using errcode = 'P0001';
  end if;
  return sha256(convert_to(secret, 'UTF8'));
end;
$$;

-- The pending invite for [secret] addressed to the caller, locked. Another
-- email gets `invite_other_email` and learns nothing about the space; a used,
-- declined, revoked, expired or unknown invite is `invite_unavailable`.
create function fundly_private.claim_invite(secret text, actor uuid)
returns public.space_invites language plpgsql set search_path = '' as $$
declare
  invite public.space_invites;
  actor_email text;
begin
  if actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  select * into invite from public.space_invites i
    where i.token_hash = fundly_private.invite_hash(secret);
  if not found then raise exception 'invite_unavailable' using errcode = 'P0001'; end if;
  select lower(u.email) into actor_email from auth.users u where u.id = actor;
  if actor_email is distinct from invite.email then
    raise exception 'invite_other_email' using errcode = 'P0001';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('fundly:' || invite.space_id::text, 0));
  select * into invite from public.space_invites i where i.id = invite.id for update;
  if invite.accepted_at is not null or invite.declined_at is not null
    or invite.revoked_at is not null or invite.expires_at <= now() then
    raise exception 'invite_unavailable' using errcode = 'P0001';
  end if;
  return invite;
end;
$$;

-- Invites ------------------------------------------------------------------------------

-- Creates an invite and returns its secret, once. A pending invite to the
-- same email is replaced (its link stops working).
create function public.fundly_create_invite(space_id uuid, email text, role text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := auth.uid();
  invitee text := lower(btrim(coalesce(email, '')));
  secret text := encode(extensions.gen_random_bytes(32), 'hex');
  created public.space_invites;
begin
  perform fundly_private.manage_space(fundly_create_invite.space_id, actor);
  if role is null or role not in ('editor', 'viewer') then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  if invitee !~ '^[^@\s]+@[^@\s]+$' or char_length(invitee) > 254 then
    raise exception 'invalid_email' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.space_members m
      where m.space_id = fundly_create_invite.space_id and m.email = invitee) then
    raise exception 'already_member' using errcode = 'P0001';
  end if;
  update public.space_invites i set revoked_at = now()
    where i.space_id = fundly_create_invite.space_id and i.email = invitee
      and i.accepted_at is null and i.declined_at is null and i.revoked_at is null;
  if (select count(*) from public.space_members m where m.space_id = fundly_create_invite.space_id) >= 10 then
    raise exception 'member_limit_reached' using errcode = 'P0001';
  end if;
  if (select count(*) from public.space_invites i where i.space_id = fundly_create_invite.space_id
      and i.accepted_at is null and i.declined_at is null and i.revoked_at is null
      and i.expires_at > now()) >= 20 then
    raise exception 'invite_limit_reached' using errcode = 'P0001';
  end if;
  insert into public.space_invites(space_id, email, role, token_hash, created_by, expires_at)
    values (fundly_create_invite.space_id, invitee, role, sha256(convert_to(secret, 'UTF8')), actor,
      now() + interval '7 days')
    returning * into created;
  return jsonb_build_object('invite_id', created.id, 'secret', secret, 'email', created.email,
    'role', created.role, 'expires_at', created.expires_at);
end;
$$;

-- Pending invites of a space (owners), never their secrets.
create function public.fundly_list_invites(space_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  perform fundly_private.manage_space(fundly_list_invites.space_id, auth.uid());
  return coalesce((select jsonb_agg(jsonb_build_object('invite_id', i.id, 'email', i.email,
      'role', i.role, 'created_at', i.created_at, 'expires_at', i.expires_at) order by i.created_at)
    from public.space_invites i where i.space_id = fundly_list_invites.space_id
      and i.accepted_at is null and i.declined_at is null and i.revoked_at is null
      and i.expires_at > now()), '[]'::jsonb);
end;
$$;

create function public.fundly_revoke_invite(invite_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare target uuid;
begin
  select i.space_id into target from public.space_invites i where i.id = invite_id;
  if not found then raise exception 'invite_unavailable' using errcode = 'P0001'; end if;
  perform fundly_private.manage_space(target, auth.uid());
  update public.space_invites i set revoked_at = coalesce(i.revoked_at, now())
    where i.id = invite_id and i.accepted_at is null and i.declined_at is null;
end;
$$;

-- What an invite offers, to the email it names only.
create function public.fundly_preview_invite(secret text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare invite public.space_invites := fundly_private.claim_invite(secret, auth.uid());
begin
  return (select jsonb_build_object('space_id', s.id, 'space_name', s.name, 'role', invite.role,
      'inviter_name', m.display_name, 'inviter_email', m.email, 'expires_at', invite.expires_at,
      'already_member', fundly_private.space_role(s.id, auth.uid()) is not null)
    from public.spaces s
    left join public.space_members m on m.space_id = s.id and m.user_id = invite.created_by
    where s.id = invite.space_id);
end;
$$;

create function public.fundly_accept_invite(secret text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := auth.uid();
  invite public.space_invites := fundly_private.claim_invite(secret, actor);
  joined_role text;
begin
  joined_role := fundly_private.space_role(invite.space_id, actor);
  if joined_role is null then
    if (select count(*) from public.space_members m where m.space_id = invite.space_id) >= 10 then
      raise exception 'member_limit_reached' using errcode = 'P0001';
    end if;
    insert into public.space_members(space_id, user_id, role) values (invite.space_id, actor, invite.role);
    joined_role := invite.role;
  end if;
  update public.space_invites i set accepted_by = actor, accepted_at = now() where i.id = invite.id;
  return (select jsonb_build_object('space_id', s.id, 'space_name', s.name, 'role', joined_role)
    from public.spaces s where s.id = invite.space_id);
end;
$$;

create function public.fundly_decline_invite(secret text)
returns void language plpgsql security definer set search_path = '' as $$
declare invite public.space_invites := fundly_private.claim_invite(secret, auth.uid());
begin
  update public.space_invites i set declined_at = now() where i.id = invite.id;
end;
$$;

-- Members --------------------------------------------------------------------------

create function public.fundly_set_member_role(space_id uuid, user_id uuid, role text)
returns void language plpgsql security definer set search_path = '' as $$
declare existing_role text;
begin
  perform fundly_private.manage_space(fundly_set_member_role.space_id, auth.uid());
  if role is null or role not in ('owner', 'editor', 'viewer') then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  existing_role := fundly_private.space_role(fundly_set_member_role.space_id, fundly_set_member_role.user_id);
  if existing_role is null then raise exception 'member_not_found' using errcode = 'P0001'; end if;
  if existing_role = 'owner' and role <> 'owner' then
    perform fundly_private.require_other_owner(fundly_set_member_role.space_id, fundly_set_member_role.user_id);
  end if;
  update public.space_members m set role = fundly_set_member_role.role, updated_at = now()
    where m.space_id = fundly_set_member_role.space_id and m.user_id = fundly_set_member_role.user_id;
end;
$$;

create function public.fundly_remove_member(space_id uuid, user_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform fundly_private.manage_space(fundly_remove_member.space_id, auth.uid());
  if fundly_private.space_role(fundly_remove_member.space_id, fundly_remove_member.user_id) is null then
    raise exception 'member_not_found' using errcode = 'P0001';
  end if;
  perform fundly_private.require_other_owner(fundly_remove_member.space_id, fundly_remove_member.user_id);
  delete from public.space_members m
    where m.space_id = fundly_remove_member.space_id and m.user_id = fundly_remove_member.user_id;
end;
$$;

create function public.fundly_leave_space(space_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid := auth.uid();
begin
  perform fundly_private.manage_space(fundly_leave_space.space_id, actor, any_member => true);
  perform fundly_private.require_other_owner(fundly_leave_space.space_id, actor);
  delete from public.space_members m where m.space_id = fundly_leave_space.space_id and m.user_id = actor;
end;
$$;

-- Deletes a space for everyone (owners; Decision C3-7) once [name] matches
-- its name (ignoring case and outer spaces). Every record is tombstoned by
-- the existing triggers, so every device removes it.
create function public.fundly_delete_space(space_id uuid, name text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  target public.spaces;
  counts jsonb;
begin
  perform fundly_private.manage_space(fundly_delete_space.space_id, auth.uid());
  select * into target from public.spaces s where s.id = fundly_delete_space.space_id;
  if lower(fundly_private.trim_text(coalesce(name, ''))) is distinct from lower(target.name) then
    raise exception 'space_name_mismatch' using errcode = 'P0001';
  end if;
  counts := fundly_private.dataset_counts(target.id);
  delete from public.monthly_plans p where p.space_id = target.id;
  delete from public.transactions t where t.space_id = target.id;
  delete from public.categories c where c.space_id = target.id;
  delete from public.accounts a where a.space_id = target.id;
  delete from public.custom_account_types t where t.space_id = target.id;
  delete from public.space_members m where m.space_id = target.id;
  delete from public.spaces s where s.id = target.id;
  return jsonb_build_object('space_id', target.id, 'deleted', counts);
end;
$$;

revoke all on function public.fundly_create_invite(uuid, text, text), public.fundly_list_invites(uuid),
  public.fundly_revoke_invite(uuid), public.fundly_preview_invite(text), public.fundly_accept_invite(text),
  public.fundly_decline_invite(text), public.fundly_set_member_role(uuid, uuid, text),
  public.fundly_remove_member(uuid, uuid), public.fundly_leave_space(uuid),
  public.fundly_delete_space(uuid, text)
  from public, anon;
grant execute on function public.fundly_create_invite(uuid, text, text), public.fundly_list_invites(uuid),
  public.fundly_revoke_invite(uuid), public.fundly_preview_invite(text), public.fundly_accept_invite(text),
  public.fundly_decline_invite(text), public.fundly_set_member_role(uuid, uuid, text),
  public.fundly_remove_member(uuid, uuid), public.fundly_leave_space(uuid),
  public.fundly_delete_space(uuid, text)
  to authenticated;

revoke all on all functions in schema fundly_private from public, anon, authenticated, service_role;
