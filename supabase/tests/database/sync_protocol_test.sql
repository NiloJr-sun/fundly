begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select no_plan();
\ir ../fixtures/write_api.inc

create function pg_temp.operation(op text, record_id uuid, data jsonb default null, revision text default null)
returns jsonb language sql as $$
  select jsonb_build_object('operation',op,'id',record_id) ||
    case when data is null then '{}'::jsonb else jsonb_build_object('data',data) end ||
    case when revision is null then '{}'::jsonb else jsonb_build_object('expected_revision',revision) end
$$;
create function pg_temp.calls(items jsonb, batch uuid default gen_random_uuid())
returns jsonb language sql as $$
  select public.fundly_apply_operations(batch,jsonb_build_object('version',1,'items',items))
$$;
create function pg_temp.call(item jsonb, batch uuid default gen_random_uuid())
returns jsonb language sql as $$ select pg_temp.calls(jsonb_build_array(item),batch) $$;
-- Message plus the full JSON detail of a rejected batch.
create function pg_temp.failure(items jsonb) returns jsonb language plpgsql as $$
declare message text; detail text;
begin
  perform pg_temp.calls(items);
  return null;
exception when others then
  get stacked diagnostics message = message_text, detail = pg_exception_detail;
  return jsonb_build_object('message',message,'detail',nullif(detail,'')::jsonb);
end;
$$;
create function pg_temp.fail(item jsonb) returns jsonb language sql as $$
  select pg_temp.failure(jsonb_build_array(item))
$$;
create function pg_temp.spend(record_id uuid, source uuid default '21000000-0000-4000-8000-000000000001',
  category uuid default '31000000-0000-4000-8000-000000000001')
returns jsonb language sql as $$
  select pg_temp.operation('transaction.create',record_id,jsonb_build_object('type','spending',
    'amount_minor','100','date','2026-11-18','payee','Test','source_account_id',source,'category_id',category))
$$;
create function pg_temp.plan(record_id uuid, category uuid, month text, assigned text,
  target jsonb default 'null', previous jsonb default 'null')
returns jsonb language sql as $$
  select pg_temp.operation('plan.save',record_id,jsonb_build_object('category_id',category,'month',month,
    'target_amount_minor',target,'assigned_amount_minor',assigned,'previous',previous))
$$;
-- Expected record_deleted detail for a single-item batch.
create function pg_temp.deleted(item jsonb, entity text, deleted_id uuid) returns jsonb language sql as $$
  select jsonb_build_object('message','record_deleted','detail',jsonb_build_object('entity',entity,
    'deleted_id',deleted_id,'index',0,'operation',item->'operation','id',item->'id'))
$$;
create table pg_temp.responses(name text primary key,value jsonb);
grant select,insert on pg_temp.responses to authenticated;
select set_config('request.jwt.claim.sub','a1000000-0000-4000-8000-000000000001',true);
set local role authenticated;

-- Transactions
select lives_ok($$select pg_temp.calls(jsonb_build_array(
  pg_temp.spend('75000000-0000-4000-8000-000000000001'),
  pg_temp.operation('transaction.delete','75000000-0000-4000-8000-000000000001',null,'1')))$$,
  'create and delete a transaction');
select is(pg_temp.fail(pg_temp.spend('75000000-0000-4000-8000-000000000001')),
  pg_temp.deleted(pg_temp.spend('75000000-0000-4000-8000-000000000001'),'transactions','75000000-0000-4000-8000-000000000001'),
  'deleted transaction UUID cannot be re-created');
select is(pg_temp.fail(pg_temp.operation('transaction.update','75000000-0000-4000-8000-000000000001','{"note":"x"}','1'))#>>'{message}',
  'record_deleted','deleted transaction cannot be edited');
select is(pg_temp.fail(pg_temp.operation('transaction.delete','75000000-0000-4000-8000-000000000001',null,'1'))#>'{detail,entity}',
  '"transactions"','deleted transaction cannot be deleted again');
select throws_ok($$select pg_temp.call(pg_temp.operation('transaction.update','ffffffff-0000-4000-8000-000000000001','{"note":"x"}','1'))$$,
  'P0001','record_not_accessible','never-existing record unchanged');

-- Custom types
select lives_ok($$select pg_temp.calls(jsonb_build_array(
  pg_temp.operation('custom_type.create','71000000-0000-4000-8000-000000000001','{"name":"Wallet","base_type":"savingsCash"}'),
  pg_temp.operation('custom_type.delete','71000000-0000-4000-8000-000000000001',null,'1')))$$,'create and delete a custom type');
