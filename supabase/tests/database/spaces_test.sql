-- Shared spaces C1.1: spaces, members, space_id and per-space rules
-- (docs/SHARED_SPACES_C1_PLAN.md). Everything is rolled back.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

create function pg_temp.act(member uuid) returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object('sub', member, 'role', 'authenticated')::text, true);
$$;
grant execute on function pg_temp.act(uuid) to authenticated;

insert into auth.users(id, email) values
  ('a1100000-0000-4000-8000-000000000001', 'c1-a@example.invalid'),
  ('b1100000-0000-4000-8000-000000000001', 'c1-b@example.invalid'),
  ('c1100000-0000-4000-8000-000000000001', 'c1-c@example.invalid');

-- Rows written the current way (owner_id only) -----------------------------

insert into public.custom_account_types(id, owner_id, name, base_type) values
  ('11100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001', 'E-wallet', 'savingsCash');
insert into public.accounts(id, owner_id, name, type, opening_balance_minor, custom_type_id) values
  ('21100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001', 'Wallet', 'savingsCash', 1000,
   '11100000-0000-4000-8000-000000000001');
insert into public.categories(id, owner_id, name, kind) values
  ('31100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001', 'Food', 'spending');
insert into public.transactions(id, owner_id, type, amount_minor, date, payee, category_id, source_account_id) values
  ('41100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001', 'spending', 100, '2026-11-24',
   'Shop', '31100000-0000-4000-8000-000000000001', '21100000-0000-4000-8000-000000000001');
insert into public.monthly_plans(id, owner_id, month, category_id, assigned_amount_minor) values
  ('51100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001', '2026-11',
   '31100000-0000-4000-8000-000000000001', 0);

select results_eq(
  $$select t, s, c, u from (
      select 'custom_account_types' t, space_id::text s, created_by::text c, updated_by::text u from public.custom_account_types
      union all select 'accounts', space_id::text, created_by::text, updated_by::text from public.accounts
      union all select 'categories', space_id::text, created_by::text, updated_by::text from public.categories
      union all select 'transactions', space_id::text, created_by::text, updated_by::text from public.transactions
      union all select 'monthly_plans', space_id::text, created_by::text, updated_by::text from public.monthly_plans
    ) r where s = 'a1100000-0000-4000-8000-000000000001' order by t$$,
  $$values ('accounts', 'a1100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001'),
    ('categories', 'a1100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001'),
    ('custom_account_types', 'a1100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001'),
    ('monthly_plans', 'a1100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001'),
    ('transactions', 'a1100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001')$$,
  'a row written with owner_id only gets that user''s space, creator and last writer');
select results_eq(
  $$select s.name, s.personal_of::text, s.created_by::text, m.user_id::text, m.role
    from public.spaces s join public.space_members m on m.space_id = s.id
    where s.id = 'a1100000-0000-4000-8000-000000000001'$$,
  $$values ('Personal', 'a1100000-0000-4000-8000-000000000001', 'a1100000-0000-4000-8000-000000000001',
    'a1100000-0000-4000-8000-000000000001', 'owner')$$,
  'the first write creates the user''s Personal space (id = user id) with them as owner');
select is((select count(*)::int from public.spaces where personal_of = 'b1100000-0000-4000-8000-000000000001'), 0,
  'a user who never wrote has no Personal space created by tests yet');

insert into public.categories(id, space_id, name, kind) values
  ('31100000-0000-4000-8000-000000000002', 'a1100000-0000-4000-8000-000000000001', 'Salary', 'inflow');
select is((select owner_id::text from public.categories where id = '31100000-0000-4000-8000-000000000002'),
  'a1100000-0000-4000-8000-000000000001', 'a row written with space_id only gets the legacy owner_id');
select throws_ok($$insert into public.categories(id, owner_id, space_id, name, kind) values
    ('31100000-0000-4000-8000-000000000003', 'a1100000-0000-4000-8000-000000000001',
     'b1100000-0000-4000-8000-000000000001', 'Mixed', 'spending')$$,
  '23514', null, 'owner_id must equal space_id while every space is Personal');

