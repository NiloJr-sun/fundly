-- Shared spaces C2.1: creating and renaming spaces, and Personal-only
-- owner_id (docs/SHARED_SPACES_C2_PLAN.md). Everything is rolled back.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

insert into auth.users(id, email) values
  ('a2100000-0000-4000-8000-000000000001', 'c21-a@example.invalid'),
  ('b2100000-0000-4000-8000-000000000001', 'c21-b@example.invalid'),
  ('c2100000-0000-4000-8000-000000000001', 'c21-c@example.invalid');

create function pg_temp.as_user(member uuid) returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object('sub', member, 'role', 'authenticated')::text, true);
$$;
create function pg_temp.write(actor uuid, items jsonb, target uuid default null) returns jsonb language plpgsql as $$
begin
  perform pg_temp.as_user(actor);
  return public.fundly_apply_operations(gen_random_uuid(), jsonb_build_object('version', 1, 'items', items)
    || case when target is null then '{}'::jsonb else jsonb_build_object('space_id', target) end);
end;
$$;
grant execute on all functions in schema pg_temp to authenticated;
set local role authenticated;

-- Creating -------------------------------------------------------------------

select pg_temp.as_user('a2100000-0000-4000-8000-000000000001');
select is(public.fundly_create_space('d2100000-0000-4000-8000-000000000001', '  Business  '),
  jsonb_build_object('id', 'd2100000-0000-4000-8000-000000000001', 'name', 'Business', 'personal', false, 'revision', '1'),
  'a user creates a space; the name is trimmed');
select is(public.fundly_create_space('d2100000-0000-4000-8000-000000000001', 'Business')->>'name', 'Business',
  'retrying the same id and name returns the space');
select throws_ok($$select public.fundly_create_space('d2100000-0000-4000-8000-000000000001', 'Other')$$,
  'P0001', 'space_id_unavailable', 'the same id with another name is refused');
select throws_ok($$select public.fundly_create_space('d2100000-0000-4000-8000-000000000002', 'BUSINESS')$$,
  'P0001', 'name_taken', 'names are unique among the user''s own spaces, ignoring case');
select throws_ok($$select public.fundly_create_space('d2100000-0000-4000-8000-000000000002', '   ')$$,
  'P0001', 'invalid_name', 'an empty name is refused');
select throws_ok($$select public.fundly_create_space('d2100000-0000-4000-8000-000000000002', repeat('x', 41))$$,
  'P0001', 'invalid_name', 'a name over 40 characters is refused');
select throws_ok($$select public.fundly_create_space(null, 'Nothing')$$, '22023', 'invalid_request',
  'a missing id is an invalid request');

reset role;
select results_eq($$select s.personal_of, s.created_by::text, m.user_id::text, m.role
    from public.spaces s join public.space_members m on m.space_id = s.id
    where s.id = 'd2100000-0000-4000-8000-000000000001'$$,
  $$values (null::uuid, 'a2100000-0000-4000-8000-000000000001', 'a2100000-0000-4000-8000-000000000001', 'owner')$$,
  'the new space is not Personal, and its creator is its owner');
select is((select count(*)::int from public.spaces where personal_of = 'a2100000-0000-4000-8000-000000000001'), 1,
  'creating a space also made sure the creator has a Personal space');
set local role authenticated;

select pg_temp.as_user('b2100000-0000-4000-8000-000000000001');
select lives_ok($$select public.fundly_create_space('d2100000-0000-4000-8000-000000000003', 'Business')$$,
  'another user may use the same name');
select throws_ok($$select public.fundly_create_space('d2100000-0000-4000-8000-000000000001', 'Business')$$,
  'P0001', 'space_id_unavailable', 'another user cannot claim an existing id, even with the same name');

-- The limit: 10 owned spaces, Personal included.
select pg_temp.as_user('c2100000-0000-4000-8000-000000000001');
select lives_ok(format($$select public.fundly_create_space(%L, %L)$$,
    'e2100000-0000-4000-8000-00000000000' || n, 'Space ' || n), 'create space ' || n)
  from generate_series(1, 9) n;
select throws_ok($$select public.fundly_create_space('e2100000-0000-4000-8000-000000000010', 'Space 10')$$,
  'P0001', 'space_limit_reached', 'the 11th owned space is refused (Personal counts)');

-- Renaming -------------------------------------------------------------------

select pg_temp.as_user('a2100000-0000-4000-8000-000000000001');
select is(public.fundly_rename_space('d2100000-0000-4000-8000-000000000001', 'Shop', '1')->>'revision', '2',
  'the owner renames a space; its revision advances');
select throws_ok($$select public.fundly_rename_space('d2100000-0000-4000-8000-000000000001', 'Store', '1')$$,
  'P0001', 'revision_conflict', 'a rename from a stale revision is refused');