select is(pg_temp.fail(pg_temp.operation('custom_type.create','71000000-0000-4000-8000-000000000001',
  '{"name":"Wallet","base_type":"savingsCash"}'))#>>'{message}','record_deleted','deleted custom type UUID retired');
select is((pg_temp.fail(pg_temp.operation('account.create','72000000-0000-4000-8000-000000000009',
  '{"name":"Typed","type":"savingsCash","entered_opening_amount_minor":"0","custom_type_id":"71000000-0000-4000-8000-000000000001"}'))->'detail')
  - array['index','operation','id'],
  '{"entity":"custom_account_types","deleted_id":"71000000-0000-4000-8000-000000000001"}'::jsonb,'reference to deleted custom type');

-- Accounts, including a liability whose linked row survives deletion
select lives_ok($$select pg_temp.calls(jsonb_build_array(
  pg_temp.operation('account.create','72000000-0000-4000-8000-000000000001','{"name":"Gone cash","type":"savingsCash","entered_opening_amount_minor":"0"}'),
  pg_temp.operation('account.set_archived','72000000-0000-4000-8000-000000000001','{"archived":true}','1'),
  pg_temp.operation('account.delete','72000000-0000-4000-8000-000000000001',null,'2'),
  pg_temp.operation('account.create','72000000-0000-4000-8000-000000000002',
    '{"name":"Gone card","type":"credit","entered_opening_amount_minor":"0","linked_category_id":"73000000-0000-4000-8000-000000000009"}'),
  pg_temp.operation('account.set_archived','72000000-0000-4000-8000-000000000002','{"archived":true}','1'),
  pg_temp.operation('account.delete','72000000-0000-4000-8000-000000000002',null,'2')))$$,
  'create, archive and delete accounts');
select is(pg_temp.fail(pg_temp.operation('account.create','72000000-0000-4000-8000-000000000001',
  '{"name":"Again","type":"savingsCash","entered_opening_amount_minor":"0"}'))#>>'{message}','record_deleted','deleted account UUID retired');
select is(pg_temp.fail(pg_temp.operation('account.update','72000000-0000-4000-8000-000000000001','{"name":"x"}','2'))#>>'{message}',
  'record_deleted','deleted account cannot be edited');
select is(pg_temp.fail(pg_temp.spend('75000000-0000-4000-8000-000000000009','72000000-0000-4000-8000-000000000001')),
  pg_temp.deleted(pg_temp.spend('75000000-0000-4000-8000-000000000009','72000000-0000-4000-8000-000000000001'),
    'accounts','72000000-0000-4000-8000-000000000001'),'reference to deleted source account');
select is((select linked_account_id from public.categories where id='73000000-0000-4000-8000-000000000009'),null::uuid,
  'linked row detached, not deleted');

-- Categories cascade their plans
select lives_ok($$select pg_temp.calls(jsonb_build_array(
  pg_temp.operation('category.create','73000000-0000-4000-8000-000000000001','{"name":"Gone category","kind":"spending"}'),
  pg_temp.plan('74000000-0000-4000-8000-000000000001','73000000-0000-4000-8000-000000000001','2026-11','1'),
  pg_temp.plan('74000000-0000-4000-8000-000000000002','73000000-0000-4000-8000-000000000001','2026-12','1'),
  pg_temp.operation('category.delete','73000000-0000-4000-8000-000000000001',null,'1')))$$,'category with plans deleted');
select is(pg_temp.fail(pg_temp.operation('category.create','73000000-0000-4000-8000-000000000001',
  '{"name":"Again","kind":"spending"}'))#>>'{message}','record_deleted','deleted category UUID retired');
select is(pg_temp.fail(pg_temp.operation('category.update','73000000-0000-4000-8000-000000000001','{"name":"x"}','1'))#>>'{message}',
  'record_deleted','deleted category cannot be edited');
select is(pg_temp.fail(pg_temp.operation('plan.set_archived','73000000-0000-4000-8000-000000000001',
  '{"archived":true,"timezone":"UTC"}','1'))#>>'{detail,entity}','categories','deleted category plan cannot be archived');
select is(pg_temp.fail(pg_temp.plan('74000000-0000-4000-8000-000000000009','73000000-0000-4000-8000-000000000001','2027-01','1'))
  #>>'{detail,deleted_id}','73000000-0000-4000-8000-000000000001','plan for a deleted category');
select is(pg_temp.fail(pg_temp.spend('75000000-0000-4000-8000-000000000009',category=>'73000000-0000-4000-8000-000000000001'))
  #>>'{detail,entity}','categories','spending in a deleted category');
select is((pg_temp.fail(pg_temp.plan('74000000-0000-4000-8000-000000000001','31000000-0000-4000-8000-000000000001','2027-01','1'))
  ->'detail') - array['index','operation','id'],
  '{"entity":"monthly_plans","deleted_id":"74000000-0000-4000-8000-000000000001"}'::jsonb,'cascaded plan UUID retired');
select is(pg_temp.fail(pg_temp.operation('account.create','72000000-0000-4000-8000-000000000003',
  '{"name":"Reuse row","type":"credit","entered_opening_amount_minor":"0","linked_category_id":"73000000-0000-4000-8000-000000000001"}'))
  #>>'{detail,entity}','categories','deleted category UUID cannot become a linked row');

-- Plan clear and permanent deletion retire plan UUIDs
select lives_ok($$select pg_temp.calls(jsonb_build_array(
  pg_temp.plan('74000000-0000-4000-8000-000000000003','31000000-0000-4000-8000-000000000001','2026-10','5'),
  pg_temp.plan('74000000-0000-4000-8000-000000000003','31000000-0000-4000-8000-000000000001','2026-10','0','null',
    '{"id":"74000000-0000-4000-8000-000000000003","revision":"1"}'),
  pg_temp.operation('category.create','73000000-0000-4000-8000-000000000002','{"name":"Purge me","kind":"spending"}'),
  pg_temp.plan('74000000-0000-4000-8000-000000000004','73000000-0000-4000-8000-000000000002','2026-01','0','"5"'),
  pg_temp.operation('plan.set_archived','73000000-0000-4000-8000-000000000002','{"archived":true,"timezone":"UTC"}','1'),
  pg_temp.operation('plan.delete_permanently','73000000-0000-4000-8000-000000000002',null,'2')))$$,'clear and purge plans');

reset role;
select is((select array_agg(entity||':'||id order by entity,id) from public.fundly_deleted_records
  where owner_id='a1000000-0000-4000-8000-000000000001'),array[
  'accounts:72000000-0000-4000-8000-000000000001','accounts:72000000-0000-4000-8000-000000000002',
  'categories:73000000-0000-4000-8000-000000000001',
  'custom_account_types:71000000-0000-4000-8000-000000000001',
  'monthly_plans:74000000-0000-4000-8000-000000000001','monthly_plans:74000000-0000-4000-8000-000000000002',
  'monthly_plans:74000000-0000-4000-8000-000000000003','monthly_plans:74000000-0000-4000-8000-000000000004',
  'transactions:75000000-0000-4000-8000-000000000001'],
  'every deletion and cascade recorded; detached and purged-plan categories kept');
select is((select revision from public.fundly_deleted_records where id='72000000-0000-4000-8000-000000000001'),2::bigint,
  'tombstone keeps the deleted revision');
select is((select count(*)::int from public.fundly_deleted_records where id='73000000-0000-4000-8000-000000000002'),0,
  'permanent plan deletion keeps its category');
set local role authenticated;

-- Another owner learns nothing about retired UUIDs
select set_config('request.jwt.claim.sub','b1000000-0000-4000-8000-000000000001',true);
select throws_ok($$select pg_temp.call(pg_temp.spend('75000000-0000-4000-8000-000000000001','21000000-0000-4000-8000-000000000006',
  '31000000-0000-4000-8000-000000000005'))$$,'P0001','record_id_unavailable','other owner cannot reuse a retired UUID');
select throws_ok($$select pg_temp.call(pg_temp.operation('category.update','73000000-0000-4000-8000-000000000001','{"name":"x"}','1'))$$,
  'P0001','record_not_accessible','other owner sees no deletion');
select is(pg_temp.fail(pg_temp.operation('transaction.update','41000000-0000-4000-8000-000000000090','{"note":"x"}','9')),
  '{"message":"record_not_accessible","detail":{"index":0,"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000090"}}'::jsonb,
  'no current revision of another owner''s record');
select set_config('request.jwt.claim.sub','a1000000-0000-4000-8000-000000000001',true);

-- Rejection details
select is(pg_temp.failure(jsonb_build_array(
  pg_temp.operation('category.create','73000000-0000-4000-8000-000000000005','{"name":"First ok","kind":"spending"}'),
  pg_temp.operation('category.create','73000000-0000-4000-8000-000000000006','{"name":"food","kind":"spending"}'))),
  '{"message":"name_taken","detail":{"index":1,"operation":"category.create","id":"73000000-0000-4000-8000-000000000006"}}'::jsonb,
  'failing item position and identity');
select is(pg_temp.failure('["x"]'),'{"message":"invalid_request","detail":{"index":0}}'::jsonb,'unreadable item gives only its position');
select is(pg_temp.fail(pg_temp.operation('category.update','31000000-0000-4000-8000-000000000001','{"name":"x"}','5'))#>>'{detail,current_revision}',
  '1','category revision conflict shows current revision');
select is(pg_temp.fail(pg_temp.operation('transaction.update','41000000-0000-4000-8000-000000000093','{"note":"x"}','2'))#>>'{detail,current_revision}',
  '1','transaction revision conflict shows current revision');
select is(pg_temp.fail(pg_temp.operation('account.update','21000000-0000-4000-8000-000000000001','{"name":"x"}','4'))#>>'{detail,current_revision}',
  '1','account revision conflict shows current revision');
select lives_ok($$select pg_temp.call(pg_temp.plan('74000000-0000-4000-8000-000000000006','31000000-0000-4000-8000-000000000001','2027-01','1'))$$,
  'plan for conflict');
select is(pg_temp.fail(pg_temp.plan('74000000-0000-4000-8000-000000000007','31000000-0000-4000-8000-000000000001','2027-01','2'))#>'{detail,current}',
  '{"id":"74000000-0000-4000-8000-000000000006","revision":"1"}'::jsonb,'plan conflict shows the current record');
select is(pg_temp.fail(pg_temp.plan('74000000-0000-4000-8000-000000000008','31000000-0000-4000-8000-000000000001','2027-02','2','null',
  '{"id":"74000000-0000-4000-8000-000000000008","revision":"1"}'))#>'{detail,current}','null'::jsonb,'plan conflict with no record');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.set_budget','21000000-0000-4000-8000-000000000001',
  '{"previous_budget":null}','1'))$$,'select a budget account');
select lives_ok($$select pg_temp.call(pg_temp.operation('account.set_budget','21000000-0000-4000-8000-000000000005',
  '{"previous_budget":null}','1'))$$,'a second budget account is not a conflict');
select is(pg_temp.fail(pg_temp.operation('plan.delete_permanently','31000000-0000-4000-8000-000000000001',null,'1'))->'detail',
  '{"reason":"not_archived","index":0,"operation":"plan.delete_permanently","id":"31000000-0000-4000-8000-000000000001"}'::jsonb,
  'existing detail merged with item identity');

-- Rollback and replay
select lives_ok($$select pg_temp.call(pg_temp.spend('75000000-0000-4000-8000-000000000003'))$$,'transaction to keep');
select throws_ok($$select pg_temp.calls(jsonb_build_array(
  pg_temp.operation('transaction.delete','75000000-0000-4000-8000-000000000003',null,'1'),
  pg_temp.operation('category.create','73000000-0000-4000-8000-000000000007','{"name":"Food","kind":"spending"}')))$$,
  'P0001','name_taken','later failure rejects the delete');
select is((select count(*)::int from public.transactions where id='75000000-0000-4000-8000-000000000003'),1,'rolled-back delete keeps the row');
select lives_ok($$select pg_temp.call(pg_temp.operation('transaction.update','75000000-0000-4000-8000-000000000003','{"note":"kept"}','1'))$$,
  'rolled-back delete left no tombstone');
select lives_ok($$select pg_temp.call(pg_temp.spend('75000000-0000-4000-8000-000000000002'))$$,'transaction to delete');
insert into pg_temp.responses values('delete',pg_temp.call(pg_temp.operation('transaction.delete',
  '75000000-0000-4000-8000-000000000002',null,'1'),'76000000-0000-4000-8000-000000000001'));
select is(pg_temp.call(pg_temp.operation('transaction.delete','75000000-0000-4000-8000-000000000002',null,'1'),
  '76000000-0000-4000-8000-000000000001'),(select value from pg_temp.responses where name='delete'),
  'replay of a committed delete returns its result');

-- Access: tombstones are backend-only, and privileged deletes are recorded too.
select throws_ok($$select count(*) from public.fundly_deleted_records$$,'42501',null,'clients cannot read tombstones');
select throws_ok($$delete from public.fundly_deleted_records$$,'42501',null,'clients cannot remove tombstones');
select throws_ok($$insert into public.fundly_deleted_records(entity,id,owner_id,revision) values('transactions',gen_random_uuid(),
  'a1000000-0000-4000-8000-000000000001',1)$$,'42501',null,'clients cannot forge tombstones');
select lives_ok($$select pg_temp.call(pg_temp.spend('75000000-0000-4000-8000-000000000004'))$$,'transaction for privileged delete');
reset role;
set local role service_role;
select throws_ok($$select count(*) from public.fundly_deleted_records$$,'42501',null,'service role cannot read tombstones');
delete from public.transactions where id='75000000-0000-4000-8000-000000000004';
reset role;
select is((select entity from public.fundly_deleted_records where id='75000000-0000-4000-8000-000000000004'),'transactions',
  'privileged delete recorded');

select * from finish();
rollback;
