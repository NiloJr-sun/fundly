begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select no_plan();
\ir ../fixtures/write_api.inc

insert into public.custom_account_types(id,owner_id,name,base_type) values
  ('11000000-0000-4000-8000-000000000001','a1000000-0000-4000-8000-000000000001','E-wallet','savingsCash'),
  ('11000000-0000-4000-8000-000000000002','b1000000-0000-4000-8000-000000000001','E-wallet','savingsCash');
create function pg_temp.operation(op text, record_id uuid, data jsonb default null, revision text default null)
returns jsonb language sql as $$
  select jsonb_build_object('operation',op,'id',record_id) ||
    case when data is null then '{}'::jsonb else jsonb_build_object('data',data) end ||
    case when revision is null then '{}'::jsonb else jsonb_build_object('expected_revision',revision) end
$$;
create function pg_temp.call(item jsonb, batch uuid default gen_random_uuid())
returns jsonb language sql as $$
  select public.fundly_apply_operations(batch,jsonb_build_object('version',1,'items',jsonb_build_array(item)))
$$;
create function pg_temp.account(patch jsonb default '{}', record_id uuid default gen_random_uuid())
returns jsonb language sql as $$
  select pg_temp.operation('account.create',record_id,
    '{"name":"New cash","type":"savingsCash","entered_opening_amount_minor":"0"}'::jsonb||patch)
$$;
create table pg_temp.responses(name text primary key,value jsonb);
grant select,insert on pg_temp.responses to authenticated;
select set_config('request.jwt.claim.sub','a1000000-0000-4000-8000-000000000001',true);
set local role authenticated;

select throws_ok(format('select pg_temp.call(pg_temp.account(%L::jsonb))',patch),state,message,description)
from (values
  ('{"name":"  "}','P0001','invalid_name','blank account name'),
  ('{"type":"unknown"}','P0001','invalid_account','unknown account base'),
  ('{"entered_opening_amount_minor":"-1"}','22023','invalid_request','negative entered opening amount'),
  ('{"entered_opening_amount_minor":0}','22023','invalid_request','opening amount must be decimal string'),
  ('{"entered_opening_amount_minor":"00"}','22023','invalid_request','noncanonical opening zero'),
  ('{"entered_opening_amount_minor":"9223372036854775808"}','22023','invalid_request','opening overflow'),
  ('{"currency_code":"USD"}','P0001','invalid_account','account currency fixed to PHP'),
  ('{"currency_code":null}','22023','invalid_request','null currency rejected'),
  ('{"is_budget_account":true}','22023','invalid_request','budget flag requires guarded operation'),
  ('{"is_archived":true}','22023','invalid_request','archive flag requires separate operation'),
  ('{"owner_id":"b1000000-0000-4000-8000-000000000001"}','22023','invalid_request','cannot forge account owner'),
  ('{"custom_type_id":"11000000-0000-4000-8000-000000000002"}','P0001','record_not_accessible','foreign custom type'),
  ('{"custom_type_id":"ffffffff-0000-4000-8000-000000000001"}','P0001','record_not_accessible','missing custom type same error'),
  ('{"type":"credit","custom_type_id":"11000000-0000-4000-8000-000000000001"}','P0001','invalid_account','custom base must match account base'),
  ('{"linked_category_id":"32000000-0000-4000-8000-000000000001"}','22023','invalid_request','asset cannot specify debt category identity')
) cases(patch,state,message,description);
select throws_ok($$select pg_temp.call(pg_temp.account(jsonb_build_object('name',repeat('😀',21))))$$,
  'P0001','invalid_name','account length counts UTF-16');
select throws_ok($$select pg_temp.call(pg_temp.account('{"name":"cASH"}'))$$,
  'P0001','name_taken','account names ignore ASCII case');
select throws_ok($$select pg_temp.call(pg_temp.account('{}','21000000-0000-4000-8000-000000000006'))$$,
  'P0001','record_id_unavailable','foreign account UUID unavailable without owner disclosure');

insert into pg_temp.responses values('cash',pg_temp.call(pg_temp.account(
  '{"name":"  New cash  ","entered_opening_amount_minor":"9223372036854775807","custom_type_id":"11000000-0000-4000-8000-000000000001"}',
  '22000000-0000-4000-8000-000000000001')));
