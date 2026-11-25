-- Entire fixture and every mutation are rolled back. No hosted test users.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

insert into auth.users(id, email) values
  ('a0000000-0000-4000-8000-000000000001', 'schema-a@example.invalid'),
  ('b0000000-0000-4000-8000-000000000001', 'schema-b@example.invalid');

insert into public.custom_account_types(id, owner_id, name, base_type) values
  ('10000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'E-wallet', 'savingsCash'),
  ('10000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001', 'E-wallet', 'savingsCash');
insert into public.accounts(id, owner_id, name, type, opening_balance_minor, is_budget_account, custom_type_id) values
  ('20000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'Wallet', 'savingsCash', 10000, true, '10000000-0000-4000-8000-000000000001'),
  ('20000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'Card', 'credit', -2000, false, null),
  ('20000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000001', 'Loan', 'loan', -3000, false, null),
  ('20000000-0000-4000-8000-000000000004', 'b0000000-0000-4000-8000-000000000001', 'Wallet', 'savingsCash', 10000, true, '10000000-0000-4000-8000-000000000002');
insert into public.categories(id, owner_id, name, kind, plan_group, linked_account_id) values
  ('30000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'Food', 'spending', 'spending', null),
  ('30000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'Salary', 'inflow', 'spending', null),
  ('30000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000001', 'Card plan', 'spending', 'liability', '20000000-0000-4000-8000-000000000002'),
  ('30000000-0000-4000-8000-000000000004', 'b0000000-0000-4000-8000-000000000001', 'Food', 'spending', 'spending', null);
insert into public.transactions(id, owner_id, type, amount_minor, date, payee, category_id, source_account_id, destination_account_id) values
  ('40000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'spending', 100, '2026-11-18', 'Groceries', '30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', null),
  ('40000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'inflow', 500, '2026-11-18', 'Salary', null, null, '20000000-0000-4000-8000-000000000001'),
  ('40000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000001', 'transfer', 100, '2026-11-18', '', null, '20000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000003'),
  ('40000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000001', 'creditCardPayment', 100, '2026-11-18', '', null, '20000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002'),
  ('40000000-0000-4000-8000-000000000005', 'b0000000-0000-4000-8000-000000000001', 'spending', 100, '2026-11-18', 'Groceries', '30000000-0000-4000-8000-000000000004', '20000000-0000-4000-8000-000000000004', null);
insert into public.monthly_plans(id, owner_id, month, category_id, target_amount_minor, assigned_amount_minor) values
  ('50000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', '2026-11', '30000000-0000-4000-8000-000000000001', null, 0),
  ('50000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001', '2026-11', '30000000-0000-4000-8000-000000000004', 0, 0);

select is((select count(*) from public.transactions), 5::bigint, 'all four transaction shapes and second-owner data are accepted');
select col_type_is('public', 'accounts', 'opening_balance_minor', 'bigint', 'opening balance uses integer minor units');
select col_type_is('public', 'transactions', 'amount_minor', 'bigint', 'transaction money uses integer minor units');
select col_type_is('public', 'monthly_plans', 'target_amount_minor', 'bigint', 'Target uses integer minor units');
select col_type_is('public', 'monthly_plans', 'assigned_amount_minor', 'bigint', 'Assigned uses integer minor units');
select col_type_is('public', 'transactions', 'date', 'date', 'transaction date has no timestamp or timezone');
select col_type_is('public', t, 'id', 'uuid', t || ': shared identity is UUID')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select col_type_is('public', t, 'owner_id', 'uuid', t || ': owner is UUID')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select col_type_is('public', t, 'created_at', 'timestamp with time zone', t || ': audit time is an instant')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select hasnt_column('public', 'accounts', 'balance', 'no independently stored account balance');
select ok((select target_amount_minor is null and assigned_amount_minor = 0 from public.monthly_plans where id = '50000000-0000-4000-8000-000000000001'), 'null target and zero assigned survive');
select is((select target_amount_minor from public.monthly_plans where id = '50000000-0000-4000-8000-000000000002'), 0::bigint, 'zero target is distinct from null');

-- Mutation-based constraint tests check the actual SQLSTATE. Each throws_ok
-- catches/rolls back its own mutation, preserving the shared valid fixtures.
select throws_ok(statement, state, null, description)
from (values
  ($$update public.accounts set name = '' where name = 'Card'$$, '23514', 'empty account name'),
  ($$update public.accounts set name = repeat('x',41) where name = 'Card'$$, '23514', 'long account name'),
  ($$update public.accounts set name = 'wALLET' where name = 'Card'$$, '23505', 'ASCII case-insensitive account names per owner'),
  ($$update public.accounts set type = 'unknown' where name = 'Card'$$, '23514', 'unknown account type'),
  ($$update public.accounts set opening_balance_minor = -1 where name = 'Wallet'$$, '23514', 'negative asset opening balance'),
  ($$update public.accounts set opening_balance_minor = 1 where name = 'Card'$$, '23514', 'positive credit opening balance'),
  ($$update public.accounts set opening_balance_minor = 1 where name = 'Loan'$$, '23514', 'positive loan opening balance'),
  ($$update public.accounts set currency_code = 'USD' where name = 'Card'$$, '23514', 'non-PHP account'),
  ($$update public.accounts set is_budget_account = true where name = 'Card'$$, '23514', 'liability cannot be budget account'),
  ($$update public.accounts set is_archived = true where is_budget_account$$, '23514', 'archived account cannot remain budget account'),
  ($$update public.accounts set custom_type_id = '10000000-0000-4000-8000-000000000002' where id = '20000000-0000-4000-8000-000000000001'$$, '23503', 'account cannot reference another owner custom type'),
  ($$delete from public.custom_account_types where id = '10000000-0000-4000-8000-000000000001'$$, '23503', 'used custom type cannot be deleted'),
  ($$update public.custom_account_types set name = ''$$, '23514', 'empty custom type name'),
  ($$update public.custom_account_types set name = repeat('x',41)$$, '23514', 'long custom type name'),
  ($$update public.custom_account_types set base_type = 'unknown'$$, '23514', 'invalid custom base type'),
  ($$insert into public.custom_account_types(id,owner_id,name,base_type) values(gen_random_uuid(),'a0000000-0000-4000-8000-000000000001','e-WALLET','loan')$$, '23505', 'custom type names ignore ASCII case'),
  ($$insert into public.custom_account_types(id,owner_id,name,base_type) values(gen_random_uuid(),'f0000000-0000-4000-8000-000000000001','Missing owner','loan')$$, '23503', 'owner must exist'),
  ($$update public.categories set name = '' where name = 'Salary'$$, '23514', 'empty category name'),
  ($$update public.categories set name = repeat('x',41) where name = 'Salary'$$, '23514', 'long category name'),
  ($$update public.categories set name = 'fOOD' where name = 'Salary'$$, '23505', 'category names ignore ASCII case'),
  ($$update public.categories set kind = 'unknown' where name = 'Salary'$$, '23514', 'invalid category kind'),
  ($$update public.categories set plan_group = 'unknown' where name = 'Salary'$$, '23514', 'invalid Plans group'),
  ($$update public.categories set is_plan_deleted = true where name = 'Food'$$, '23514', 'deleted plan must be archived'),
  ($$update public.categories set is_plan_archived = true, is_plan_deleted = true where name = 'Salary'$$, '23514', 'deleted plan must be spending kind'),
  ($$update public.categories set plan_group = 'spending' where name = 'Card plan'$$, '23514', 'linked row must be in liability group'),
  ($$update public.categories set kind = 'inflow' where name = 'Card plan'$$, '23514', 'linked row must be spending kind'),
  ($$update public.categories set linked_account_id = '20000000-0000-4000-8000-000000000004' where name = 'Card plan'$$, '23503', 'linked account must have same owner'),
  ($$insert into public.categories(id,owner_id,name,kind,plan_group,linked_account_id) values(gen_random_uuid(),'a0000000-0000-4000-8000-000000000001','Duplicate linked row','spending','liability','20000000-0000-4000-8000-000000000002')$$, '23505', 'one linked category per account'),
  ($$delete from public.categories where id = '30000000-0000-4000-8000-000000000001'$$, '23503', 'transaction history restricts category deletion'),
  ($$delete from public.accounts where id = '20000000-0000-4000-8000-000000000001'$$, '23503', 'transaction history restricts account deletion'),
  ($$update public.transactions set type = 'unknown' where type = 'spending'$$, '23514', 'invalid transaction type'),
  ($$update public.transactions set amount_minor = 0$$, '23514', 'zero transaction amount'),
  ($$update public.transactions set amount_minor = -1$$, '23514', 'negative transaction amount'),
  ($$update public.transactions set amount_minor = 9223372036854775808$$, '22003', 'money overflow is rejected'),
  ($$update public.transactions set currency_code = 'USD'$$, '23514', 'non-PHP transaction'),
  ($$update public.transactions set destination_account_id = source_account_id where type = 'transfer'$$, '23514', 'self transfer is rejected'),
  ($$update public.transactions set payee = repeat('x',61)$$, '23514', 'payee length limit'),
  ($$update public.transactions set note = repeat('x',501)$$, '23514', 'note length limit'),
  ($$update public.transactions set date = '2026-02-30'$$, '22008', 'invalid calendar day'),
  ($$update public.transactions set date = 'infinity'$$, '23514', 'infinite date rejected'),
  ($$update public.transactions set date = '10000-01-01'$$, '23514', 'date above supported four-digit year range'),
  ($$update public.transactions set date = '0002-01-01 BC'$$, '23514', 'date below ISO year zero'),
  ($$update public.transactions set source_account_id = null where type = 'spending'$$, '23514', 'spending requires source'),
  ($$update public.transactions set destination_account_id = '20000000-0000-4000-8000-000000000002' where type = 'spending'$$, '23514', 'spending forbids destination'),
  ($$update public.transactions set destination_account_id = null where type = 'inflow'$$, '23514', 'inflow requires destination'),
  ($$update public.transactions set source_account_id = '20000000-0000-4000-8000-000000000003' where type = 'inflow'$$, '23514', 'inflow forbids source'),
  ($$update public.transactions set destination_account_id = null where type = 'transfer'$$, '23514', 'transfer requires destination'),
  ($$update public.transactions set source_account_id = null where type = 'creditCardPayment'$$, '23514', 'card payment requires source'),
  ($$update public.transactions set category_id = '30000000-0000-4000-8000-000000000001' where type in ('transfer','creditCardPayment')$$, '23514', 'movements forbid categories'),
  ($$update public.transactions set category_id = '30000000-0000-4000-8000-000000000004' where id = '40000000-0000-4000-8000-000000000001'$$, '23503', 'transaction category must share owner'),
  ($$update public.transactions set source_account_id = '20000000-0000-4000-8000-000000000004' where id = '40000000-0000-4000-8000-000000000001'$$, '23503', 'transaction source must share owner'),
  ($$update public.transactions set destination_account_id = '20000000-0000-4000-8000-000000000004' where type = 'transfer'$$, '23503', 'transaction destination must share owner'),
  ($$update public.monthly_plans set month = '2026-13'$$, '23514', 'month above 12'),
  ($$update public.monthly_plans set month = '2026-00'$$, '23514', 'month below 01'),
  ($$update public.monthly_plans set month = '2026-1'$$, '23514', 'month must be padded'),
  ($$update public.monthly_plans set month = '10000-01'$$, '23514', 'month must use four-digit year'),
  ($$update public.monthly_plans set target_amount_minor = -1$$, '23514', 'negative Target'),
  ($$update public.monthly_plans set assigned_amount_minor = -1$$, '23514', 'negative Assigned'),
  ($$update public.monthly_plans set currency_code = 'USD'$$, '23514', 'non-PHP monthly plan'),
  ($$update public.monthly_plans set category_id = '30000000-0000-4000-8000-000000000004' where id = '50000000-0000-4000-8000-000000000001'$$, '23503', 'plan category must share owner'),
  ($$insert into public.monthly_plans(id,owner_id,month,category_id,assigned_amount_minor) values(gen_random_uuid(),'a0000000-0000-4000-8000-000000000001','2026-11','30000000-0000-4000-8000-000000000001',0)$$, '23505', 'one monthly plan per owner/category/month')
) as cases(statement, state, description);
-- R.20: Spending and Inflow may have no payee. Undone inside the block, so the
-- later checks see the original rows.
select lives_ok($test$do $block$ begin
    update public.transactions set payee = '' where type in ('spending', 'inflow');
    raise exception 'undo' using errcode = 'P0099';
  exception when sqlstate 'P0099' then null;
  end $block$$test$,
  'R.20: spending and inflow without a payee are accepted');
select lives_ok($$insert into public.accounts(id,owner_id,name,type,opening_balance_minor,is_budget_account) values(gen_random_uuid(),'a0000000-0000-4000-8000-000000000001','Another budget','savingsCash',0,true)$$,
  'several budget accounts per owner');

select lives_ok($$insert into public.accounts(id,owner_id,name,type,opening_balance_minor) values
  (gen_random_uuid(),'a0000000-0000-4000-8000-000000000001','É','savingsCash',0),
  (gen_random_uuid(),'a0000000-0000-4000-8000-000000000001','é','savingsCash',0)$$,
  'non-ASCII names remain distinct as in SQLite NOCASE');
select lives_ok($$update public.transactions set date = date '0001-02-29 BC' where type = 'inflow'$$,
  'ISO year zero leap day maps to PostgreSQL 1 BC');
select lives_ok($$update public.monthly_plans set month = '0000-01'$$, 'ISO year zero month remains valid');
select lives_ok($$update public.monthly_plans set month = '2026-11'$$, 'restore fixture months');
select lives_ok($$update public.transactions set amount_minor = 9007199254740991 where type = 'inflow'$$,
  'large integer money remains exact without floating point');
-- R.18: the table lets a Spending have no category (a card purchase); the
-- write API and import keep it to Credit sources, since a check cannot see
-- the account type.
select lives_ok($$insert into public.transactions(id,owner_id,type,amount_minor,date,payee,source_account_id) values
  ('40000000-0000-4000-8000-000000000099','a0000000-0000-4000-8000-000000000001','spending',100,'2026-11-25','7/11',
   '20000000-0000-4000-8000-000000000002')$$,
  'a spending may have no category at table level');
delete from public.transactions where id = '40000000-0000-4000-8000-000000000099';

-- Detachment and cascade semantics are checked independently of API workflows.
insert into public.accounts(id,owner_id,name,type,opening_balance_minor) values
  ('20000000-0000-4000-8000-000000000099','a0000000-0000-4000-8000-000000000001','Unused debt','loan',0);
insert into public.categories(id,owner_id,name,kind,plan_group,linked_account_id) values
  ('30000000-0000-4000-8000-000000000099','a0000000-0000-4000-8000-000000000001','Unused debt plan','spending','liability','20000000-0000-4000-8000-000000000099');
insert into public.monthly_plans(id,owner_id,month,category_id,assigned_amount_minor) values
  (gen_random_uuid(),'a0000000-0000-4000-8000-000000000001','2026-11','30000000-0000-4000-8000-000000000099',0);
select lives_ok($$delete from public.accounts where id = '20000000-0000-4000-8000-000000000099'$$,
  'unused account deletion detaches category link');
select ok((select owner_id = 'a0000000-0000-4000-8000-000000000001' and linked_account_id is null and revision = 2
  from public.categories where id = '30000000-0000-4000-8000-000000000099'),
  'detachment preserves owner and advances revision');
select lives_ok($$delete from public.categories where id = '30000000-0000-4000-8000-000000000099'$$,
  'unused category deletion cascades its monthly plans');
select is((select count(*) from public.monthly_plans), 2::bigint, 'only original monthly plans remain');

-- These checks execute real writes against all tables, not only catalog checks.
select lives_ok(format('update public.%I set revision = 999999', t), t || ': server controls revisions')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select ok((select bool_and(revision <> 999999 and revision > 1) from public.accounts), 'provided revision was overridden');
select throws_ok(format('update public.%I set owner_id = %L', t, 'b0000000-0000-4000-8000-000000000001'),
  '23514', null, t || ': owner cannot change')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select throws_ok(format('update public.%I set id = gen_random_uuid()', t),
  '23514', null, t || ': identity cannot change')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select lives_ok($$insert into public.accounts(id,owner_id,name,type,opening_balance_minor,revision)
  values(gen_random_uuid(),'a0000000-0000-4000-8000-000000000001','Server revision','savingsCash',0,-99)$$,
  'server replaces client-supplied initial revision');
select is((select revision from public.accounts where name = 'Server revision'), 1::bigint, 'initial revision is one');

-- Role/JWT simulation, using the same auth.uid() function as the Data API.
select set_config('request.jwt.claim.sub', 'a0000000-0000-4000-8000-000000000001', true);
set local role authenticated;
select results_eq(format('select distinct owner_id from public.%I', t),
  array['a0000000-0000-4000-8000-000000000001'::uuid], t || ': user A reads only A')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select throws_ok(format('insert into public.%I(id, owner_id) values(gen_random_uuid(), auth.uid())', t),
  '42501', null, t || ': authenticated INSERT denied')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select throws_ok(format('update public.%I set revision = 8', t),
  '42501', null, t || ': authenticated UPDATE denied')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select throws_ok(format('delete from public.%I', t),
  '42501', null, t || ': authenticated DELETE denied')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select throws_ok(format('truncate public.%I cascade', t),
  '42501', null, t || ': authenticated TRUNCATE denied')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select ok(not has_function_privilege('authenticated', 'public.fundly_set_revision()', 'execute'),
  'revision trigger function is not an authenticated RPC');
reset role;
select set_config('request.jwt.claim.sub', 'b0000000-0000-4000-8000-000000000001', true);
set local role authenticated;
select results_eq(format('select distinct owner_id from public.%I', t),
  array['b0000000-0000-4000-8000-000000000001'::uuid], t || ': user B reads only B')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select throws_ok($$update public.accounts set owner_id = auth.uid() where owner_id <> auth.uid()$$,
  '42501', null, 'forged ownership update is denied');
reset role;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '{}', true);
set local role authenticated;
select is_empty(format('select id from public.%I', t), t || ': missing user claim sees no records')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
reset role;
set local role anon;
select throws_ok(format('select * from public.%I', t),
  '42501', null, t || ': anonymous SELECT denied')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select throws_ok(format('insert into public.%I(id,owner_id) values(gen_random_uuid(),gen_random_uuid())', t),
  '42501', null, t || ': anonymous INSERT denied')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select throws_ok(format('update public.%I set revision = 8', t),
  '42501', null, t || ': anonymous UPDATE denied')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
select throws_ok(format('delete from public.%I', t),
  '42501', null, t || ': anonymous DELETE denied')
from unnest(array['custom_account_types','accounts','categories','transactions','monthly_plans']) t;
reset role;

select * from finish();
rollback;
