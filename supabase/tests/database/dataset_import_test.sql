begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select no_plan();

-- A: imports, then replaces. B: untouched defaults. C: a renamed default.
-- D: stays empty (every refused import). E: another owner trying A's IDs.
insert into auth.users(id,email) values
  ('a6100000-0000-4000-8000-000000000001','import-a@example.invalid'),
  ('b6100000-0000-4000-8000-000000000001','import-b@example.invalid'),
  ('c6100000-0000-4000-8000-000000000001','import-c@example.invalid'),
  ('d6100000-0000-4000-8000-000000000001','import-d@example.invalid'),
  ('e6100000-0000-4000-8000-000000000001','import-e@example.invalid');

-- Stable IDs per seed, so each successful import can use fresh ones.
create function pg_temp.id(seed text, name text) returns text language sql immutable as $$
  select md5(seed || ':' || name)::uuid::text
$$;

-- A valid dataset covering every table, flag and transaction type.
create function pg_temp.dataset(s text) returns jsonb language sql as $$
  select jsonb_build_object(
    'custom_account_types', jsonb_build_array(
      jsonb_build_object('id',pg_temp.id(s,'T1'),'name','Wallets','base_type','savingsCash',
        'created_at','2025-01-02T03:04:05.123456Z','updated_at','2025-02-03T04:05:06Z')),
    'accounts', jsonb_build_array(
      jsonb_build_object('id',pg_temp.id(s,'A1'),'name','Cash','type','savingsCash',
        'opening_balance_minor','10000','currency_code','PHP','is_archived',false,
        'custom_type_id',pg_temp.id(s,'T1'),'is_budget_account',true,
        'created_at','2025-01-05T00:00:00Z'),
      jsonb_build_object('id',pg_temp.id(s,'A2'),'name','Card','type','credit',
        'opening_balance_minor','-2000','currency_code','PHP','is_archived',false,
        'custom_type_id',null,'is_budget_account',false),
      jsonb_build_object('id',pg_temp.id(s,'A3'),'name','Loan','type','loan',
        'opening_balance_minor','0','currency_code','PHP','is_archived',false,
        'custom_type_id',null,'is_budget_account',false),
      jsonb_build_object('id',pg_temp.id(s,'A4'),'name','Old card','type','credit',
        'opening_balance_minor','0','currency_code','PHP','is_archived',true,
        'custom_type_id',null,'is_budget_account',false)),
    'categories', jsonb_build_array(
      jsonb_build_object('id',pg_temp.id(s,'C1'),'name','Food','kind','spending','is_archived',false,
        'is_plan_archived',false,'is_plan_deleted',false,'plan_group','spending','linked_account_id',null),
      jsonb_build_object('id',pg_temp.id(s,'C2'),'name','Salary','kind','inflow','is_archived',false,
        'is_plan_archived',false,'is_plan_deleted',false,'plan_group','spending','linked_account_id',null),
      jsonb_build_object('id',pg_temp.id(s,'C3'),'name','Card debt','kind','spending','is_archived',false,
        'is_plan_archived',false,'is_plan_deleted',false,'plan_group','liability',
        'linked_account_id',pg_temp.id(s,'A2')),
      jsonb_build_object('id',pg_temp.id(s,'C4'),'name','Loan debt','kind','spending','is_archived',false,
        'is_plan_archived',true,'is_plan_deleted',false,'plan_group','liability',
        'linked_account_id',pg_temp.id(s,'A3')),
      jsonb_build_object('id',pg_temp.id(s,'C5'),'name','Old card debt','kind','spending','is_archived',true,
        'is_plan_archived',false,'is_plan_deleted',false,'plan_group','liability',
        'linked_account_id',pg_temp.id(s,'A4')),
      jsonb_build_object('id',pg_temp.id(s,'C6'),'name','Gone','kind','spending','is_archived',true,
        'is_plan_archived',true,'is_plan_deleted',true,'plan_group','savings','linked_account_id',null)),
    'transactions', jsonb_build_array(
      jsonb_build_object('id',pg_temp.id(s,'X1'),'type','spending','amount_minor','150','currency_code','PHP',
        'date','2026-11-20','payee','Shop','category_id',pg_temp.id(s,'C1'),
        'source_account_id',pg_temp.id(s,'A1'),'destination_account_id',null,'note','Weekly',
        'created_at','2026-11-20T10:00:00.5Z','updated_at','2026-11-21T10:00:00Z'),
      jsonb_build_object('id',pg_temp.id(s,'X2'),'type','inflow','amount_minor','50000','currency_code','PHP',
        'date','2026-11-15','payee','Work','category_id',pg_temp.id(s,'C2'),
        'source_account_id',null,'destination_account_id',pg_temp.id(s,'A1'),'note',''),
      jsonb_build_object('id',pg_temp.id(s,'X3'),'type','transfer','amount_minor','2000','currency_code','PHP',
        'date','2026-11-16','payee','','category_id',null,
        'source_account_id',pg_temp.id(s,'A1'),'destination_account_id',pg_temp.id(s,'A3'),'note',''),
      jsonb_build_object('id',pg_temp.id(s,'X4'),'type','creditCardPayment','amount_minor','3000',
        'currency_code','PHP','date','2026-11-17','payee','','category_id',null,
        'source_account_id',pg_temp.id(s,'A1'),'destination_account_id',pg_temp.id(s,'A2'),'note',''),
      -- History on an archived account and an archived category is allowed.
      jsonb_build_object('id',pg_temp.id(s,'X5'),'type','spending','amount_minor','99','currency_code','PHP',
        'date','0000-01-01','payee','Old shop','category_id',pg_temp.id(s,'C6'),
        'source_account_id',pg_temp.id(s,'A4'),'destination_account_id',null,'note','')),
    'monthly_plans', jsonb_build_array(
      jsonb_build_object('id',pg_temp.id(s,'P1'),'month','2026-11','category_id',pg_temp.id(s,'C1'),
        'target_amount_minor','500','assigned_amount_minor','300','currency_code','PHP'),
      jsonb_build_object('id',pg_temp.id(s,'P2'),'month','2026-11','category_id',pg_temp.id(s,'C3'),
        'target_amount_minor',null,'assigned_amount_minor','0','currency_code','PHP')))
