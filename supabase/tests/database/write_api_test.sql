begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();
\ir ../fixtures/write_api.inc

create function pg_temp.spend(patch jsonb default '{}', record_id uuid default gen_random_uuid())
returns jsonb language sql as $$
  select jsonb_build_object('operation','transaction.create','id',record_id,'data',
    '{"type":"spending","amount_minor":"100","date":"2026-11-18","payee":"Groceries",
      "source_account_id":"21000000-0000-4000-8000-000000000001",
      "category_id":"31000000-0000-4000-8000-000000000001"}'::jsonb || patch)
$$;
create function pg_temp.envelope(item jsonb)
returns jsonb language sql as $$ select jsonb_build_object('version',1,'items',jsonb_build_array(item)) $$;
create function pg_temp.call(item jsonb, batch uuid default gen_random_uuid())
returns jsonb language sql as $$ select public.fundly_apply_operations(batch,pg_temp.envelope(item)) $$;
create table pg_temp.responses(name text primary key, value jsonb);
grant select, insert on pg_temp.responses to authenticated;

select throws_ok($$select public.fundly_apply_operations(gen_random_uuid(), '{"version":1,"items":[]}')$$,
  '28000', 'authentication_required', 'RPC checks for a user even when called by privileged SQL');
select set_config('request.jwt.claim.sub','a1000000-0000-4000-8000-000000000001',true);
set local role authenticated;

-- Strict envelopes, including JSON null and scalar values.
select throws_ok(format('select public.fundly_apply_operations(gen_random_uuid(), %L::jsonb)', payload),
  '22023','invalid_request',description)
from (values
  ('null','JSON null envelope'), ('[]','array envelope'), ('1','scalar envelope'),
  ('{}','missing version and items'), ('{"version":2,"items":[]}','unsupported version'),
  ('{"version":"1","items":[]}','version must be a number'),
  ('{"version":1.0,"items":[]}','version must use integer representation'),
  ('{"version":1,"items":{}}','items must be an array'),
  ('{"version":1,"items":[]}','empty batch'),
  ('{"version":1,"items":[],"owner_id":"fake"}','unknown envelope field')
) cases(payload,description);
select throws_ok($$select public.fundly_apply_operations(null,pg_temp.envelope(pg_temp.spend()))$$,
  '22023','invalid_request','null batch key');
select throws_ok($$select public.fundly_apply_operations(gen_random_uuid(),
  jsonb_build_object('version',1,'items',(select jsonb_agg(pg_temp.spend()) from generate_series(1,101))))$$,
  '22023','invalid_request','batch operation limit');
select throws_ok($$select pg_temp.call(pg_temp.spend(jsonb_build_object('note',repeat('x',262145))))$$,
  '22023','invalid_request','request byte limit');
select throws_ok(format('select pg_temp.call(%L::jsonb)',item), '22023','invalid_request',description)
from (values
  ('null','null item'), ('[]','array item'), ('{}','missing operation'),
  ('{"operation":42}','non-string operation'),
  ('{"operation":"transaction.create","id":"bad","data":{}}','invalid UUID'),
  ('{"operation":"transaction.create","id":null,"data":{}}','null UUID'),
  ('{"operation":"transaction.create","id":"41000000-0000-4000-8000-000000000001","data":null}','null data'),
  ('{"operation":"transaction.create","id":"41000000-0000-4000-8000-000000000001","data":{}}','missing creation fields')
) cases(item,description);
select throws_ok($$select pg_temp.call(pg_temp.spend() || '{"expected_revision":null}')$$,
  '22023','invalid_request','create cannot specify a revision');
select throws_ok($$select pg_temp.call(pg_temp.spend() || '{"owner_id":"fake"}')$$,
  '22023','invalid_request','owner forbidden at operation level');
select throws_ok($$select pg_temp.call(pg_temp.spend() || '{"operation":"unknown.operation"}')$$,
  'P0001','unsupported_operation','unknown domain operations are not exposed');

