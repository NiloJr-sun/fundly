-- Shared spaces C3.1: invites, members, leaving and deleting
-- (docs/SHARED_SPACES_C3_PLAN.md). Everything is rolled back.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

insert into auth.users(id, email, raw_user_meta_data) values
  ('a3100000-0000-4000-8000-000000000001', 'Owner@Example.invalid', '{"full_name":"Olive Owner"}'),
  ('b3100000-0000-4000-8000-000000000001', 'editor@example.invalid', '{"full_name":"Eddie Editor"}'),
  ('c3100000-0000-4000-8000-000000000001', 'viewer@example.invalid', '{"name":"Vee"}'),
  ('d3100000-0000-4000-8000-000000000001', 'outsider@example.invalid', '{}'),
  ('e3100000-0000-4000-8000-000000000001', 'second@example.invalid', '{"full_name":"Second Owner"}');

create function pg_temp.as_user(member uuid) returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object('sub', member, 'role', 'authenticated')::text, true);
$$;
-- Remembers secrets between statements (each test runs on its own).
create temporary table secrets(label text primary key, secret text);
grant all on secrets to authenticated;
create function pg_temp.invite(owner uuid, space uuid, email text, role text, tag text) returns text
language plpgsql as $$
declare created text;
begin
  perform pg_temp.as_user(owner);
  created := public.fundly_create_invite(space, email, role)->>'secret';
  insert into secrets(label, secret) values (tag, created)
    on conflict (label) do update set secret = excluded.secret;
  return created;
end;
$$;
create function pg_temp.secret(tag text) returns text language sql as $$
  select s.secret from secrets s where s.label = tag
$$;
grant execute on all functions in schema pg_temp to authenticated;
set local role authenticated;

select pg_temp.as_user('a3100000-0000-4000-8000-000000000001');
select lives_ok($$select public.fundly_create_space('f3100000-0000-4000-8000-000000000001', 'Household')$$,
  'the owner creates a space to share');

-- Creating invites -------------------------------------------------------------------

select matches(pg_temp.invite('a3100000-0000-4000-8000-000000000001', 'f3100000-0000-4000-8000-000000000001',
    '  EDITOR@example.invalid ', 'editor', 'editor'), '^[0-9a-f]{64}$',
  'an invite returns a 64-character secret once');
select pg_temp.as_user('a3100000-0000-4000-8000-000000000001');
select is((public.fundly_list_invites('f3100000-0000-4000-8000-000000000001')->0->>'email'),
  'editor@example.invalid', 'the email is stored trimmed and lower-cased; the owner lists pending invites');
select ok(not (public.fundly_list_invites('f3100000-0000-4000-8000-000000000001')::text
    ~ pg_temp.secret('editor')), 'the list never shows a secret');
select throws_ok($$select public.fundly_create_invite('a3100000-0000-4000-8000-000000000001',
    'x@example.invalid', 'editor')$$, 'P0001', 'personal_space', 'Personal cannot be shared');
select throws_ok($$select public.fundly_create_invite('f3100000-0000-4000-8000-000000000001',
    'not an email', 'editor')$$, 'P0001', 'invalid_email', 'an invalid email is refused');
select throws_ok($$select public.fundly_create_invite('f3100000-0000-4000-8000-000000000001',
    'x@example.invalid', 'owner')$$, '22023', 'invalid_request', 'invites are for editors and viewers only');
select throws_ok($$select public.fundly_create_invite('f3100000-0000-4000-8000-000000000001',
    'owner@example.invalid', 'editor')$$, 'P0001', 'already_member', 'a member cannot be invited again');
select pg_temp.as_user('d3100000-0000-4000-8000-000000000001');
select throws_ok($$select public.fundly_create_invite('f3100000-0000-4000-8000-000000000001',
    'x@example.invalid', 'editor')$$, 'P0001', 'not_space_member', 'an outsider cannot invite');
select throws_ok($$select public.fundly_list_invites('f3100000-0000-4000-8000-000000000001')$$,
  'P0001', 'not_space_member', 'an outsider cannot list invites');

-- Previewing, accepting, declining ---------------------------------------------------

select pg_temp.as_user('d3100000-0000-4000-8000-000000000001');
select throws_ok(format($$select public.fundly_preview_invite(%L)$$, pg_temp.secret('editor')),
  'P0001', 'invite_other_email', 'another email learns only that the invite is not theirs');
select throws_ok(format($$select public.fundly_accept_invite(%L)$$, pg_temp.secret('editor')),
  'P0001', 'invite_other_email', 'and cannot accept it');
select throws_ok($$select public.fundly_preview_invite('not-a-secret')$$, 'P0001', 'invite_unavailable',
  'a malformed secret is unavailable');