$$;

create function pg_temp.request(mode text, dataset jsonb, expected jsonb default null) returns jsonb
language sql as $$
  select jsonb_build_object('version',1,'mode',mode,'dataset',dataset) ||
    case when expected is null then '{}'::jsonb else jsonb_build_object('expected',expected) end
$$;

-- 'ok', or the error and where the server says the problem is.
create function pg_temp.attempt(request jsonb, import uuid default gen_random_uuid()) returns text
language plpgsql as $$
declare message text; raw text; detail jsonb;
begin
  perform public.fundly_import_dataset(import, request);
  return 'ok';
exception when others then
  get stacked diagnostics message = message_text, raw = pg_exception_detail;
  detail := nullif(raw, '')::jsonb;
  if detail ? 'table' then
    return message || ' ' || (detail->>'table') || '[' || (detail->>'index') || ']'
      || coalesce('.' || (detail->>'field'), '') || coalesce(' ' || (detail->>'rule'), '');
  end if;
  return message;
end;
$$;

-- Refused imports run as D, whose dataset stays empty.
create function pg_temp.try(dataset jsonb) returns text language sql as $$
  select pg_temp.attempt(pg_temp.request('into_empty', dataset))
$$;

-- 'ok' when D's import would succeed; the import is rolled back either way,
-- so D's dataset stays empty.
create function pg_temp.try_rolled_back(dataset jsonb) returns text
language plpgsql as $$
declare outcome text;
begin
  begin
    outcome := pg_temp.try(dataset);
    raise exception 'rolled_back';
  exception when others then
    if sqlerrm <> 'rolled_back' then raise; end if;
  end;
  return outcome;
end;
$$;

create function pg_temp.act(owner text) returns void language sql as $$
  select set_config('request.jwt.claim.sub', owner, true)
$$;

-- Envelope and access.
select throws_ok($$select public.fundly_import_dataset(gen_random_uuid(),
  pg_temp.request('into_empty', pg_temp.dataset('x')))$$,'28000','authentication_required','sign-in required');