select throws_ok(format('select pg_temp.call(pg_temp.spend(%L::jsonb))',patch),state,message,description)
from (values
  ('{"owner_id":"b1000000-0000-4000-8000-000000000001"}','22023','invalid_request','forged data owner'),
  ('{"revision":"1"}','22023','invalid_request','forged data revision'),
  ('{"created_at":"2000-01-01"}','22023','invalid_request','forged audit timestamp'),
  ('{"unknown":true}','22023','invalid_request','unknown data field'),
  ('{"amount_minor":100}','22023','invalid_request','numeric money forbidden'),
  ('{"amount_minor":"0"}','22023','invalid_request','zero amount'),
  ('{"amount_minor":"-1"}','22023','invalid_request','negative amount'),
  ('{"amount_minor":"1.5"}','22023','invalid_request','fractional money forbidden'),
  ('{"amount_minor":"01"}','22023','invalid_request','noncanonical decimal amount'),
  ('{"amount_minor":"9223372036854775808"}','22023','invalid_request','bigint overflow'),
  ('{"amount_minor":null}','22023','invalid_request','null amount'),
  ('{"type":false}','22023','invalid_request','non-string type'),
  ('{"type":"unknown"}','P0001','invalid_transaction','unknown transaction type'),
  ('{"currency_code":"USD"}','P0001','invalid_transaction','unsupported currency'),
  ('{"date":"2026-02-30"}','22023','invalid_request','invalid calendar date'),
  ('{"date":"2026-2-01"}','22023','invalid_request','unpadded date'),
  ('{"date":"infinity"}','22023','invalid_request','infinite date'),
  ('{"date":"10000-01-01"}','22023','invalid_request','unsupported date year'),
  ('{"date":null}','22023','invalid_request','null date'),
  ('{"payee":null}','22023','invalid_request','null free text'),
  ('{"payee":"  "}','P0001','invalid_transaction','blank payee'),
  ('{"source_account_id":null}','P0001','invalid_transaction','spending source required'),
  ('{"category_id":null}','P0001','invalid_transaction','spending category required'),
  ('{"destination_account_id":"21000000-0000-4000-8000-000000000002"}','P0001','invalid_transaction','spending destination forbidden'),
  ('{"source_account_id":"21000000-0000-4000-8000-000000000003"}','P0001','invalid_transaction','loan cannot fund spending'),
  ('{"source_account_id":"21000000-0000-4000-8000-000000000004"}','P0001','invalid_transaction','new spending from archived account'),
  ('{"category_id":"31000000-0000-4000-8000-000000000003"}','P0001','invalid_transaction','new spending in archived category'),
  ('{"category_id":"31000000-0000-4000-8000-000000000002"}','P0001','invalid_transaction','spending with inflow category'),
  ('{"category_id":"31000000-0000-4000-8000-000000000004"}','P0001','invalid_transaction','spending cannot use managed debt category'),
  ('{"source_account_id":"21000000-0000-4000-8000-000000000006"}','P0001','record_not_accessible','cross-owner source'),
  ('{"source_account_id":"ffffffff-0000-4000-8000-000000000001"}','P0001','record_not_accessible','missing source has same error'),
  ('{"category_id":"31000000-0000-4000-8000-000000000005"}','P0001','record_not_accessible','cross-owner category'),
  ('{"source_account_id":"bad"}','22023','invalid_request','malformed reference UUID')
) cases(patch,state,message,description);

select throws_ok($$select pg_temp.call(pg_temp.spend(jsonb_build_object('payee',repeat('😀',31))))$$,
  'P0001','invalid_transaction','payee limit counts UTF-16 code units');
select throws_ok($$select pg_temp.call(pg_temp.spend(jsonb_build_object('note',repeat('😀',251))))$$,
  'P0001','invalid_transaction','note limit counts UTF-16 code units');
select throws_ok($$select pg_temp.call(pg_temp.spend(jsonb_build_object('payee',chr(65279)||chr(160)||chr(9))))$$,
  'P0001','invalid_transaction','Unicode whitespace-only payee rejected');