select throws_ok(format($$select public.fundly_preview_invite(%L)$$, repeat('a', 64)), 'P0001',
  'invite_unavailable', 'an unknown secret is unavailable');

select pg_temp.as_user('b3100000-0000-4000-8000-000000000001');
select results_eq(format($$select p->>'space_name', p->>'role', p->>'inviter_name', p->>'inviter_email',
    p->>'already_member' from public.fundly_preview_invite(%L) p$$, pg_temp.secret('editor')),
  $$values ('Household', 'editor', 'Olive Owner', 'owner@example.invalid', 'false')$$,
  'the invited email sees the space, role and inviter');
select is(public.fundly_accept_invite(pg_temp.secret('editor'))->>'role', 'editor', 'the invited email accepts');
select throws_ok(format($$select public.fundly_accept_invite(%L)$$, pg_temp.secret('editor')),
  'P0001', 'invite_unavailable', 'an invite works once');
select results_eq($$select user_id::text, role, email, display_name from public.space_members
    where space_id = 'f3100000-0000-4000-8000-000000000001' order by role desc$$,
  $$values ('a3100000-0000-4000-8000-000000000001', 'owner', 'owner@example.invalid', 'Olive Owner'),
    ('b3100000-0000-4000-8000-000000000001', 'editor', 'editor@example.invalid', 'Eddie Editor')$$,
  'members see each other''s name and email');
select throws_ok($$select public.fundly_create_invite('f3100000-0000-4000-8000-000000000001',
    'x@example.invalid', 'viewer')$$, 'P0001', 'space_owner_only', 'an editor cannot invite');

select pg_temp.invite('a3100000-0000-4000-8000-000000000001', 'f3100000-0000-4000-8000-000000000001',
  'viewer@example.invalid', 'viewer', 'viewer');
select pg_temp.as_user('c3100000-0000-4000-8000-000000000001');
select lives_ok(format($$select public.fundly_decline_invite(%L)$$, pg_temp.secret('viewer')),
  'the invited email can decline');
select throws_ok(format($$select public.fundly_accept_invite(%L)$$, pg_temp.secret('viewer')),
  'P0001', 'invite_unavailable', 'a declined invite cannot be accepted');

-- A new invite to the same email replaces the old one.
select pg_temp.invite('a3100000-0000-4000-8000-000000000001', 'f3100000-0000-4000-8000-000000000001',
  'viewer@example.invalid', 'viewer', 'viewer-old');
select pg_temp.invite('a3100000-0000-4000-8000-000000000001', 'f3100000-0000-4000-8000-000000000001',
  'viewer@example.invalid', 'viewer', 'viewer-new');
select is(jsonb_array_length(public.fundly_list_invites('f3100000-0000-4000-8000-000000000001')), 1,
  'only the newest invite to an email is pending');
select pg_temp.as_user('c3100000-0000-4000-8000-000000000001');
select throws_ok(format($$select public.fundly_accept_invite(%L)$$, pg_temp.secret('viewer-old')),
  'P0001', 'invite_unavailable', 'a replaced link stops working');
select is(public.fundly_accept_invite(pg_temp.secret('viewer-new'))->>'role', 'viewer', 'the new link works');

-- Revoked and expired invites.
select pg_temp.invite('a3100000-0000-4000-8000-000000000001', 'f3100000-0000-4000-8000-000000000001',
  'second@example.invalid', 'editor', 'revoked');
select pg_temp.as_user('b3100000-0000-4000-8000-000000000001');
select throws_ok($$select public.fundly_revoke_invite((select (i->>'invite_id')::uuid from
    jsonb_array_elements('[]'::jsonb) i))$$, 'P0001', 'invite_unavailable', 'revoking nothing is refused');
select pg_temp.as_user('a3100000-0000-4000-8000-000000000001');
select lives_ok($$select public.fundly_revoke_invite((public.fundly_list_invites(
    'f3100000-0000-4000-8000-000000000001')->0->>'invite_id')::uuid)$$, 'the owner revokes an invite');
select pg_temp.as_user('e3100000-0000-4000-8000-000000000001');
select throws_ok(format($$select public.fundly_accept_invite(%L)$$, pg_temp.secret('revoked')),
  'P0001', 'invite_unavailable', 'a revoked invite cannot be accepted');
select pg_temp.invite('a3100000-0000-4000-8000-000000000001', 'f3100000-0000-4000-8000-000000000001',
  'second@example.invalid', 'editor', 'expired');
reset role;
update public.space_invites set expires_at = now() - interval '1 second' where email = 'second@example.invalid'
  and revoked_at is null;