set local role authenticated;
select pg_temp.act('d6100000-0000-4000-8000-000000000001');
select is(pg_temp.attempt(null),'invalid_request','a request is required');
select is(pg_temp.attempt(pg_temp.request('into_empty', pg_temp.dataset('x')), null),'invalid_request',
  'an import ID is required');
select is(pg_temp.attempt(jsonb_build_object('version',1,'pad',repeat('x',8388608))),'invalid_request',
  'a request over 8 MB is refused');
select is(pg_temp.attempt(pg_temp.request('into_empty', pg_temp.dataset('x')) || '{"version":2}'),
  'invalid_request','only version 1');
select is(pg_temp.attempt(pg_temp.request('into_empty', pg_temp.dataset('x')) || '{"extra":1}'),
  'invalid_request','no unknown keys');
select is(pg_temp.attempt(pg_temp.request('merge', pg_temp.dataset('x'))),'invalid_request','known modes only');
select is(pg_temp.attempt(pg_temp.request('replace', pg_temp.dataset('x'))),'invalid_request',
  'replace needs the expected counts');
select is(pg_temp.attempt(pg_temp.request('replace', pg_temp.dataset('x'),
  '{"custom_account_types":0,"accounts":0,"categories":0,"transactions":0}')),'invalid_request',
  'expected names every table');
select is(pg_temp.attempt(pg_temp.request('replace', pg_temp.dataset('x'),
  '{"custom_account_types":0,"accounts":-1,"categories":0,"transactions":0,"monthly_plans":0}')),
  'invalid_request','expected counts are non-negative integers');
select is(pg_temp.try(pg_temp.dataset('x') - 'monthly_plans'),'invalid_request','every table is present');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{accounts}','{}')),'invalid_request',
  'every table is an array');

-- Record shape.
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{accounts,0}','1')),
  'invalid_import accounts[0] not_an_object','records are objects');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{accounts,1,owner_id}',
  '"a6100000-0000-4000-8000-000000000001"')),'invalid_import accounts[1].owner_id unknown_field',
  'the owner is never sent');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,2,revision}','"1"')),
  'invalid_import transactions[2].revision unknown_field','revisions are never sent');
select is(pg_temp.try(pg_temp.dataset('x') #- '{categories,3,plan_group}'),
  'invalid_import categories[3].plan_group missing','fields other than timestamps are required');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{accounts,0,id}','"nope"')),
  'invalid_import accounts[0].id invalid_value','IDs are UUIDs');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{accounts,0,is_archived}','"false"')),
  'invalid_import accounts[0].is_archived invalid_value','flags are booleans');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,0,created_at}','"2026-11-20T10:00:00"')),
  'invalid_import transactions[0].created_at invalid_value','timestamps are UTC');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,0,date}','"2026-02-30"')),
  'invalid_import transactions[0].date invalid_value','dates are real dates');

-- Custom account types.
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{custom_account_types,0,name}','" Wallets"')),
  'invalid_import custom_account_types[0].name invalid_name','names are trimmed');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{custom_account_types,0,name}',to_jsonb(repeat('w',41)))),
  'invalid_import custom_account_types[0].name invalid_name','names are at most 40 characters');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{custom_account_types,0,name}','"Credit"')),
  'invalid_import custom_account_types[0].name name_taken','built-in type names are taken');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{custom_account_types,0,base_type}','"stocks"')),
  'invalid_import custom_account_types[0].base_type invalid_value','known base types only');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{custom_account_types,1}',
  jsonb_build_object('id',pg_temp.id('x','T2'),'name','WALLETS','base_type','credit'))),
  'invalid_import custom_account_types[1].name name_taken','type names are unique ignoring case');

-- Accounts.
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{accounts,1,name}','"CASH"')),
  'invalid_import accounts[1].name name_taken','account names are unique ignoring case');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{accounts,1,id}',to_jsonb(pg_temp.id('x','A1')))),
  'invalid_import accounts[1].id duplicate_id','IDs are unique');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{accounts,1,opening_balance_minor}','"100"')),
  'invalid_import accounts[1].opening_balance_minor wrong_sign','owed balances are not positive');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{accounts,0,opening_balance_minor}','"-1"')),
  'invalid_import accounts[0].opening_balance_minor wrong_sign','asset balances are not negative');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{accounts,0,opening_balance_minor}','"-0"')),
  'invalid_import accounts[0].opening_balance_minor invalid_value','money is canonical');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{accounts,0,currency_code}','"USD"')),
  'invalid_import accounts[0].currency_code invalid_value','PHP only');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{accounts,1,custom_type_id}',to_jsonb(pg_temp.id('x','T1')))),
  'invalid_import accounts[1].custom_type_id invalid_reference','a custom type has the account''s base type');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{accounts,1,is_budget_account}','true')),
  'invalid_import accounts[1].is_budget_account not_eligible','the budget account is Savings/Cash');