-- All allowed source/destination type combinations and forbidden alternatives.
select lives_ok(format('select pg_temp.call(pg_temp.spend(%L::jsonb))',patch),description)
from (values
  ('{"source_account_id":"21000000-0000-4000-8000-000000000002"}','credit purchase counts as Spending'),
  ('{"category_id":"31000000-0000-4000-8000-000000000007"}','deleted plan does not disable ordinary category spending'),
  ('{"type":"inflow","source_account_id":null,"destination_account_id":"21000000-0000-4000-8000-000000000001","category_id":null}','cash inflow without category'),
  ('{"type":"inflow","source_account_id":null,"destination_account_id":"21000000-0000-4000-8000-000000000002","category_id":"31000000-0000-4000-8000-000000000002"}','credit refund with inflow category'),
  ('{"type":"transfer","destination_account_id":"21000000-0000-4000-8000-000000000005","category_id":null,"payee":""}','asset transfer without payee'),
  ('{"type":"transfer","destination_account_id":"21000000-0000-4000-8000-000000000003","category_id":null}','loan payment is Transfer'),
  ('{"type":"transfer","source_account_id":"21000000-0000-4000-8000-000000000002","destination_account_id":"21000000-0000-4000-8000-000000000005","category_id":null}','cash advance is a Transfer from credit to an asset'),
  ('{"type":"creditCardPayment","destination_account_id":"21000000-0000-4000-8000-000000000002","category_id":null}','credit payment is movement')
) cases(patch,description);
select throws_ok(format('select pg_temp.call(pg_temp.spend(%L::jsonb))',patch),'P0001',message,description)
from (values
  ('{"type":"inflow","destination_account_id":"21000000-0000-4000-8000-000000000002"}','invalid_transaction','inflow forbids source'),
  ('{"type":"inflow","source_account_id":null,"destination_account_id":"21000000-0000-4000-8000-000000000003","category_id":null}','invalid_transaction','loan cannot receive inflow'),
  ('{"type":"inflow","source_account_id":null,"destination_account_id":"21000000-0000-4000-8000-000000000008","category_id":null}','invalid_transaction','new inflow into archived account'),
  ('{"type":"inflow","source_account_id":null,"destination_account_id":"21000000-0000-4000-8000-000000000002"}','invalid_transaction','inflow forbids spending category'),
  ('{"type":"transfer","destination_account_id":"21000000-0000-4000-8000-000000000001","category_id":null}','invalid_transaction','self transfer forbidden'),
  ('{"type":"transfer","destination_account_id":"21000000-0000-4000-8000-000000000002","category_id":null}','invalid_transaction','Transfer cannot target credit'),
  ('{"type":"transfer","source_account_id":"21000000-0000-4000-8000-000000000002","destination_account_id":"21000000-0000-4000-8000-000000000003","category_id":null}','invalid_transaction','cash advance cannot go to a loan'),
  ('{"type":"transfer","source_account_id":"21000000-0000-4000-8000-000000000003","destination_account_id":"21000000-0000-4000-8000-000000000005","category_id":null}','invalid_transaction','loan cannot source Transfer'),
  ('{"type":"transfer","destination_account_id":"21000000-0000-4000-8000-000000000005"}','invalid_transaction','movements forbid category'),
  ('{"type":"transfer","category_id":null}','invalid_transaction','transfer needs destination'),
  ('{"type":"creditCardPayment","source_account_id":"21000000-0000-4000-8000-000000000003","destination_account_id":"21000000-0000-4000-8000-000000000002","category_id":null}','invalid_transaction','loan cannot source card payment'),
  ('{"type":"creditCardPayment","destination_account_id":"21000000-0000-4000-8000-000000000005","category_id":null}','invalid_transaction','card payment must target credit'),
  ('{"type":"creditCardPayment","destination_account_id":"21000000-0000-4000-8000-000000000007","category_id":null}','record_not_accessible','cross-owner destination')
) cases(patch,message,description);