select is((select value#>>'{results,0,record,name}' from pg_temp.responses where name='cash'),'New cash','account name trimmed');
select is((select value#>>'{results,0,record,opening_balance_minor}' from pg_temp.responses where name='cash'),
  '9223372036854775807','opening money exact decimal string');
select is((select value#>>'{results,0,revision}' from pg_temp.responses where name='cash'),'1','server initial revision');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.update','22000000-0000-4000-8000-000000000001',
  '{"custom_type_id":null}', '1'))$$,'explicit null clears custom type');
select ok((select custom_type_id is null from public.accounts where id='22000000-0000-4000-8000-000000000001'),'custom type cleared');
select is((select opening_balance_minor from public.accounts where id='22000000-0000-4000-8000-000000000001'),
  9223372036854775807::bigint,'omitted opening amount preserved');
select throws_ok($$select pg_temp.call(pg_temp.operation('account.update','22000000-0000-4000-8000-000000000001','{"name":"Stale"}','1'))$$,
  'P0001','revision_conflict','stale account edit');
select throws_ok($$select pg_temp.call(pg_temp.operation('account.update','22000000-0000-4000-8000-000000000001','{"type":"credit"}','2'))$$,
  '22023','invalid_request','base account type immutable');
select throws_ok($$select pg_temp.call(pg_temp.operation('account.update','22000000-0000-4000-8000-000000000001','{"currency_code":"PHP"}','2'))$$,
  '22023','invalid_request','currency not an editable field');
select throws_ok($$select pg_temp.call(pg_temp.operation('account.update','21000000-0000-4000-8000-000000000006','{"name":"Foreign"}','1'))$$,
  'P0001','record_not_accessible','foreign account update');

-- Custom types: unused class changes allowed, active and archived references block.
select lives_ok($$select pg_temp.call(pg_temp.operation('custom_type.create','12000000-0000-4000-8000-000000000001',
  '{"name":"  Pay later  ","base_type":"credit"}'))$$,'custom type creation');
select is((select name from public.custom_account_types where id='12000000-0000-4000-8000-000000000001'),'Pay later','custom type normalized');
select throws_ok(format('select pg_temp.call(pg_temp.operation(''custom_type.create'',gen_random_uuid(),%L::jsonb))',patch),state,message,description)
from (values
  ('{"name":"cREDIT","base_type":"credit"}','P0001','name_taken','built-in Credit name reserved'),
  ('{"name":" Savings / Cash ","base_type":"savingsCash"}','P0001','name_taken','built-in asset name reserved'),
  ('{"name":"LOAN","base_type":"loan"}','P0001','name_taken','built-in Loan name reserved'),
  ('{"name":"x","base_type":"unknown"}','P0001','invalid_custom_type','unknown custom base'),
  ('{"name":" ","base_type":"loan"}','P0001','invalid_name','blank custom type'),
  ('{"name":"PAY LATER","base_type":"loan"}','P0001','name_taken','custom names ignore case'),
  ('{"name":"x","base_type":"loan","created_at":"2000-01-01"}','22023','invalid_request','custom audit fields forbidden')
) cases(patch,state,message,description);
select lives_ok($$select pg_temp.call(pg_temp.operation('custom_type.update','12000000-0000-4000-8000-000000000001',
  '{"base_type":"loan"}','1'))$$,'unused custom type can change base');
select lives_ok($$select pg_temp.call(pg_temp.operation('custom_type.delete','12000000-0000-4000-8000-000000000001',null,'2'))$$,
  'unused custom type can be deleted');
select throws_ok($$select pg_temp.call(pg_temp.operation('custom_type.delete','11000000-0000-4000-8000-000000000002',null,'1'))$$,
  'P0001','record_not_accessible','foreign custom type delete');
select lives_ok($$select pg_temp.call(pg_temp.account('{"name":"Uses custom","custom_type_id":"11000000-0000-4000-8000-000000000001"}',
  '22000000-0000-4000-8000-000000000002'))$$,'custom type can be used by matching asset');
select throws_ok($$select pg_temp.call(pg_temp.operation('custom_type.update','11000000-0000-4000-8000-000000000001','{"base_type":"credit"}','1'))$$,
  'P0001','custom_type_in_use','active reference blocks base change');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.set_archived','22000000-0000-4000-8000-000000000002','{"archived":true}','1'))$$,
  'archive custom asset');
select throws_ok($$select pg_temp.call(pg_temp.operation('custom_type.delete','11000000-0000-4000-8000-000000000001',null,'1'))$$,
  'P0001','custom_type_in_use','archived reference blocks custom deletion');
select throws_ok($$select pg_temp.call(pg_temp.operation('custom_type.update','11000000-0000-4000-8000-000000000001','{"base_type":"loan"}','1'))$$,
  'P0001','custom_type_in_use','archived reference blocks class change');
select lives_ok($$select pg_temp.call(pg_temp.operation('custom_type.update','11000000-0000-4000-8000-000000000001','{"name":"Renamed wallet"}','1'))$$,
  'used custom type can still be renamed');

-- Liability category creation, request-supplied identity and replay stability.
insert into pg_temp.responses values('debt',pg_temp.call(pg_temp.account(
  '{"name":"New card","type":"credit","entered_opening_amount_minor":"12345","linked_category_id":"32000000-0000-4000-8000-000000000001"}',
  '22000000-0000-4000-8000-000000000003'),'62000000-0000-4000-8000-000000000001'));
select is((select value#>>'{results,0,record,opening_balance_minor}' from pg_temp.responses where name='debt'),'-12345','liability opening is signed server-side');
select is((select value#>>'{results,0,changes,0,id}' from pg_temp.responses where name='debt'),
  '32000000-0000-4000-8000-000000000001','client may supply linked category identity for offline use');
select ok((select kind='spending' and plan_group='liability' and not is_archived and not is_plan_archived and not is_plan_deleted
  from public.categories where id='32000000-0000-4000-8000-000000000001'),'new linked category defaults');
select is_empty($$select * from public.monthly_plans where category_id='32000000-0000-4000-8000-000000000001'$$,
  'linked row starts with no stored target or assignment');
select is(pg_temp.call(pg_temp.account(
  '{"name":"New card","type":"credit","entered_opening_amount_minor":"12345","linked_category_id":"32000000-0000-4000-8000-000000000001"}',
  '22000000-0000-4000-8000-000000000003'),'62000000-0000-4000-8000-000000000001'),
  (select value from pg_temp.responses where name='debt'),'retry keeps same linked category and response');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.update','22000000-0000-4000-8000-000000000003',
  '{"name":"Renamed card","entered_opening_amount_minor":"0"}','1'))$$,'liability rename/opening update');
select is((select name from public.categories where linked_account_id='22000000-0000-4000-8000-000000000003'),'Renamed card','linked name follows account');
select is((select opening_balance_minor from public.accounts where id='22000000-0000-4000-8000-000000000003'),0::bigint,'zero liability opening supported');

-- Independent plan flags must survive account changes.
reset role;
update public.categories set is_plan_archived=true,is_plan_deleted=true
  where linked_account_id='22000000-0000-4000-8000-000000000003';
set local role authenticated;
select lives_ok($$select pg_temp.call(pg_temp.operation('account.set_archived','22000000-0000-4000-8000-000000000003','{"archived":true}','2'))$$,
  'archive liability updates linked parent archive flag');
select ok((select is_archived and is_plan_archived and is_plan_deleted from public.categories
  where id='32000000-0000-4000-8000-000000000001'),'independent deleted-plan flags retained on archive');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.set_archived','22000000-0000-4000-8000-000000000003','{"archived":false}','3'))$$,
  'unarchive liability');