select lives_ok($$select public.fundly_rename_space('a2100000-0000-4000-8000-000000000001', 'Me', '1')$$,
  'Personal can be renamed');
select throws_ok($$select public.fundly_rename_space('d2100000-0000-4000-8000-000000000001', 'me', '2')$$,
  'P0001', 'name_taken', 'a rename cannot take another of the user''s space names');
select lives_ok($$select public.fundly_rename_space('d2100000-0000-4000-8000-000000000001', 'SHOP', '2')$$,
  'a space may change only the case of its own name');

reset role;
insert into public.space_members(space_id, user_id, role) values
  ('d2100000-0000-4000-8000-000000000001', 'b2100000-0000-4000-8000-000000000001', 'editor');
set local role authenticated;
select pg_temp.as_user('b2100000-0000-4000-8000-000000000001');
select throws_ok($$select public.fundly_rename_space('d2100000-0000-4000-8000-000000000001', 'Mine', '3')$$,
  'P0001', 'space_owner_only', 'an editor cannot rename');
select pg_temp.as_user('c2100000-0000-4000-8000-000000000001');
select throws_ok($$select public.fundly_rename_space('d2100000-0000-4000-8000-000000000001', 'Mine', '3')$$,
  'P0001', 'not_space_member', 'an outsider cannot rename');
reset role;
select ok(not has_function_privilege('anon', 'public.fundly_create_space(uuid, text)', 'execute')
  and not has_function_privilege('anon', 'public.fundly_rename_space(uuid, text, text)', 'execute'),
  'anonymous callers cannot create or rename spaces');
set local role authenticated;

-- Records in a non-Personal space -------------------------------------------------

select lives_ok($$select pg_temp.write('a2100000-0000-4000-8000-000000000001', jsonb_build_array(
    '{"operation":"dataset.initialize","id":"f2100000-0000-4000-8000-000000000001"}'::jsonb,
    '{"operation":"account.create","id":"f2100000-0000-4000-8000-000000000002","data":{"name":"Till","type":"savingsCash","entered_opening_amount_minor":"100"}}'::jsonb),
    'd2100000-0000-4000-8000-000000000001')$$, 'records are written to the new space through the write API');
select lives_ok($$select pg_temp.write('a2100000-0000-4000-8000-000000000001', jsonb_build_array(
    '{"operation":"account.create","id":"f2100000-0000-4000-8000-000000000003","data":{"name":"Wallet","type":"savingsCash","entered_opening_amount_minor":"100"}}'::jsonb))$$,
  'and to Personal without naming it');
reset role;
select results_eq($$select space_id::text, owner_id::text, created_by::text from public.accounts
    where id in ('f2100000-0000-4000-8000-000000000002', 'f2100000-0000-4000-8000-000000000003') order by name$$,
  $$values ('d2100000-0000-4000-8000-000000000001', null, 'a2100000-0000-4000-8000-000000000001'),
    ('a2100000-0000-4000-8000-000000000001', 'a2100000-0000-4000-8000-000000000001', 'a2100000-0000-4000-8000-000000000001')$$,
  'a non-Personal record has no owner_id; a Personal one keeps it');
select is((select count(*)::int from public.categories where space_id = 'd2100000-0000-4000-8000-000000000001'), 9,
  'the new space got its own default categories');
select is((select count(*)::int from public.accounts where owner_id = 'a2100000-0000-4000-8000-000000000001'), 1,
  'the legacy filter (owner_id = user) finds only Personal records, as apps 1.2.x download');
select throws_ok($$insert into public.categories(id, space_id, owner_id, name, kind) values
    ('f2100000-0000-4000-8000-000000000009', 'd2100000-0000-4000-8000-000000000001',
     'a2100000-0000-4000-8000-000000000001', 'Forced', 'spending')$$,
  '23514', null, 'owner_id cannot be set on a non-Personal space''s record');
delete from public.accounts where id = 'f2100000-0000-4000-8000-000000000002';
select results_eq($$select space_id::text, owner_id from public.fundly_deleted_records
    where id = 'f2100000-0000-4000-8000-000000000002'$$,
  $$values ('d2100000-0000-4000-8000-000000000001', null::uuid)$$,
  'deleting a non-Personal record leaves a tombstone with its space and no owner');

-- The space tables can be read by members only, as before.
set local role authenticated;
select pg_temp.as_user('c2100000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.spaces where id = 'd2100000-0000-4000-8000-000000000001'), 0,
  'an outsider does not see the space');
select pg_temp.as_user('b2100000-0000-4000-8000-000000000001');
select is((select name from public.spaces where id = 'd2100000-0000-4000-8000-000000000001'), 'SHOP',
  'a member sees the space and its current name');

select * from finish();
rollback;