set local role authenticated;
select pg_temp.as_user('e3100000-0000-4000-8000-000000000001');
select throws_ok(format($$select public.fundly_preview_invite(%L)$$, pg_temp.secret('expired')),
  'P0001', 'invite_unavailable', 'an expired invite is unavailable');

-- Roles -------------------------------------------------------------------------------

select pg_temp.as_user('b3100000-0000-4000-8000-000000000001');
select throws_ok($$select public.fundly_set_member_role('f3100000-0000-4000-8000-000000000001',
    'c3100000-0000-4000-8000-000000000001', 'editor')$$, 'P0001', 'space_owner_only', 'an editor cannot change roles');
select pg_temp.as_user('a3100000-0000-4000-8000-000000000001');
select throws_ok($$select public.fundly_set_member_role('f3100000-0000-4000-8000-000000000001',
    'a3100000-0000-4000-8000-000000000001', 'editor')$$, 'P0001', 'last_owner',
  'the only owner cannot step down');
select throws_ok($$select public.fundly_set_member_role('f3100000-0000-4000-8000-000000000001',
    'd3100000-0000-4000-8000-000000000001', 'editor')$$, 'P0001', 'member_not_found',
  'a non-member''s role cannot be set');
select lives_ok($$select public.fundly_set_member_role('f3100000-0000-4000-8000-000000000001',
    'b3100000-0000-4000-8000-000000000001', 'owner')$$, 'an owner makes another member owner');
select lives_ok($$select public.fundly_set_member_role('f3100000-0000-4000-8000-000000000001',
    'a3100000-0000-4000-8000-000000000001', 'editor')$$, 'with another owner, an owner can step down');
select pg_temp.as_user('b3100000-0000-4000-8000-000000000001');
select lives_ok($$select public.fundly_set_member_role('f3100000-0000-4000-8000-000000000001',
    'a3100000-0000-4000-8000-000000000001', 'owner')$$, 'and be made owner again');

-- The viewer's writes stay refused (C1); members and outsiders read as before.
select pg_temp.as_user('c3100000-0000-4000-8000-000000000001');
select throws_ok($$select public.fundly_apply_operations(gen_random_uuid(), jsonb_build_object('version', 1,
    'space_id', 'f3100000-0000-4000-8000-000000000001', 'items', jsonb_build_array(jsonb_build_object(
      'operation', 'dataset.initialize', 'id', gen_random_uuid()))))$$, 'P0001', 'space_read_only',
  'a viewer who joined by invite cannot write');
select is((select count(*)::int from public.space_members where space_id = 'f3100000-0000-4000-8000-000000000001'),
  3, 'a member sees all three members');
select pg_temp.as_user('d3100000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.space_members where space_id = 'f3100000-0000-4000-8000-000000000001'),
  0, 'an outsider sees none of them');

-- Removing and leaving -------------------------------------------------------------------

select pg_temp.as_user('c3100000-0000-4000-8000-000000000001');
select throws_ok($$select public.fundly_remove_member('f3100000-0000-4000-8000-000000000001',
    'b3100000-0000-4000-8000-000000000001')$$, 'P0001', 'space_owner_only', 'a viewer cannot remove anyone');
select lives_ok($$select public.fundly_leave_space('f3100000-0000-4000-8000-000000000001')$$, 'a viewer leaves');
select is((select count(*)::int from public.spaces where id = 'f3100000-0000-4000-8000-000000000001'), 0,
  'after leaving, the space is no longer visible');
select pg_temp.as_user('a3100000-0000-4000-8000-000000000001');
select throws_ok($$select public.fundly_leave_space('a3100000-0000-4000-8000-000000000001')$$, 'P0001',
  'personal_space', 'nobody leaves their Personal space');
select lives_ok($$select public.fundly_remove_member('f3100000-0000-4000-8000-000000000001',
    'b3100000-0000-4000-8000-000000000001')$$, 'an owner removes another owner while one remains');
select throws_ok($$select public.fundly_leave_space('f3100000-0000-4000-8000-000000000001')$$, 'P0001',
  'last_owner', 'the last owner cannot leave');
select throws_ok($$select public.fundly_remove_member('f3100000-0000-4000-8000-000000000001',
    'a3100000-0000-4000-8000-000000000001')$$, 'P0001', 'last_owner', 'nor be removed');
select pg_temp.as_user('b3100000-0000-4000-8000-000000000001');
select throws_ok($$select public.fundly_apply_operations(gen_random_uuid(), jsonb_build_object('version', 1,
    'space_id', 'f3100000-0000-4000-8000-000000000001', 'items', jsonb_build_array(jsonb_build_object(
      'operation', 'dataset.initialize', 'id', gen_random_uuid()))))$$, 'P0001', 'not_space_member',
  'a removed member''s writes are refused');