select is(pg_temp.try_rolled_back(jsonb_set(pg_temp.dataset('x'),'{accounts,4}',
  jsonb_build_object('id',pg_temp.id('x','A5'),'name','Spare','type','savingsCash',
    'opening_balance_minor','0','currency_code','PHP','is_archived',false,
    'custom_type_id',null,'is_budget_account',true))),
  'ok','several budget accounts import');
select is(pg_temp.try(jsonb_set(jsonb_set(pg_temp.dataset('x'),'{accounts,0,is_archived}','true'),
  '{accounts,0,is_budget_account}','true')),
  'invalid_import accounts[0].is_budget_account not_eligible','an archived account is not the budget account');

-- Categories and linked Plans rows.
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{categories,1,plan_group}','"savings"')),
  'invalid_import categories[1].plan_group invalid_value','inflow categories have no group');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{categories,1,is_plan_archived}','true')),
  'invalid_import categories[1].is_plan_archived invalid_value','only spending rows are Plans rows');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{categories,0,is_plan_deleted}','true')),
  'invalid_import categories[0].is_plan_deleted invalid_value','a deleted Plans row is archived first');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{categories,2,linked_account_id}',to_jsonb(pg_temp.id('x','A1')))),
  'invalid_import categories[2].linked_account_id invalid_link','only liability accounts are linked');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{categories,2,plan_group}','"spending"')),
  'invalid_import categories[2].linked_account_id invalid_link','linked rows are in the Liability group');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{categories,4,is_archived}','false')),
  'invalid_import categories[4].linked_account_id invalid_link','a linked row follows its account''s archive');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{categories,3,linked_account_id}',to_jsonb(pg_temp.id('x','A2')))),
  'invalid_import categories[3].linked_account_id invalid_link','one linked row per account');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{categories,3,linked_account_id}',to_jsonb(pg_temp.id('x','A9')))),
  'invalid_import categories[3].linked_account_id invalid_link','a linked account is in the import');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{categories,3,linked_account_id}','null')),
  'invalid_import accounts[2].id missing_linked_category','every active liability account has a row');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{categories,1,name}','"food"')),
  'invalid_import categories[1].name name_taken','category names are unique ignoring case');

-- Transactions.
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,0,amount_minor}','"0"')),
  'invalid_import transactions[0].amount_minor invalid_value','amounts are positive');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,0,payee}','"  "')),
  'invalid_import transactions[0].payee invalid_value','Spending needs a payee');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,0,payee}',to_jsonb(repeat('p',61)))),
  'invalid_import transactions[0].payee invalid_value','payees are at most 60 characters');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,0,note}',to_jsonb(repeat('n',501)))),
  'invalid_import transactions[0].note invalid_value','notes are at most 500 characters');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,0,category_id}','null')),
  'invalid_import transactions[0] invalid_shape','Spending needs a category');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,2,destination_account_id}',to_jsonb(pg_temp.id('x','A1')))),
  'invalid_import transactions[2].destination_account_id same_account','no transfer to the same account');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,0,source_account_id}',to_jsonb(pg_temp.id('x','A9')))),
  'invalid_import transactions[0].source_account_id invalid_reference','accounts are in the import');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,0,category_id}',to_jsonb(pg_temp.id('x','C9')))),
  'invalid_import transactions[0].category_id invalid_reference','categories are in the import');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,0,source_account_id}',to_jsonb(pg_temp.id('x','A3')))),
  'invalid_import transactions[0].source_account_id account_not_allowed','no Spending from a loan');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,2,destination_account_id}',to_jsonb(pg_temp.id('x','A2')))),
  'invalid_import transactions[2].destination_account_id account_not_allowed','no Transfer to a card');