select ok((select not is_archived and is_plan_archived and is_plan_deleted from public.categories
  where id='32000000-0000-4000-8000-000000000001'),'unarchive does not resurrect permanently deleted plan');
select is((select count(*) from public.categories where linked_account_id='22000000-0000-4000-8000-000000000003'),1::bigint,'no duplicate linked category');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.set_archived','22000000-0000-4000-8000-000000000003','{"archived":true}','4'))$$,
  'archive before permanent account deletion');
insert into pg_temp.responses values('deleted',pg_temp.call(pg_temp.operation('account.delete','22000000-0000-4000-8000-000000000003',null,'5')));
select ok((select linked_account_id is null and owner_id='a1000000-0000-4000-8000-000000000001'
  from public.categories where id='32000000-0000-4000-8000-000000000001'),'account delete detaches category preserving owner');
select is_empty($$select id from public.monthly_plans where category_id='32000000-0000-4000-8000-000000000001'$$,
  'permanently deleted plan stays empty');
select is((select value#>>'{results,0,changes,0,record,linked_account_id}' from pg_temp.responses where name='deleted'),null::text,
  'detached category returned as canonical side effect');
select throws_ok($$select pg_temp.call(pg_temp.operation('account.delete','21000000-0000-4000-8000-000000000001',null,'1'))$$,
  'P0001','account_not_archived','active account cannot be deleted');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.set_archived','21000000-0000-4000-8000-000000000004','{"archived":true}','1'))$$,
  'archived account with history can stay archived');