-- Identity, space and creator are immutable; revisions behave as before.
select throws_ok($$update public.categories set space_id = 'b1100000-0000-4000-8000-000000000001',
    owner_id = 'b1100000-0000-4000-8000-000000000001' where id = '31100000-0000-4000-8000-000000000001'$$,
  '23514', 'Fundly record identity and owner are immutable', 'a record cannot move to another space');
select throws_ok($$update public.categories set created_by = 'b1100000-0000-4000-8000-000000000001'
    where id = '31100000-0000-4000-8000-000000000001'$$,
  '23514', 'Fundly record identity and owner are immutable', 'a record''s creator cannot change');
update public.categories set name = 'Groceries' where id = '31100000-0000-4000-8000-000000000001';
select is((select revision from public.categories where id = '31100000-0000-4000-8000-000000000001'), 2::bigint,
  'an ordinary edit still bumps the revision');

-- Rules are per space ------------------------------------------------------

insert into public.accounts(id, owner_id, name, type, opening_balance_minor) values
  ('21100000-0000-4000-8000-000000000002', 'b1100000-0000-4000-8000-000000000001', 'Wallet', 'savingsCash', 0);
select pass('the same account name is allowed in another space');
select throws_ok($$insert into public.accounts(id, owner_id, name, type, opening_balance_minor) values
    ('21100000-0000-4000-8000-000000000003', 'a1100000-0000-4000-8000-000000000001', 'WALLET', 'savingsCash', 0)$$,
  '23505', 'duplicate key value violates unique constraint "accounts_space_name"',
  'account names are unique per space, ignoring ASCII case');
select throws_ok($$insert into public.categories(id, owner_id, name, kind) values
    ('31100000-0000-4000-8000-000000000004', 'a1100000-0000-4000-8000-000000000001', 'groceries', 'spending')$$,
  '23505', 'duplicate key value violates unique constraint "categories_space_name"',
  'category names are unique per space');
select throws_ok($$insert into public.custom_account_types(id, owner_id, name, base_type) values
    ('11100000-0000-4000-8000-000000000002', 'a1100000-0000-4000-8000-000000000001', 'e-WALLET', 'savingsCash')$$,
  '23505', 'duplicate key value violates unique constraint "custom_account_types_space_name"',
  'account type names are unique per space');
select throws_ok($$insert into public.transactions(id, owner_id, type, amount_minor, date, payee, category_id,
    source_account_id, destination_account_id) values
    ('41100000-0000-4000-8000-000000000002', 'b1100000-0000-4000-8000-000000000001', 'spending', 100, '2026-11-24',
     'Shop', null, '21100000-0000-4000-8000-000000000001', '21100000-0000-4000-8000-000000000002')$$,
  '23514', null, 'a spending with a destination is still refused');
select throws_ok($$insert into public.transactions(id, owner_id, type, amount_minor, date, payee, source_account_id, destination_account_id) values
    ('41100000-0000-4000-8000-000000000003', 'b1100000-0000-4000-8000-000000000001', 'transfer', 100, '2026-11-24',
     '', '21100000-0000-4000-8000-000000000002', '21100000-0000-4000-8000-000000000001')$$,
  '23503', null, 'a transaction cannot use an account from another space');
select throws_ok($$insert into public.monthly_plans(id, owner_id, month, category_id, assigned_amount_minor) values
    ('51100000-0000-4000-8000-000000000002', 'b1100000-0000-4000-8000-000000000001', '2026-11',
     '31100000-0000-4000-8000-000000000001', 0)$$,
  '23503', null, 'a plan cannot use a category from another space');
select throws_ok($$insert into public.monthly_plans(id, owner_id, month, category_id, assigned_amount_minor) values
    ('51100000-0000-4000-8000-000000000003', 'a1100000-0000-4000-8000-000000000001', '2026-11',
     '31100000-0000-4000-8000-000000000001', 5)$$,
  '23505', null, 'one plan per category and month in a space');