select is(pg_temp.try_rolled_back(jsonb_set(jsonb_set(pg_temp.dataset('x'),
    '{transactions,2,source_account_id}',to_jsonb(pg_temp.id('x','A2'))),
    '{transactions,2,destination_account_id}',to_jsonb(pg_temp.id('x','A1')))),
  'ok','a cash advance is a Transfer from a card to Savings/Cash');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,2,source_account_id}',to_jsonb(pg_temp.id('x','A2')))),
  'invalid_import transactions[2].destination_account_id account_not_allowed','a cash advance cannot go to a loan');
select is(pg_temp.try(jsonb_set(jsonb_set(pg_temp.dataset('x'),
    '{transactions,2,source_account_id}',to_jsonb(pg_temp.id('x','A3'))),
    '{transactions,2,destination_account_id}',to_jsonb(pg_temp.id('x','A1')))),
  'invalid_import transactions[2].source_account_id account_not_allowed','no Transfer from a loan');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,3,destination_account_id}',to_jsonb(pg_temp.id('x','A3')))),
  'invalid_import transactions[3].destination_account_id account_not_allowed','card payments go to a card');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,3,source_account_id}',to_jsonb(pg_temp.id('x','A4')))),
  'invalid_import transactions[3].source_account_id account_not_allowed','card payments come from Savings/Cash');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,0,category_id}',to_jsonb(pg_temp.id('x','C2')))),
  'invalid_import transactions[0].category_id category_not_allowed','Spending uses a spending category');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,0,category_id}',to_jsonb(pg_temp.id('x','C3')))),
  'invalid_import transactions[0].category_id category_not_allowed','linked debt rows are not categories');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{transactions,1,category_id}',to_jsonb(pg_temp.id('x','C1')))),
  'invalid_import transactions[1].category_id category_not_allowed','Inflow uses an inflow category');

-- Monthly plans.
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{monthly_plans,0,category_id}',to_jsonb(pg_temp.id('x','C2')))),
  'invalid_import monthly_plans[0].category_id category_not_allowed','plans need a spending category');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{monthly_plans,0,category_id}',to_jsonb(pg_temp.id('x','C6')))),
  'invalid_import monthly_plans[0].category_id category_not_allowed','no plans on a deleted Plans row');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{monthly_plans,0,category_id}',to_jsonb(pg_temp.id('x','C9')))),
  'invalid_import monthly_plans[0].category_id invalid_reference','plan categories are in the import');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{monthly_plans,1,category_id}',to_jsonb(pg_temp.id('x','C1')))),
  'invalid_import monthly_plans[1].month duplicate_plan','one plan per category per month');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{monthly_plans,0,assigned_amount_minor}','"-1"')),
  'invalid_import monthly_plans[0].assigned_amount_minor invalid_value','amounts are not negative');
select is(pg_temp.try(jsonb_set(pg_temp.dataset('x'),'{monthly_plans,0,month}','"2026-13"')),
  'invalid_import monthly_plans[0].month invalid_value','months are YYYY-MM');

reset role;
select is((select count(*)::int from public.accounts where owner_id='d6100000-0000-4000-8000-000000000001'),0,
  'refused imports change nothing');
select is((select count(*)::int from public.fundly_import_receipts),0,'refused imports leave no receipt');
set local role authenticated;

-- A: import into an empty account.
select pg_temp.act('a6100000-0000-4000-8000-000000000001');
select is(public.fundly_import_dataset('76100000-0000-4000-8000-000000000001',
    pg_temp.request('into_empty', pg_temp.dataset('a'))),
  jsonb_build_object('version',1,'import_id','76100000-0000-4000-8000-000000000001','mode','into_empty',
    'counts',jsonb_build_object('custom_account_types',1,'accounts',4,'categories',6,'transactions',5,
      'monthly_plans',2)),
  'an empty account accepts the import and returns its counts');