select throws_ok($$select pg_temp.call(pg_temp.operation('account.delete','21000000-0000-4000-8000-000000000004',null,'2'))$$,
  'P0001','account_has_transactions','history blocks permanent deletion');

-- Collision handling is owner scoped and respects the 40 UTF-16-unit limit.
select lives_ok($$select pg_temp.call(pg_temp.account('{"name":"Food","type":"loan"}','22000000-0000-4000-8000-000000000004'))$$,
  'liability name may collide with ordinary category');
select is((select name from public.categories where linked_account_id='22000000-0000-4000-8000-000000000004'),
  'Food (debt 22000000)','short UUID debt suffix');
reset role;
insert into public.monthly_plans(id,owner_id,month,category_id,assigned_amount_minor)
  select gen_random_uuid(),owner_id,'2026-01',id,123 from public.categories
  where linked_account_id='22000000-0000-4000-8000-000000000004';
set local role authenticated;
select lives_ok($$select pg_temp.call(pg_temp.operation('account.set_archived','22000000-0000-4000-8000-000000000004','{"archived":true}','1'))$$,
  'unused liability with past assignments can be archived');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.delete','22000000-0000-4000-8000-000000000004',null,'2'))$$,
  'unused archived liability can be deleted while retaining its plan category');
select is((select p.assigned_amount_minor from public.monthly_plans p join public.categories c on c.id=p.category_id
  where c.name='Food (debt 22000000)'),123::bigint,'past allocations survive parent account deletion');
select lives_ok($$select pg_temp.call(pg_temp.account('{"name":"Food (debt 22000000)","type":"credit"}',
  '22000000-0000-4000-8000-000000000005'))$$,'another managed row can occupy next collision candidate');
reset role;
insert into public.categories(id,owner_id,name,kind) values
  (gen_random_uuid(),'a1000000-0000-4000-8000-000000000001','Clash','spending'),
  (gen_random_uuid(),'a1000000-0000-4000-8000-000000000001','Clash (debt 22000000)','spending');
set local role authenticated;
select lives_ok($$select pg_temp.call(pg_temp.account('{"name":"Clash","type":"credit"}',
  '22000000-0000-4000-8000-000000000006'))$$,'suffix collisions resolve with counter');
select is((select name from public.categories where linked_account_id='22000000-0000-4000-8000-000000000006'),
  'Clash (debt 22000000-1)','collision counter deterministic');
reset role;
insert into public.categories(id,owner_id,name,kind) values
  (gen_random_uuid(),'a1000000-0000-4000-8000-000000000001',repeat('😀',20),'spending');
set local role authenticated;
select lives_ok($$select pg_temp.call(pg_temp.account(jsonb_build_object('name',repeat('😀',20),'type','loan'),
  '22000000-0000-4000-8000-000000000007'))$$,'collision truncation preserves complete Unicode characters');
reset role;
select ok((select fundly_private.utf16_length(name)<=40 from public.categories
  where linked_account_id='22000000-0000-4000-8000-000000000007'),'suffix output fits UTF-16 limit');
-- A legacy valid signed bigint minimum must survive a metadata-only update.
insert into public.accounts(id,owner_id,name,type,opening_balance_minor) values
  ('22000000-0000-4000-8000-000000000008','a1000000-0000-4000-8000-000000000001','Legacy minimum','credit',-9223372036854775808);
set local role authenticated;
select lives_ok($$select pg_temp.call(pg_temp.operation('account.update','22000000-0000-4000-8000-000000000008','{"name":"Legacy kept"}','1'))$$,
  'metadata-only edit does not negate bigint minimum');
select is((select opening_balance_minor::text from public.accounts where id='22000000-0000-4000-8000-000000000008'),
  '-9223372036854775808','legacy signed balance preserved');
select throws_ok($$select pg_temp.call(pg_temp.account('{"name":"Conflicting child","type":"loan","linked_category_id":"31000000-0000-4000-8000-000000000005"}',
  '22000000-0000-4000-8000-000000000098'))$$,'P0001','record_id_unavailable','foreign child UUID cannot be reused');
select is_empty($$select id from public.accounts where id='22000000-0000-4000-8000-000000000098'$$,
  'linked UUID failure rolls back account insert');