-- Owners ------------------------------------------------------------------

select throws_ok($$delete from public.space_members where space_id = 'a1100000-0000-4000-8000-000000000001';
    set constraints space_members_keep_owner immediate$$,
  '23514', 'space_needs_owner', 'a space cannot lose its last owner');
select throws_ok($$update public.space_members set role = 'editor'
    where space_id = 'a1100000-0000-4000-8000-000000000001';
    set constraints space_members_keep_owner immediate$$,
  '23514', 'space_needs_owner', 'a Personal space''s user stays its owner');
select throws_ok($$insert into public.spaces(id, name, personal_of, created_by) values
    ('d1100000-0000-4000-8000-000000000001', 'Personal', 'c1100000-0000-4000-8000-000000000001',
     'c1100000-0000-4000-8000-000000000001')$$,
  '23514', null, 'a Personal space has its user''s id');
select throws_ok($$insert into public.spaces(id, name, created_by) values
    ('d1100000-0000-4000-8000-000000000002', ' Household', 'a1100000-0000-4000-8000-000000000001')$$,
  '23514', null, 'space names are trimmed');

-- Reads are by membership ----------------------------------------------------

insert into public.space_members(space_id, user_id, role) values
  ('a1100000-0000-4000-8000-000000000001', 'c1100000-0000-4000-8000-000000000001', 'viewer');

set local role authenticated;
select pg_temp.act('a1100000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.transactions), 1, 'the owner reads their space''s records');
select is((select count(*)::int from public.accounts), 1, 'the owner does not read another space''s records');
select is((select count(*)::int from public.space_members), 2, 'the owner reads their space''s members');

select pg_temp.act('c1100000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.categories), 2, 'a member reads the space''s records');
select is((select array_agg(id::text) from public.spaces), array['a1100000-0000-4000-8000-000000000001'],
  'a member reads the spaces they belong to');

select pg_temp.act('b1100000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.categories where space_id = 'a1100000-0000-4000-8000-000000000001'), 0,
  'a non-member reads none of the space''s records');
select is((select count(*)::int from public.space_members where space_id = 'a1100000-0000-4000-8000-000000000001'), 0,
  'a non-member reads none of the space''s members');

select throws_ok($$insert into public.spaces(id, name, created_by) values
    ('d1100000-0000-4000-8000-000000000003', 'Mine', 'b1100000-0000-4000-8000-000000000001')$$,
  '42501', null, 'clients cannot create spaces directly');
select throws_ok($$insert into public.space_members(space_id, user_id, role) values
    ('a1100000-0000-4000-8000-000000000001', 'b1100000-0000-4000-8000-000000000001', 'owner')$$,
  '42501', null, 'clients cannot add themselves to a space');
select throws_ok($$select * from public.fundly_deleted_records$$, '42501', null, 'tombstones stay unreadable');
reset role;

select ok(not has_function_privilege('anon', 'fundly_access.my_space_ids()', 'execute'),
  'anonymous callers cannot use the membership helper');

-- Backend tables record the space -------------------------------------------

delete from public.monthly_plans where id = '51100000-0000-4000-8000-000000000001';
select is((select space_id::text from public.fundly_deleted_records where id = '51100000-0000-4000-8000-000000000001'),
  'a1100000-0000-4000-8000-000000000001', 'a tombstone records the deleted record''s space');

-- Deleting users behaves as before -------------------------------------------

insert into auth.users(id, email) values ('e1100000-0000-4000-8000-000000000001', 'c1-e@example.invalid');
select fundly_private.ensure_personal_space('e1100000-0000-4000-8000-000000000001');
delete from auth.users where id = 'e1100000-0000-4000-8000-000000000001';
select is((select count(*)::int from public.spaces where id = 'e1100000-0000-4000-8000-000000000001'), 0,
  'deleting a user with no records removes their Personal space and membership');
select throws_ok($$delete from auth.users where id = 'a1100000-0000-4000-8000-000000000001'$$,
  '23503', null, 'a user with records still cannot be deleted');

select * from finish();
rollback;