-- Limits ----------------------------------------------------------------------------------

reset role;
insert into auth.users(id, email)
  select ('a31000ff-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid, 'm' || n || '@example.invalid'
  from generate_series(1, 9) n;
insert into public.space_members(space_id, user_id, role)
  select 'f3100000-0000-4000-8000-000000000001', ('a31000ff-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid, 'viewer'
  from generate_series(1, 9) n;
set local role authenticated;
select pg_temp.as_user('a3100000-0000-4000-8000-000000000001');
select throws_ok($$select public.fundly_create_invite('f3100000-0000-4000-8000-000000000001',
    'eleventh@example.invalid', 'viewer')$$, 'P0001', 'member_limit_reached', 'a space holds at most 10 members');
reset role;
delete from public.space_members where user_id::text like 'a31000ff-%';
set local role authenticated;
select pg_temp.as_user('a3100000-0000-4000-8000-000000000001');
select lives_ok(format($$select public.fundly_create_invite('f3100000-0000-4000-8000-000000000001', %L, 'viewer')$$,
    'invitee' || n || '@example.invalid'), 'invite ' || n) from generate_series(1, 20) n;
select throws_ok($$select public.fundly_create_invite('f3100000-0000-4000-8000-000000000001',
    'one-more@example.invalid', 'viewer')$$, 'P0001', 'invite_limit_reached', 'at most 20 pending invites');

-- Deleting a space ----------------------------------------------------------------------

reset role;
update public.space_invites set revoked_at = now() where revoked_at is null and accepted_at is null;
set local role authenticated;

select pg_temp.invite('a3100000-0000-4000-8000-000000000001', 'f3100000-0000-4000-8000-000000000001',
  'editor@example.invalid', 'editor', 'rejoin');
select pg_temp.as_user('b3100000-0000-4000-8000-000000000001');
select lives_ok(format($$select public.fundly_accept_invite(%L)$$, pg_temp.secret('rejoin')),
  'a removed member can be invited again');
select lives_ok($$select public.fundly_apply_operations(gen_random_uuid(), '{"version": 1,
    "space_id": "f3100000-0000-4000-8000-000000000001", "items": [
      {"operation": "dataset.initialize", "id": "f3100000-0000-4000-8000-0000000000a0"},
      {"operation": "account.create", "id": "f3100000-0000-4000-8000-0000000000a1",
       "data": {"name": "Joint", "type": "savingsCash", "entered_opening_amount_minor": "0"}}]}'::jsonb)$$,
  'the editor fills the space');
select throws_ok($$select public.fundly_delete_space('f3100000-0000-4000-8000-000000000001', 'Household')$$,
  'P0001', 'space_owner_only', 'an editor cannot delete the space');
select pg_temp.as_user('a3100000-0000-4000-8000-000000000001');
select throws_ok($$select public.fundly_delete_space('f3100000-0000-4000-8000-000000000001', 'Home')$$,
  'P0001', 'space_name_mismatch', 'the typed name must match');
select throws_ok($$select public.fundly_delete_space('a3100000-0000-4000-8000-000000000001', 'Personal')$$,
  'P0001', 'personal_space', 'Personal cannot be deleted');
select is(public.fundly_delete_space('f3100000-0000-4000-8000-000000000001', '  household ')->'deleted'->>'accounts',
  '1', 'the owner deletes it (case and outer spaces ignored), with its counts');
reset role;
select is((select count(*)::int from public.spaces where id = 'f3100000-0000-4000-8000-000000000001')
  + (select count(*)::int from public.space_members where space_id = 'f3100000-0000-4000-8000-000000000001')
  + (select count(*)::int from public.space_invites where space_id = 'f3100000-0000-4000-8000-000000000001')
  + (select count(*)::int from public.categories where space_id = 'f3100000-0000-4000-8000-000000000001'),
  0, 'the space, its members, invites and records are gone');
select ok((select count(*) from public.fundly_deleted_records
    where space_id = 'f3100000-0000-4000-8000-000000000001' and entity = 'accounts') = 1
  and (select count(*) from public.fundly_deleted_records
    where space_id = 'f3100000-0000-4000-8000-000000000001' and entity = 'categories') = 9,
  'every deleted record is tombstoned, so every device removes it');
select ok(not has_function_privilege('anon', 'public.fundly_accept_invite(text)', 'execute')
  and not has_function_privilege('anon', 'public.fundly_delete_space(uuid, text)', 'execute'),
  'anonymous callers cannot use the sharing functions');
select throws_ok($$set local role authenticated; select * from public.space_invites$$, '42501', null,
  'invites are never readable directly');

select * from finish();
rollback;