-- Canonical results, exact large values, year zero and Unicode normalization.
insert into pg_temp.responses values ('created',pg_temp.call(pg_temp.spend(jsonb_build_object(
  'amount_minor','9223372036854775807','date','0000-02-29',
  'payee',chr(65279)||chr(160)||'Groceries'||chr(8199), 'note',E'\t note \n'),
  '41000000-0000-4000-8000-000000000001'), '61000000-0000-4000-8000-000000000001'));
select is((select value#>>'{results,0,record,amount_minor}' from pg_temp.responses where name='created'),
  '9223372036854775807','bigint maximum round trips as decimal string');
select is((select jsonb_typeof(value#>'{results,0,record,revision}') from pg_temp.responses where name='created'),
  'string','revision is a JSON string');
select is((select value#>>'{results,0,record,date}' from pg_temp.responses where name='created'), '0000-02-29','ISO year zero output');
select is((select payee from public.transactions where id='41000000-0000-4000-8000-000000000001'),'Groceries','Dart-compatible payee trim');
select is((select note from public.transactions where id='41000000-0000-4000-8000-000000000001'),'note','Dart-compatible note trim');
select alike((select value#>>'{results,0,record,created_at}' from pg_temp.responses where name='created'),'%Z','audit timestamp uses UTC wire format');
select lives_ok($$select pg_temp.call(pg_temp.spend(jsonb_build_object('payee',repeat('😀',30),'note',repeat('😀',250))))$$,
  'exact UTF-16 limits accepted');

insert into pg_temp.responses values ('updated',pg_temp.call(
  '{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000001","expected_revision":"1","data":{"note":"Updated"}}'));
select is((select amount_minor::text from public.transactions where id='41000000-0000-4000-8000-000000000001'),
  '9223372036854775807','omitted fields are preserved by partial update');
select is((select revision from public.transactions where id='41000000-0000-4000-8000-000000000001'),2::bigint,'edit advances server revision');
select is((select value#>>'{results,0,record,created_at}' from pg_temp.responses where name='updated'),
  (select value#>>'{results,0,record,created_at}' from pg_temp.responses where name='created'),'edit preserves created_at');
select ok((select updated_at >= created_at from public.transactions where id='41000000-0000-4000-8000-000000000001'),'server edit timestamp maintained');
select is(pg_temp.call(pg_temp.spend(jsonb_build_object('amount_minor','9223372036854775807','date','0000-02-29',
  'payee',chr(65279)||chr(160)||'Groceries'||chr(8199),'note',E'\t note \n'),
  '41000000-0000-4000-8000-000000000001'),'61000000-0000-4000-8000-000000000001'),
  (select value from pg_temp.responses where name='created'),'lost-response retry returns original result despite later edit');
select throws_ok($$select pg_temp.call(pg_temp.spend('{}','41000000-0000-4000-8000-000000000001'),
  '61000000-0000-4000-8000-000000000001')$$,'P0001','batch_key_reused','same key with changed payload rejected');
select throws_ok($$select pg_temp.call(pg_temp.spend('{}','41000000-0000-4000-8000-000000000001'))$$,
  'P0001','transaction_id_unavailable','new key does not silently upsert existing transaction');
select throws_ok($$select pg_temp.call(pg_temp.spend('{}','41000000-0000-4000-8000-000000000099'))$$,
  'P0001','transaction_id_unavailable','foreign UUID collision does not reveal owner');

select throws_ok(format('select pg_temp.call(%L::jsonb)',item),state,message,description)
from (values
  ('{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000001","data":{"note":"x"}}','22023','invalid_request','missing revision'),
  ('{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000001","expected_revision":2,"data":{"note":"x"}}','22023','invalid_request','numeric revision forbidden'),
  ('{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000001","expected_revision":"1","data":{"note":"x"}}','P0001','revision_conflict','stale edit'),
  ('{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000001","expected_revision":"2","data":{"type":"inflow"}}','P0001','invalid_transaction','transaction type immutable'),
  ('{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000001","expected_revision":"2","data":{}}','22023','invalid_request','empty edit rejected'),
  ('{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000099","expected_revision":"1","data":{"note":"x"}}','P0001','record_not_accessible','foreign transaction edit'),
  ('{"operation":"transaction.delete","id":"41000000-0000-4000-8000-000000000099","expected_revision":"1"}','P0001','record_not_accessible','foreign transaction delete'),
  ('{"operation":"transaction.delete","id":"ffffffff-0000-4000-8000-000000000001","expected_revision":"1"}','P0001','record_not_accessible','missing transaction delete has same error'),
  ('{"operation":"transaction.delete","id":"41000000-0000-4000-8000-000000000001","expected_revision":"1"}','P0001','revision_conflict','stale delete'),
  ('{"operation":"transaction.delete","id":"41000000-0000-4000-8000-000000000001","expected_revision":"2","data":null}','22023','invalid_request','delete null payload rejected')
) cases(item,state,message,description);

select lives_ok($$select pg_temp.call('{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000090","expected_revision":"1","data":{"note":"History"}}')$$,
  'edit can retain archived source and category');
select lives_ok($$select pg_temp.call('{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000091","expected_revision":"1","data":{"note":"History"}}')$$,
  'edit can retain archived destination and inflow category');
select lives_ok($$select pg_temp.call('{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000092","expected_revision":"1","data":{"note":"History"}}')$$,
  'payment edit can retain both archived accounts');
select throws_ok($$select pg_temp.call('{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000001","expected_revision":"2","data":{"source_account_id":"21000000-0000-4000-8000-000000000004"}}')$$,
  'P0001','invalid_transaction','edit cannot introduce archived source');
select throws_ok($$select pg_temp.call('{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000001","expected_revision":"2","data":{"category_id":"31000000-0000-4000-8000-000000000003"}}')$$,
  'P0001','invalid_transaction','edit cannot introduce archived category');
select throws_ok($$select pg_temp.call('{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000093","expected_revision":"1","data":{"destination_account_id":"21000000-0000-4000-8000-000000000008"}}')$$,
  'P0001','invalid_transaction','edit cannot introduce archived destination');
select lives_ok($$select pg_temp.call('{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000091","expected_revision":"2","data":{"category_id":null}}')$$,
  'explicit null clears optional category');
select ok((select category_id is null from public.transactions where id='41000000-0000-4000-8000-000000000091'),'nullable edit stored');

-- Ordered create/update/delete in one atomic batch and replay after deletion.
insert into pg_temp.responses values ('ordered',public.fundly_apply_operations(
  '61000000-0000-4000-8000-000000000002',jsonb_build_object('version',1,'items',jsonb_build_array(
    pg_temp.spend('{}','41000000-0000-4000-8000-000000000002'),
    '{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000002","expected_revision":"1","data":{"amount_minor":"200"}}'::jsonb,
    '{"operation":"transaction.delete","id":"41000000-0000-4000-8000-000000000002","expected_revision":"2"}'::jsonb))));
select is((select value#>>'{results,2,revision}' from pg_temp.responses where name='ordered'),'2','delete returns prior revision');
select is((select value#>>'{results,2,deleted}' from pg_temp.responses where name='ordered'),'true','delete result explicit');
select is_empty($$select id from public.transactions where id='41000000-0000-4000-8000-000000000002'$$,'ordered batch leaves no deleted record');
select is(public.fundly_apply_operations('61000000-0000-4000-8000-000000000002',jsonb_build_object('version',1,'items',jsonb_build_array(
  pg_temp.spend('{}','41000000-0000-4000-8000-000000000002'),
  '{"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000002","expected_revision":"1","data":{"amount_minor":"200"}}'::jsonb,
  '{"operation":"transaction.delete","id":"41000000-0000-4000-8000-000000000002","expected_revision":"2"}'::jsonb))),
  (select value from pg_temp.responses where name='ordered'),'receipt permits replay even after row deletion');
select throws_ok($$select public.fundly_apply_operations('61000000-0000-4000-8000-000000000003',
  jsonb_build_object('version',1,'items',jsonb_build_array(
    pg_temp.spend('{}','41000000-0000-4000-8000-000000000003'),'{"operation":"invalid"}'::jsonb)))$$,
  'P0001','unsupported_operation','later failure rejects entire batch');
select is_empty($$select id from public.transactions where id='41000000-0000-4000-8000-000000000003'$$,'no partial financial row after rollback');
select throws_ok($$select public.fundly_apply_operations('61000000-0000-4000-8000-000000000010',
  '{"version":1,"items":[
    {"operation":"transaction.update","id":"41000000-0000-4000-8000-000000000001","expected_revision":"2","data":{"note":"Must roll back"}},
    {"operation":"transaction.delete","id":"41000000-0000-4000-8000-000000000090","expected_revision":"2"},
    {"operation":"invalid"}]}')$$,
  'P0001','unsupported_operation','later failure also rolls back earlier edit and delete');
select is((select note from public.transactions where id='41000000-0000-4000-8000-000000000001'),'Updated','edit rolled back');
select is((select revision from public.transactions where id='41000000-0000-4000-8000-000000000090'),2::bigint,'delete rolled back');

select throws_ok('select * from public.fundly_write_receipts','42501',null,'receipt reads denied even to owner');
select throws_ok('delete from public.fundly_write_receipts','42501',null,'receipt deletion denied');
select throws_ok('insert into public.fundly_write_receipts(owner_id,batch_id) values(auth.uid(),gen_random_uuid())',
  '42501',null,'forged receipt insertion denied');
select throws_ok('update public.fundly_write_receipts set result=''{}''','42501',null,'receipt rewrite denied');
select throws_ok('select fundly_private.positive_bigint(''"1"'')','42501',null,'internal helper calls denied');
select throws_ok('update public.transactions set amount_minor=1','42501',null,'direct table writes remain denied');
reset role;
select is((select count(*) from public.fundly_write_receipts where batch_id='61000000-0000-4000-8000-000000000003'),
  0::bigint,'no success receipt after failed batch');
select ok(not has_table_privilege('service_role','public.fundly_write_receipts','SELECT'),'receipt table backend function only');
select ok(not has_schema_privilege('authenticated','fundly_private','USAGE'),'private schema not accessible to client');
select ok(not has_function_privilege('authenticated',p.oid,'EXECUTE'),p.proname || ': private helper not executable')
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='fundly_private';
select is((select amount_minor from public.transactions where id='41000000-0000-4000-8000-000000000099'),100::bigint,'foreign record unchanged');

-- Same idempotency key is independent for another user.
select set_config('request.jwt.claim.sub','b1000000-0000-4000-8000-000000000001',true);
set local role authenticated;
select lives_ok($$select pg_temp.call(pg_temp.spend('{"source_account_id":"21000000-0000-4000-8000-000000000006","category_id":"31000000-0000-4000-8000-000000000005"}',
  '41000000-0000-4000-8000-000000000004'),'61000000-0000-4000-8000-000000000001')$$,
  'batch keys are scoped to the authenticated user');
select is((select count(*) from public.transactions where owner_id='a1000000-0000-4000-8000-000000000001'),0::bigint,'RPC did not weaken read isolation');
reset role;
select is((select count(*) from public.fundly_write_receipts where batch_id='61000000-0000-4000-8000-000000000001'),2::bigint,'two separate owner receipts');
select set_config('request.jwt.claim.sub','',true);
set local role authenticated;
select throws_ok($$select pg_temp.call(pg_temp.spend())$$,'28000','authentication_required','authenticated role still needs a user claim');
reset role;
set local role anon;
select throws_ok($$select public.fundly_apply_operations(gen_random_uuid(),'{"version":1,"items":[]}'::jsonb)$$,
  '42501',null,'anonymous RPC denied by privilege');
select throws_ok('select * from public.fundly_write_receipts','42501',null,'anonymous receipt read denied');
reset role;
select * from finish();
rollback;