reset role;
select results_eq(
  $$select name, type, opening_balance_minor, is_archived, custom_type_id::text, is_budget_account,
      created_at, revision from public.accounts
    where owner_id='a6100000-0000-4000-8000-000000000001' order by name$$,
  $$values ('Card','credit',-2000::bigint,false,null::text,false,now(),1::bigint),
    ('Cash','savingsCash',10000,false,pg_temp.id('a','T1'),true,'2025-01-05T00:00:00Z'::timestamptz,1),
    ('Loan','loan',0,false,null,false,now(),1),
    ('Old card','credit',0,true,null,false,now(),1)$$,
  'accounts keep their values, flags and timestamps; missing timestamps use the import time');
select results_eq(
  $$select name, kind, is_archived, is_plan_archived, is_plan_deleted, plan_group, linked_account_id::text
    from public.categories where owner_id='a6100000-0000-4000-8000-000000000001' order by name$$,
  $$values ('Card debt','spending',false,false,false,'liability',pg_temp.id('a','A2')),
    ('Food','spending',false,false,false,'spending',null),
    ('Gone','spending',true,true,true,'savings',null),
    ('Loan debt','spending',false,true,false,'liability',pg_temp.id('a','A3')),
    ('Old card debt','spending',true,false,false,'liability',pg_temp.id('a','A4')),
    ('Salary','inflow',false,false,false,'spending',null)$$,
  'categories keep their flags, groups and links');
select is((select fundly_private.transaction_wire(t) - 'owner_id' from public.transactions t
    where id = pg_temp.id('a','X1')::uuid),
  jsonb_build_object('id',pg_temp.id('a','X1'),'type','spending','amount_minor','150','currency_code','PHP',
    'date','2026-11-20','payee','Shop','category_id',pg_temp.id('a','C1'),
    'source_account_id',pg_temp.id('a','A1'),'destination_account_id',null,'note','Weekly',
    'created_at','2026-11-20T10:00:00.500000Z','updated_at','2026-11-21T10:00:00.000000Z','revision','1'),
  'a transaction downloads exactly as imported');
select is((select fundly_private.transaction_wire(t)->>'date' from public.transactions t
    where id = pg_temp.id('a','X5')::uuid),'0000-01-01','year 0000 survives the round trip');
select results_eq(
  $$select month, target_amount_minor, assigned_amount_minor from public.monthly_plans
    where owner_id='a6100000-0000-4000-8000-000000000001' order by assigned_amount_minor$$,
  $$values ('2026-11',null::bigint,0::bigint), ('2026-11',500,300)$$,
  'plans keep their Target and Assigned');
select is((select bool_and(revision = 1) from (
    select revision from public.custom_account_types where owner_id='a6100000-0000-4000-8000-000000000001'
    union all select revision from public.categories where owner_id='a6100000-0000-4000-8000-000000000001'
    union all select revision from public.transactions where owner_id='a6100000-0000-4000-8000-000000000001'
  ) r),true,'imported records start at revision 1');
set local role authenticated;

-- Retries.
select is((public.fundly_import_dataset('76100000-0000-4000-8000-000000000001',
    pg_temp.request('into_empty', pg_temp.dataset('a')))->'counts'->>'transactions'),'5',
  'a retry returns the first result');
reset role;
select is((select count(*)::int from public.transactions where owner_id='a6100000-0000-4000-8000-000000000001'),5,
  'a retry imports nothing twice');
set local role authenticated;
select is(pg_temp.attempt(pg_temp.request('into_empty', pg_temp.dataset('a2')),
    '76100000-0000-4000-8000-000000000001'),'import_key_reused','an import ID cannot carry another body');
select is(pg_temp.attempt(pg_temp.request('into_empty', pg_temp.dataset('a2'))),'dataset_not_empty',
  'into_empty refuses an account with records');

-- A: replace.
select is(pg_temp.attempt(pg_temp.request('replace', pg_temp.dataset('a2'),
  '{"custom_account_types":1,"accounts":4,"categories":6,"transactions":4,"monthly_plans":2}')),
  'dataset_changed','replace refuses when the account changed since the user confirmed');
select is(public.fundly_import_dataset('76100000-0000-4000-8000-000000000002',
    pg_temp.request('replace', pg_temp.dataset('a2'),
      '{"custom_account_types":1,"accounts":4,"categories":6,"transactions":5,"monthly_plans":2}'))->>'mode',
  'replace','replace accepts matching counts');