-- Several budget accounts: each is set and cleared on its own (2026-11-23).
insert into pg_temp.responses values('budget',pg_temp.call(pg_temp.operation('account.set_budget',
  '21000000-0000-4000-8000-000000000001',null,'1')));
select ok((select is_budget_account from public.accounts where id='21000000-0000-4000-8000-000000000001'),'budget set without data');
select is(pg_temp.call(pg_temp.operation('account.set_budget','21000000-0000-4000-8000-000000000001',null,'2'))#>>'{results,0,revision}',
  '2','setting a budget account again is a no-op');
select throws_ok($$select pg_temp.call(pg_temp.operation('account.set_budget','21000000-0000-4000-8000-000000000005',null,'2'))$$,
  'P0001','revision_conflict','a stale account revision is still refused');
insert into pg_temp.responses values('second',pg_temp.call(pg_temp.operation('account.set_budget',
  '21000000-0000-4000-8000-000000000005','{"previous_budget":null}','1')));
select is((select count(*) from public.accounts where is_budget_account),2::bigint,'a second budget account keeps the first');
select is((select jsonb_array_length(value#>'{results,0,changes}') from pg_temp.responses where name='second'),
  0,'no other account changes');
select throws_ok($$select pg_temp.call(pg_temp.operation('account.set_budget','21000000-0000-4000-8000-000000000005','{"other":1}','2'))$$,
  '22023','invalid_request','unknown budget data denied');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.clear_budget','21000000-0000-4000-8000-000000000001',null,'2'))$$,
  'clear one budget account');
select is((select array_agg(id::text) from public.accounts where is_budget_account),
  array['21000000-0000-4000-8000-000000000005'],'clearing leaves the other');
select is(pg_temp.call(pg_temp.operation('account.clear_budget','21000000-0000-4000-8000-000000000001',null,'3'))#>>'{results,0,revision}',
  '3','clearing a non-budget account is a no-op');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.clear_budget','21000000-0000-4000-8000-000000000005',null,'2'))$$,
  'clear the last budget account');
select is_empty('select id from public.accounts where is_budget_account','clearing leaves none');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.set_budget','21000000-0000-4000-8000-000000000005','{"previous_budget":null}','3'))$$,
  'set again after clear, as app 1.1.0 sends it');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.set_archived','21000000-0000-4000-8000-000000000005','{"archived":true}','4'))$$,
  'archive budget account atomically clears budget');
select is_empty('select id from public.accounts where is_budget_account','archive leaves no budget');
select throws_ok($$select pg_temp.call(pg_temp.operation('account.set_budget','21000000-0000-4000-8000-000000000005','{"previous_budget":null}','5'))$$,
  'P0001','invalid_account','archived asset cannot be budget');
select throws_ok($$select pg_temp.call(pg_temp.operation('account.set_budget','21000000-0000-4000-8000-000000000002','{"previous_budget":null}','1'))$$,
  'P0001','invalid_account','liability cannot be budget');
select throws_ok($$select pg_temp.call(pg_temp.operation('account.set_archived','21000000-0000-4000-8000-000000000001','{"archived":"true"}','3'))$$,
  '22023','invalid_request','archive field must be Boolean');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.set_archived','21000000-0000-4000-8000-000000000005','{"archived":false}','5'))$$,
  'unarchive a former budget account');
select is_empty('select id from public.accounts where is_budget_account','unarchive does not automatically reinstate budget');

-- A later failure undoes both account and generated linked category creation.
select throws_ok($$select public.fundly_apply_operations('62000000-0000-4000-8000-000000000002',
  jsonb_build_object('version',1,'items',jsonb_build_array(
    pg_temp.account('{"name":"Rollback debt","type":"loan"}','22000000-0000-4000-8000-000000000099'),
    '{"operation":"unknown.operation"}'::jsonb)))$$,'P0001','unsupported_operation','account/linked rows share batch rollback');
select is_empty($$select id from public.accounts where id='22000000-0000-4000-8000-000000000099'$$,'account rolled back');
select is_empty($$select id from public.categories where linked_account_id='22000000-0000-4000-8000-000000000099'$$,'linked category rolled back');
select throws_ok('update public.accounts set is_budget_account=true','42501',null,'direct account writes remain denied');
select throws_ok('delete from public.custom_account_types','42501',null,'direct custom type writes remain denied');
reset role;
select is((select count(*) from public.fundly_write_receipts where batch_id='62000000-0000-4000-8000-000000000002'),0::bigint,'no success receipt after rollback');
select * from finish();
rollback;