reset role;
select is((select count(*)::int from public.accounts
    where owner_id='a6100000-0000-4000-8000-000000000001' and id = pg_temp.id('a2','A1')::uuid),1,
  'the new dataset is in place');
select is((select count(*)::int from public.fundly_deleted_records
    where owner_id='a6100000-0000-4000-8000-000000000001'),18,'every replaced record is tombstoned');
select is((select count(*)::int from public.transactions where owner_id='a6100000-0000-4000-8000-000000000001'),5,
  'only the new dataset remains');
set local role authenticated;

-- IDs.
select is(pg_temp.attempt(pg_temp.request('replace', pg_temp.dataset('a'),
  '{"custom_account_types":1,"accounts":4,"categories":6,"transactions":5,"monthly_plans":2}')),
  'record_id_unavailable accounts[0].id','retired IDs cannot come back');
select pg_temp.act('e6100000-0000-4000-8000-000000000001');
select is(pg_temp.attempt(pg_temp.request('into_empty', pg_temp.dataset('a2'))),
  'record_id_unavailable accounts[0].id','another owner''s IDs are unavailable, without saying whose');
select is(pg_temp.attempt(pg_temp.request('into_empty', jsonb_set(pg_temp.dataset('e'),
  '{transactions,4,id}',to_jsonb(pg_temp.id('a2','X1'))))),
  'record_id_unavailable transactions[4].id','every table is checked');

-- B: untouched defaults count as empty and are replaced.
select pg_temp.act('b6100000-0000-4000-8000-000000000001');
select is((public.fundly_apply_operations(gen_random_uuid(),'{"version":1,"items":[
  {"operation":"dataset.initialize","id":"66100000-0000-4000-8000-000000000001"}]}')
  ->'results'->0->>'initialized'),'true','B starts with the defaults');
select is(pg_temp.attempt(pg_temp.request('into_empty', pg_temp.dataset('b'))),'ok',
  'untouched defaults count as empty');
reset role;
select is((select count(*)::int from public.categories where owner_id='b6100000-0000-4000-8000-000000000001'),6,
  'the defaults are replaced, not merged');
select is((select count(*)::int from public.fundly_deleted_records
    where owner_id='b6100000-0000-4000-8000-000000000001' and entity = 'categories'),9,
  'the replaced defaults are tombstoned, so other devices remove them');
set local role authenticated;

-- C: a changed default is a real record.
select pg_temp.act('c6100000-0000-4000-8000-000000000001');
select is((public.fundly_apply_operations(gen_random_uuid(),'{"version":1,"items":[
  {"operation":"dataset.initialize","id":"66100000-0000-4000-8000-000000000002"}]}')
  ->'results'->0->>'initialized'),'true','C starts with the defaults');
select is((public.fundly_apply_operations(gen_random_uuid(), jsonb_build_object('version',1,'items',
  jsonb_build_array(jsonb_build_object('operation','category.update','expected_revision','1',
    'id',(select id from public.categories where name='Rent'
      and owner_id='c6100000-0000-4000-8000-000000000001'),
    'data',jsonb_build_object('name','Housing')))))->'results'->0->>'revision'),'2','C renames a default');
select is(pg_temp.attempt(pg_temp.request('into_empty', pg_temp.dataset('c'))),'dataset_not_empty',
  'a renamed default makes the account non-empty');

-- Other owners.
reset role;
select is((select count(*)::int from public.categories where owner_id='c6100000-0000-4000-8000-000000000001'),9,
  'a refused import leaves the account as it was');
select is((select count(*)::int from public.accounts where owner_id='e6100000-0000-4000-8000-000000000001'),0,
  'nothing reaches an owner whose import was refused');
select is((select count(*)::int from public.accounts where owner_id='a6100000-0000-4000-8000-000000000001'),4,
  'imports by others leave A''s data alone');
select is((select count(*)::int from public.fundly_import_receipts),3,'one receipt per accepted import');

-- Access.
select is(has_function_privilege('anon','public.fundly_import_dataset(uuid,jsonb)','execute'),false,
  'anonymous users cannot import');
select is(has_table_privilege('authenticated','public.fundly_import_receipts','select'),false,
  'receipts are backend-only');

select * from finish();
rollback;
