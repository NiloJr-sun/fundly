begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select no_plan();
\ir ../fixtures/write_api.inc

-- S2.2C fixtures for owner A: a budget account, a side account, a credit card
-- with its linked Plans row, and categories in each lifecycle state.
insert into public.accounts(id,owner_id,name,type,opening_balance_minor,is_budget_account) values
  ('23000000-0000-4000-8000-000000000001','a1000000-0000-4000-8000-000000000001','Budget cash','savingsCash',100000,true),
  ('23000000-0000-4000-8000-000000000002','a1000000-0000-4000-8000-000000000001','Side cash','savingsCash',100000,false),
  ('23000000-0000-4000-8000-000000000003','a1000000-0000-4000-8000-000000000001','Debt card','credit',0,false);
insert into public.categories(id,owner_id,name,kind,is_archived,is_plan_archived,plan_group,linked_account_id) values
  ('33000000-0000-4000-8000-000000000001','a1000000-0000-4000-8000-000000000001','Blocked','spending',false,false,'spending',null),
  ('33000000-0000-4000-8000-000000000002','a1000000-0000-4000-8000-000000000001','Debt card','spending',false,false,'liability','23000000-0000-4000-8000-000000000003'),
  ('33000000-0000-4000-8000-000000000003','a1000000-0000-4000-8000-000000000001','Old','spending',true,false,'spending',null),
  ('33000000-0000-4000-8000-000000000004','a1000000-0000-4000-8000-000000000001','Shelved','spending',false,true,'spending',null),
  ('33000000-0000-4000-8000-000000000005','a1000000-0000-4000-8000-000000000001','No budget','spending',false,false,'spending',null),
  ('33000000-0000-4000-8000-000000000006','a1000000-0000-4000-8000-000000000001','Temp','spending',false,false,'spending',null);
insert into public.monthly_plans(id,owner_id,month,category_id,target_amount_minor,assigned_amount_minor) values
  ('53000000-0000-4000-8000-000000000001','a1000000-0000-4000-8000-000000000001','2026-01','33000000-0000-4000-8000-000000000003',null,700),
  ('53000000-0000-4000-8000-000000000002','b1000000-0000-4000-8000-000000000001','2026-01','31000000-0000-4000-8000-000000000005',null,100);

create table pg_temp.months as
  select to_char(now() at time zone 'UTC','YYYY-MM') as cur,
    to_char((now() at time zone 'UTC') - interval '1 month','YYYY-MM') as prev,
    to_char((now() at time zone 'UTC') + interval '1 month','YYYY-MM') as next;
create function pg_temp.month(name text) returns text language sql as $$
  select case name when 'cur' then cur when 'prev' then prev else next end from pg_temp.months
$$;
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
create function pg_temp.first(item jsonb) returns jsonb language sql as $$
  select pg_temp.call(item)#>'{results,0}'
$$;
-- Message plus parsed JSON detail of a rejected item.
create function pg_temp.failure(item jsonb) returns jsonb language plpgsql as $$
declare message text; detail text;
begin
  perform pg_temp.call(item);
  return null;
exception when others then
  get stacked diagnostics message = message_text, detail = pg_exception_detail;
  return jsonb_build_object('message',message,'detail',nullif(detail,'')::jsonb);
end;
$$;
create function pg_temp.revision(record_id uuid) returns text language sql as $$
  select revision::text from public.categories where id=record_id
$$;
create function pg_temp.plan(category uuid, month text, target jsonb, assigned text,
  previous jsonb default 'null', record_id uuid default gen_random_uuid())
returns jsonb language sql as $$
  select pg_temp.operation('plan.save',record_id,jsonb_build_object('category_id',category,'month',month,
    'target_amount_minor',target,'assigned_amount_minor',assigned,'previous',previous))
$$;
create function pg_temp.spend(source uuid, category uuid, month text, amount text)
returns jsonb language sql as $$
  select pg_temp.operation('transaction.create',gen_random_uuid(),jsonb_build_object('type','spending',
    'amount_minor',amount,'date',month||'-01','payee','Test','source_account_id',source,'category_id',category))
$$;
create function pg_temp.pay(source uuid, destination uuid, month text, amount text)
returns jsonb language sql as $$
  select pg_temp.operation('transaction.create',gen_random_uuid(),jsonb_build_object('type','creditCardPayment',
    'amount_minor',amount,'date',month||'-01','source_account_id',source,'destination_account_id',destination))
$$;
create function pg_temp.archive(category uuid, zone text default 'UTC') returns jsonb language sql as $$
  select pg_temp.operation('plan.set_archived',category,jsonb_build_object('archived',true,'timezone',zone),
    pg_temp.revision(category))
$$;
create function pg_temp.purge(category uuid) returns jsonb language sql as $$
  select pg_temp.operation('plan.delete_permanently',category,null,pg_temp.revision(category))
$$;
create table pg_temp.responses(name text primary key,value jsonb);
grant select on pg_temp.months to authenticated;
grant select,insert on pg_temp.responses to authenticated;

-- The archive month comes from the caller's timezone at one instant.
select is(fundly_private.local_month('Asia/Manila','2026-10-31 16:30:00+00'),'2026-11','Manila is already November');
select is(fundly_private.local_month('America/Los_Angeles','2026-10-31 16:30:00+00'),'2026-10','Los Angeles is still October');
select is(fundly_private.local_month('UTC','2026-12-31 23:59:59.999999+00'),'2026-12','UTC end of year');
select is(fundly_private.local_month('Pacific/Kiritimati','2026-12-31 10:00:00+00'),'2027-01','UTC+14 crosses the year first');

select set_config('request.jwt.claim.sub','a1000000-0000-4000-8000-000000000001',true);
set local role authenticated;

-- category.create
select throws_ok(format('select pg_temp.call(pg_temp.operation(''category.create'',%L,%L::jsonb))',record_id,data),
  state,message,description)
from (values
  ('34000000-0000-4000-8000-000000000001','{"name":"  ","kind":"spending"}','P0001','invalid_name','blank category name'),
  ('34000000-0000-4000-8000-000000000001','{"name":"New","kind":"other"}','22023','invalid_request','unknown kind'),
  ('34000000-0000-4000-8000-000000000001','{"name":"New","kind":"spending","plan_group":"x"}','22023','invalid_request','unknown plan group'),
  ('34000000-0000-4000-8000-000000000001','{"name":"New","kind":"inflow","plan_group":"savings"}','22023','invalid_request','inflow keeps default group'),
  ('34000000-0000-4000-8000-000000000001','{"name":"New"}','22023','invalid_request','kind required'),
  ('34000000-0000-4000-8000-000000000001','{"kind":"spending"}','22023','invalid_request','name required'),
  ('34000000-0000-4000-8000-000000000001','{"name":null,"kind":"spending"}','22023','invalid_request','null name'),
  ('34000000-0000-4000-8000-000000000001','{"name":"New","kind":"spending","is_archived":true}','22023','invalid_request','archive needs its own operation'),
  ('34000000-0000-4000-8000-000000000001','{"name":"New","kind":"spending","linked_account_id":"21000000-0000-4000-8000-000000000002"}','22023','invalid_request','managed link cannot be requested'),
  ('34000000-0000-4000-8000-000000000001','{"name":"New","kind":"spending","owner_id":"b1000000-0000-4000-8000-000000000001"}','22023','invalid_request','cannot forge category owner'),
  ('34000000-0000-4000-8000-000000000001','{"name":"fOOD","kind":"spending"}','P0001','name_taken','category names ignore ASCII case'),
  ('34000000-0000-4000-8000-000000000001','{"name":"card PLAN","kind":"inflow"}','P0001','name_taken','names collide with managed rows'),
  ('34000000-0000-4000-8000-000000000001','{"name":"Archived Food","kind":"spending"}','P0001','name_taken','names collide with archived categories'),
  ('31000000-0000-4000-8000-000000000005','{"name":"Unique","kind":"spending"}','P0001','record_id_unavailable','foreign category UUID unavailable')
) cases(record_id,data,state,message,description);
select throws_ok($$select pg_temp.call(pg_temp.operation('category.create','34000000-0000-4000-8000-000000000001',
  jsonb_build_object('name',repeat('😀',21),'kind','spending')))$$,'P0001','invalid_name','category length counts UTF-16');
select throws_ok($$select pg_temp.call(pg_temp.operation('category.create','34000000-0000-4000-8000-000000000001',
  '{"name":"New","kind":"spending"}','1'))$$,'22023','invalid_request','create takes no revision');

insert into pg_temp.responses values('create',pg_temp.first(pg_temp.operation('category.create',
  '34000000-0000-4000-8000-000000000001','{"name":"  Rent  ","kind":"spending","plan_group":"savings"}')));
select is((select value->>'entity' from pg_temp.responses where name='create'),'categories','category result entity');
select is((select value->>'revision' from pg_temp.responses where name='create'),'1','new category revision');
select is((select value#>>'{record,name}' from pg_temp.responses where name='create'),'Rent','category name trimmed');
select is((select value#>>'{record,plan_group}' from pg_temp.responses where name='create'),'savings','requested plan group');
select is((select value#>'{record,linked_account_id}' from pg_temp.responses where name='create'),'null'::jsonb,'ordinary category unlinked');
select is((select value->'changes' from pg_temp.responses where name='create'),'[]'::jsonb,'create has no side effects');
select ok((select value#>>'{record,created_at}' from pg_temp.responses where name='create') ~ 'Z$','audit time in UTC');
select is(pg_temp.first(pg_temp.operation('category.create','34000000-0000-4000-8000-000000000002',
  '{"name":"Gift","kind":"inflow"}'))#>>'{record,plan_group}','spending','inflow defaults to the spending group');
select set_config('request.jwt.claim.sub','b1000000-0000-4000-8000-000000000001',true);
select is(pg_temp.first(pg_temp.operation('category.create','34000000-0000-4000-8000-000000000009',
  '{"name":"Rent","kind":"spending"}'))->>'id','34000000-0000-4000-8000-000000000009',
  'names are unique per owner');
select set_config('request.jwt.claim.sub','a1000000-0000-4000-8000-000000000001',true);

-- category.update
select throws_ok(format('select pg_temp.call(pg_temp.operation(''category.update'',%L,%L::jsonb,%L))',record_id,data,revision),
  state,message,description)
from (values
  ('34000000-0000-4000-8000-000000000001','{"kind":"inflow"}','1','22023','invalid_request','kind is immutable'),
  ('34000000-0000-4000-8000-000000000001','{}','1','22023','invalid_request','update needs a field'),
  ('34000000-0000-4000-8000-000000000001','{"name":"Rent 2"}','2','P0001','revision_conflict','stale category revision'),
  ('34000000-0000-4000-8000-000000000001','{"name":"Salary"}','1','P0001','name_taken','rename collision'),
  ('34000000-0000-4000-8000-000000000002','{"plan_group":"liability"}','1','22023','invalid_request','inflow group cannot change'),
  ('31000000-0000-4000-8000-000000000005','{"name":"Mine"}','1','P0001','record_not_accessible','foreign category'),
  ('34000000-0000-4000-8000-000000000009','{"name":"Mine"}','1','P0001','record_not_accessible','another owner category'),
  ('31000000-0000-4000-8000-000000000004','{"name":"Card row"}','1','P0001','managed_category','linked row rename refused'),
  ('31000000-0000-4000-8000-000000000004','{"plan_group":"savings"}','1','P0001','managed_category','linked row group refused')
) cases(record_id,data,revision,state,message,description);
select throws_ok($$select pg_temp.call(pg_temp.operation('category.update','34000000-0000-4000-8000-000000000001'))$$,
  '22023','invalid_request','update data required');
insert into pg_temp.responses values('update',pg_temp.first(pg_temp.operation('category.update',
  '34000000-0000-4000-8000-000000000001','{"name":" RENT ","plan_group":"liability"}','1')));
select is((select value#>>'{record,name}' from pg_temp.responses where name='update'),'RENT','rename may change only case');
select is((select value#>>'{record,plan_group}' from pg_temp.responses where name='update'),'liability','ordinary row may use liability group');
select is((select value->>'revision' from pg_temp.responses where name='update'),'2','update increments revision');
select is(pg_temp.first(pg_temp.operation('category.update','34000000-0000-4000-8000-000000000001',
  '{"plan_group":"spending"}','2'))#>>'{record,name}','RENT','omitted name is kept');
select is(pg_temp.first(pg_temp.operation('category.update','34000000-0000-4000-8000-000000000002',
  '{"name":"Gifts","plan_group":"spending"}','1'))#>>'{record,name}','Gifts','inflow rename with default group');

-- category.set_archived
select throws_ok($$select pg_temp.call(pg_temp.operation('category.set_archived','34000000-0000-4000-8000-000000000001','{"archived":"yes"}','3'))$$,
  '22023','invalid_request','archive flag must be Boolean');
select throws_ok($$select pg_temp.call(pg_temp.operation('category.set_archived','34000000-0000-4000-8000-000000000001','{}','3'))$$,
  '22023','invalid_request','archive flag required');
select throws_ok($$select pg_temp.call(pg_temp.operation('category.set_archived','31000000-0000-4000-8000-000000000004','{"archived":true}','1'))$$,
  'P0001','managed_category','linked row archive refused');
select is(pg_temp.first(pg_temp.operation('category.set_archived','34000000-0000-4000-8000-000000000001',
  '{"archived":true}','3'))#>>'{record,is_archived}','true','category archived');
select throws_ok($$select pg_temp.call(pg_temp.spend('23000000-0000-4000-8000-000000000001','34000000-0000-4000-8000-000000000001','2026-11','100'))$$,
  'P0001','invalid_transaction','new spending cannot use an archived category');
select is(pg_temp.first(pg_temp.operation('category.set_archived','34000000-0000-4000-8000-000000000001',
  '{"archived":false}','4'))#>>'{record,is_archived}','false','category restored');

-- category.delete
select throws_ok($$select pg_temp.call(pg_temp.operation('category.delete','31000000-0000-4000-8000-000000000003',null,'1'))$$,
  'P0001','category_in_use','used category cannot be deleted');
select throws_ok($$select pg_temp.call(pg_temp.operation('category.delete','31000000-0000-4000-8000-000000000004',null,'1'))$$,
  'P0001','managed_category','linked row delete refused');
select throws_ok($$select pg_temp.call(pg_temp.operation('category.delete','34000000-0000-4000-8000-000000000001','{"force":true}','5'))$$,
  '22023','invalid_request','delete takes no data');
select lives_ok($$select pg_temp.calls(jsonb_build_array(
  pg_temp.plan('34000000-0000-4000-8000-000000000001','2026-12','"100"','0',record_id=>'54000000-0000-4000-8000-000000000002'),
  pg_temp.plan('34000000-0000-4000-8000-000000000001','2026-11',null,'50',record_id=>'54000000-0000-4000-8000-000000000001')))$$,
  'two plans for the category');
insert into pg_temp.responses values('delete',pg_temp.first(pg_temp.operation('category.delete',
  '34000000-0000-4000-8000-000000000001','{}','5')));
select is((select value->>'deleted' from pg_temp.responses where name='delete'),'true','category deleted');
select is((select value->>'revision' from pg_temp.responses where name='delete'),'5','delete returns prior revision');
select is((select value->'changes' from pg_temp.responses where name='delete'),
  '[{"entity":"monthly_plans","id":"54000000-0000-4000-8000-000000000001","revision":"1","deleted":true},
    {"entity":"monthly_plans","id":"54000000-0000-4000-8000-000000000002","revision":"1","deleted":true}]'::jsonb,
  'cascaded plans reported in month order');
select is((select count(*)::int from public.monthly_plans where category_id='34000000-0000-4000-8000-000000000001'),0,'plans removed');
select is((select count(*)::int from public.categories where id='34000000-0000-4000-8000-000000000001'),0,'category removed');

-- plan.save validation
select throws_ok(format('select pg_temp.call(pg_temp.operation(''plan.save'',%L,%L::jsonb))',
  '54000000-0000-4000-8000-000000000010',data),state,message,description)
from (values
  ('{"category_id":"31000000-0000-4000-8000-000000000001","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":"1"}','22023','invalid_request','previous is required'),
  ('{"category_id":"31000000-0000-4000-8000-000000000001","month":"2026-11","assigned_amount_minor":"1","previous":null}','22023','invalid_request','target is required'),
  ('{"category_id":"31000000-0000-4000-8000-000000000001","month":"2026-11","target_amount_minor":"-1","assigned_amount_minor":"1","previous":null}','22023','invalid_request','negative target'),
  ('{"category_id":"31000000-0000-4000-8000-000000000001","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":1,"previous":null}','22023','invalid_request','assigned must be a decimal string'),
  ('{"category_id":"31000000-0000-4000-8000-000000000001","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":null,"previous":null}','22023','invalid_request','assigned cannot be null'),
  ('{"category_id":"31000000-0000-4000-8000-000000000001","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":"9223372036854775808","previous":null}','22023','invalid_request','assigned overflow'),
  ('{"category_id":"31000000-0000-4000-8000-000000000001","month":"2026-13","target_amount_minor":null,"assigned_amount_minor":"1","previous":null}','22023','invalid_request','invalid month'),
  ('{"category_id":"31000000-0000-4000-8000-000000000001","month":"2026-1","target_amount_minor":null,"assigned_amount_minor":"1","previous":null}','22023','invalid_request','month needs two digits'),
  ('{"category_id":"31000000-0000-4000-8000-000000000001","month":"2026-11-01","target_amount_minor":null,"assigned_amount_minor":"1","previous":null}','22023','invalid_request','date is not a month'),
  ('{"category_id":"31000000-0000-4000-8000-000000000001","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":"1","previous":null,"currency_code":"PHP"}','22023','invalid_request','currency not accepted'),
  ('{"category_id":"31000000-0000-4000-8000-000000000001","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":"1","previous":{"id":"54000000-0000-4000-8000-000000000099","revision":"1"}}','22023','invalid_request','previous must name the item'),
  ('{"category_id":"31000000-0000-4000-8000-000000000001","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":"1","previous":{"id":"54000000-0000-4000-8000-000000000010"}}','22023','invalid_request','previous needs a revision'),
  ('{"category_id":"31000000-0000-4000-8000-000000000002","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":"1","previous":null}','P0001','category_not_spending','inflow categories are not planned'),
  ('{"category_id":"31000000-0000-4000-8000-000000000005","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":"1","previous":null}','P0001','record_not_accessible','foreign category'),
  ('{"category_id":"31000000-0000-4000-8000-000000000007","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":"1","previous":null}','P0001','plan_deleted','permanently deleted plan'),
  ('{"category_id":"33000000-0000-4000-8000-000000000004","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":"1","previous":null}','P0001','plan_archived','archived plan is read-only'),
  ('{"category_id":"33000000-0000-4000-8000-000000000003","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":"1","previous":null}','P0001','category_archived','archived category gains no new plan')
) cases(data,state,message,description);
select throws_ok($$select pg_temp.call(pg_temp.plan('31000000-0000-4000-8000-000000000001','2026-11',null,'1')||'{"expected_revision":"1"}')$$,
  '22023','invalid_request','plan revision belongs in previous');
select throws_ok($$select pg_temp.call(pg_temp.plan('31000000-0000-4000-8000-000000000001','2026-01',null,'1',
  record_id=>'53000000-0000-4000-8000-000000000002'))$$,'P0001','record_id_unavailable','foreign plan UUID unavailable');

-- plan.save create, update, clear
insert into pg_temp.responses values('plan',pg_temp.first(pg_temp.plan('31000000-0000-4000-8000-000000000001','2026-11',
  null,'500',record_id=>'54000000-0000-4000-8000-000000000010')));
select is((select value->>'entity' from pg_temp.responses where name='plan'),'monthly_plans','plan result entity');
select is((select value#>'{record,target_amount_minor}' from pg_temp.responses where name='plan'),'null'::jsonb,'no target is null');
select is((select value#>>'{record,assigned_amount_minor}' from pg_temp.responses where name='plan'),'500','assigned as decimal string');
select is((select value#>>'{record,month}' from pg_temp.responses where name='plan'),'2026-11','plan month');
select is((select value#>>'{record,currency_code}' from pg_temp.responses where name='plan'),'PHP','plan currency');
select is((select value->>'revision' from pg_temp.responses where name='plan'),'1','new plan revision');
select throws_ok($$select pg_temp.call(pg_temp.plan('31000000-0000-4000-8000-000000000001','2026-11',null,'600'))$$,
  'P0001','plan_conflict','creating over an unseen plan conflicts');
select throws_ok($$select pg_temp.call(pg_temp.plan('31000000-0000-4000-8000-000000000001','2026-11',null,'600',
  '{"id":"54000000-0000-4000-8000-000000000010","revision":"2"}','54000000-0000-4000-8000-000000000010'))$$,
  'P0001','plan_conflict','stale plan snapshot conflicts');
select throws_ok($$select pg_temp.call(pg_temp.plan('31000000-0000-4000-8000-000000000001','2026-10',null,'600',
  '{"id":"54000000-0000-4000-8000-000000000010","revision":"1"}','54000000-0000-4000-8000-000000000010'))$$,
  'P0001','plan_conflict','snapshot of a missing month conflicts');
select is(pg_temp.first(pg_temp.plan('31000000-0000-4000-8000-000000000001','2026-11','"0"','500',
  '{"id":"54000000-0000-4000-8000-000000000010","revision":"1"}','54000000-0000-4000-8000-000000000010'))#>>'{record,target_amount_minor}',
  '0','zero target differs from no target');
select is(pg_temp.first(pg_temp.plan('31000000-0000-4000-8000-000000000001','2026-11','"0"','0',
  '{"id":"54000000-0000-4000-8000-000000000010","revision":"2"}','54000000-0000-4000-8000-000000000010'))->>'revision',
  '3','zero target with nothing assigned keeps the plan');
insert into pg_temp.responses values('clear',pg_temp.first(pg_temp.plan('31000000-0000-4000-8000-000000000001','2026-11',
  null,'0','{"id":"54000000-0000-4000-8000-000000000010","revision":"3"}','54000000-0000-4000-8000-000000000010')));
select is((select value->>'deleted' from pg_temp.responses where name='clear'),'true','no target and nothing assigned removes the plan');
select is((select value->>'revision' from pg_temp.responses where name='clear'),'3','clear returns prior revision');
select is((select count(*)::int from public.monthly_plans where id='54000000-0000-4000-8000-000000000010'),0,'cleared plan removed');
select is(pg_temp.first(pg_temp.plan('31000000-0000-4000-8000-000000000001','2026-11',null,'0'))->'record',
  'null'::jsonb,'clearing nothing is a no-op');
select throws_ok($$select pg_temp.call(pg_temp.plan('31000000-0000-4000-8000-000000000001','2026-11',null,'0',
  '{"id":"54000000-0000-4000-8000-000000000010","revision":"3"}','54000000-0000-4000-8000-000000000010'))$$,
  'P0001','plan_conflict','clearing an already cleared plan conflicts');
select is(pg_temp.first(pg_temp.plan('33000000-0000-4000-8000-000000000003','2026-01','"10"','700',
  '{"id":"53000000-0000-4000-8000-000000000001","revision":"1"}','53000000-0000-4000-8000-000000000001'))#>>'{record,target_amount_minor}',
  '10','archived category may edit an existing plan');
select is(pg_temp.first(pg_temp.plan('31000000-0000-4000-8000-000000000004','2026-11',null,'9223372036854775807'))#>>'{record,assigned_amount_minor}',
  '9223372036854775807','linked row plan with bigint maximum');
-- plan.set_archived validation
select throws_ok(format('select pg_temp.call(pg_temp.operation(''plan.set_archived'',%L,%L::jsonb,%L))',record_id,data,revision),
  state,message,description)
from (values
  ('33000000-0000-4000-8000-000000000001','{"archived":true}','1','22023','invalid_request','archive requires a timezone'),
  ('33000000-0000-4000-8000-000000000004','{"archived":false,"timezone":"UTC"}','1','22023','invalid_request','unarchive takes no timezone'),
  ('33000000-0000-4000-8000-000000000001','{"archived":true,"timezone":8}','1','22023','invalid_request','timezone must be a string'),
  ('33000000-0000-4000-8000-000000000001','{"archived":true,"timezone":"UTC+8"}','1','P0001','invalid_timezone','POSIX offset rejected'),
  ('33000000-0000-4000-8000-000000000001','{"archived":true,"timezone":"asia/manila"}','1','P0001','invalid_timezone','zone names are exact'),
  ('33000000-0000-4000-8000-000000000001','{"archived":true,"timezone":""}','1','P0001','invalid_timezone','empty timezone'),
  ('33000000-0000-4000-8000-000000000001','{"archived":"true","timezone":"UTC"}','1','22023','invalid_request','archive flag must be Boolean'),
  ('33000000-0000-4000-8000-000000000001','{"archived":true,"timezone":"UTC","month":"2026-11"}','1','22023','invalid_request','supplied month not trusted'),
  ('33000000-0000-4000-8000-000000000001','{"archived":true,"timezone":"UTC"}','2','P0001','revision_conflict','stale category revision'),
  ('31000000-0000-4000-8000-000000000002','{"archived":true,"timezone":"UTC"}','1','P0001','category_not_spending','inflow has no plan'),
  ('31000000-0000-4000-8000-000000000007','{"archived":false}','1','P0001','plan_deleted','deleted plan cannot be unarchived'),
  ('31000000-0000-4000-8000-000000000005','{"archived":true,"timezone":"UTC"}','1','P0001','record_not_accessible','foreign category')
) cases(record_id,data,revision,state,message,description);

-- Archive guard: remaining current/future allocations block; the past does not.
select lives_ok(format($$select pg_temp.calls(jsonb_build_array(
  pg_temp.plan('33000000-0000-4000-8000-000000000001',%L,null,'999'),
  pg_temp.plan('33000000-0000-4000-8000-000000000001',%L,null,'500'),
  pg_temp.plan('33000000-0000-4000-8000-000000000001',%L,null,'100'),
  pg_temp.spend('23000000-0000-4000-8000-000000000001','33000000-0000-4000-8000-000000000001',%L,'200'),
  pg_temp.spend('23000000-0000-4000-8000-000000000002','33000000-0000-4000-8000-000000000001',%L,'1000')))$$,
  pg_temp.month('prev'),pg_temp.month('cur'),pg_temp.month('next'),pg_temp.month('cur'),pg_temp.month('cur')),
  'plans and spending for the archive guard');
select is(pg_temp.failure(pg_temp.archive('33000000-0000-4000-8000-000000000001')),
  jsonb_build_object('message','plan_allocation_remaining','detail',jsonb_build_object('months',jsonb_build_array(
    jsonb_build_object('month',pg_temp.month('cur'),'remaining_minor','300'),
    jsonb_build_object('month',pg_temp.month('next'),'remaining_minor','100')))),
  'blocking months exclude the past and non-budget spending');
select is((select is_plan_archived from public.categories where id='33000000-0000-4000-8000-000000000001'),false,'blocked archive changes nothing');
select lives_ok(format($$select pg_temp.calls(jsonb_build_array(
  pg_temp.spend('23000000-0000-4000-8000-000000000001','33000000-0000-4000-8000-000000000001',%L,'400'),
  pg_temp.plan('33000000-0000-4000-8000-000000000001',%L,'"100"','0',
    jsonb_build_object('id',(select id from public.monthly_plans where category_id='33000000-0000-4000-8000-000000000001' and month=%L),'revision','1'),
    (select id from public.monthly_plans where category_id='33000000-0000-4000-8000-000000000001' and month=%L))))$$,
  pg_temp.month('cur'),pg_temp.month('next'),pg_temp.month('next'),pg_temp.month('next')),
  'overspend this month and keep only a Target next month');
insert into pg_temp.responses values('archive',pg_temp.first(pg_temp.archive('33000000-0000-4000-8000-000000000001')));
select is((select value#>>'{record,is_plan_archived}' from pg_temp.responses where name='archive'),'true','overspent and target-only months allow archive');
select is((select value#>>'{record,is_archived}' from pg_temp.responses where name='archive'),'false','plan archive leaves the category active');
select is((select value->>'revision' from pg_temp.responses where name='archive'),'2','archive increments revision');
select is((select assigned_amount_minor from public.monthly_plans where category_id='33000000-0000-4000-8000-000000000001'
  and month=pg_temp.month('prev')),999::bigint,'past assignment kept');
select is(pg_temp.first(pg_temp.archive('33000000-0000-4000-8000-000000000001'))->>'revision','2','archiving again is a no-op');
select throws_ok($$select pg_temp.call(pg_temp.plan('33000000-0000-4000-8000-000000000001','2027-06',null,'1'))$$,
  'P0001','plan_archived','archived row cannot gain plans');
select lives_ok($$select pg_temp.call(pg_temp.spend('23000000-0000-4000-8000-000000000001',
  '33000000-0000-4000-8000-000000000001','2026-11','1'))$$,'spending in a plan-archived category still allowed');

-- Linked rows count payments into their account from the budget account.
select lives_ok(format($$select pg_temp.call(pg_temp.plan('33000000-0000-4000-8000-000000000002',%L,null,'400'))$$,
  pg_temp.month('cur')),'debt row plan');
select lives_ok(format($$select pg_temp.calls(jsonb_build_array(
  pg_temp.pay('23000000-0000-4000-8000-000000000001','23000000-0000-4000-8000-000000000003',%L,'150'),
  pg_temp.pay('23000000-0000-4000-8000-000000000002','23000000-0000-4000-8000-000000000003',%L,'250')))$$,
  pg_temp.month('cur'),pg_temp.month('cur')),'budget and side payments');
select is(pg_temp.failure(pg_temp.archive('33000000-0000-4000-8000-000000000002'))#>'{detail,months,0,remaining_minor}',
  '"250"'::jsonb,'only budget payments release a debt allocation');
select lives_ok(format($$select pg_temp.call(pg_temp.pay('23000000-0000-4000-8000-000000000001',
  '23000000-0000-4000-8000-000000000003',%L,'250'))$$,pg_temp.month('cur')),'pay the rest from budget');
select is(pg_temp.first(pg_temp.archive('33000000-0000-4000-8000-000000000002'))#>>'{record,is_plan_archived}','true',
  'fully paid debt row archives');

-- The caller's timezone decides which month is current (UTC+14 here).
create function pg_temp.zone_month() returns text language sql as $$
  select to_char(now() at time zone 'Pacific/Kiritimati','YYYY-MM')
$$;
select lives_ok($$select pg_temp.call(pg_temp.plan('33000000-0000-4000-8000-000000000005',
  pg_temp.zone_month(),null,'50'))$$,'plan in the Kiritimati month');
select is(pg_temp.failure(pg_temp.archive('33000000-0000-4000-8000-000000000005','Pacific/Kiritimati'))#>>'{detail,months,0,month}',
  pg_temp.zone_month(),'guard uses the requested timezone month');

-- Budget spending releases the allocation; without a budget account nothing is released.
select lives_ok($$select pg_temp.call(pg_temp.spend('23000000-0000-4000-8000-000000000001',
  '33000000-0000-4000-8000-000000000005',pg_temp.zone_month(),'50'))$$,'spend the allocation from budget');
reset role;
update public.accounts set is_budget_account=false where id='23000000-0000-4000-8000-000000000001';
set local role authenticated;
select is(pg_temp.failure(pg_temp.archive('33000000-0000-4000-8000-000000000005','Pacific/Kiritimati'))#>>'{detail,months,0,remaining_minor}',
  '50','no budget account keeps the full allocation');
reset role;
update public.accounts set is_budget_account=true where id='23000000-0000-4000-8000-000000000001';
set local role authenticated;
select is(pg_temp.first(pg_temp.archive('33000000-0000-4000-8000-000000000005','Pacific/Kiritimati'))#>>'{record,is_plan_archived}',
  'true','budget spending released the allocation');

-- Unarchive
select is(pg_temp.first(pg_temp.archive('33000000-0000-4000-8000-000000000003'))#>>'{record,is_plan_archived}','true',
  'archived category plan with only past assignments archives');
select throws_ok($$select pg_temp.call(pg_temp.operation('plan.set_archived','33000000-0000-4000-8000-000000000003',
  '{"archived":false}',pg_temp.revision('33000000-0000-4000-8000-000000000003')))$$,
  'P0001','category_archived','restore the category before the plan');
select is(pg_temp.first(pg_temp.operation('plan.set_archived','33000000-0000-4000-8000-000000000004',
  '{"archived":false}','1'))#>>'{record,is_plan_archived}','false','plan unarchived');
select is(pg_temp.first(pg_temp.operation('plan.set_archived','33000000-0000-4000-8000-000000000004',
  '{"archived":false}','2'))->>'revision','2','unarchiving an active plan is a no-op');

-- Permanent deletion
select is(pg_temp.failure(pg_temp.purge('33000000-0000-4000-8000-000000000006')),
  '{"message":"plan_delete_blocked","detail":{"reason":"not_archived"}}'::jsonb,'active plan cannot be deleted');
select is(pg_temp.failure(pg_temp.purge('31000000-0000-4000-8000-000000000002'))#>>'{detail,reason}',
  'category_not_spending','inflow has no plan to delete');
select is(pg_temp.failure(pg_temp.purge('31000000-0000-4000-8000-000000000007'))#>>'{detail,reason}',
  'already_deleted','already deleted');
select is(pg_temp.failure(pg_temp.purge('33000000-0000-4000-8000-000000000003'))#>>'{detail,reason}',
  'has_assigned_money','any month with Assigned blocks deletion');
select is(pg_temp.failure(pg_temp.purge('33000000-0000-4000-8000-000000000001'))#>>'{detail,reason}',
  'has_assigned_money','past Assigned blocks deletion');
select throws_ok($$select pg_temp.call(pg_temp.operation('plan.delete_permanently','33000000-0000-4000-8000-000000000006','{"force":true}',
  pg_temp.revision('33000000-0000-4000-8000-000000000006')))$$,'22023','invalid_request','delete takes no data');
select lives_ok($$select pg_temp.calls(jsonb_build_array(
  pg_temp.plan('33000000-0000-4000-8000-000000000006','2026-02','"5"','0'),
  pg_temp.plan('33000000-0000-4000-8000-000000000006','2026-01','"5"','0')))$$,'target-only plans');
select lives_ok($$select pg_temp.call(pg_temp.archive('33000000-0000-4000-8000-000000000006'))$$,'archive the plan');
insert into pg_temp.responses values('purge',pg_temp.first(pg_temp.purge('33000000-0000-4000-8000-000000000006')));
select is((select jsonb_array_length(value->'changes') from pg_temp.responses where name='purge'),2,'every month deleted');
select is((select value#>>'{record,is_plan_deleted}' from pg_temp.responses where name='purge'),'true','plan marked deleted');
select is((select value#>>'{record,is_plan_archived}' from pg_temp.responses where name='purge'),'true','deleted plan stays archived');
select is((select count(*)::int from public.monthly_plans where category_id='33000000-0000-4000-8000-000000000006'),0,'monthly records removed');
select is((select count(*)::int from public.categories where id='33000000-0000-4000-8000-000000000006'),1,'category kept');
select throws_ok($$select pg_temp.call(pg_temp.plan('33000000-0000-4000-8000-000000000006','2026-03',null,'1'))$$,
  'P0001','plan_deleted','deleted plan cannot be saved');
select throws_ok($$select pg_temp.call(pg_temp.operation('plan.set_archived','33000000-0000-4000-8000-000000000006',
  '{"archived":false}',pg_temp.revision('33000000-0000-4000-8000-000000000006')))$$,'P0001','plan_deleted','deleted plan cannot be unarchived');
select lives_ok($$select pg_temp.call(pg_temp.spend('23000000-0000-4000-8000-000000000001',
  '33000000-0000-4000-8000-000000000006','2026-11','1'))$$,'category spending still allowed after plan deletion');

-- Activity blocks deletion: category spending, or payments into a linked account.
select is(pg_temp.failure(pg_temp.purge('31000000-0000-4000-8000-000000000003'))#>>'{detail,reason}',
  'has_activity','archived category with spending history');
reset role;
update public.monthly_plans set assigned_amount_minor=0 where category_id='33000000-0000-4000-8000-000000000002';
set local role authenticated;
select is(pg_temp.failure(pg_temp.purge('33000000-0000-4000-8000-000000000002'))#>>'{detail,reason}',
  'has_activity','debt row with payments');

-- An unused debt row: deletion survives account edits and unarchive.
select lives_ok($$select pg_temp.call(pg_temp.operation('account.create','24000000-0000-4000-8000-000000000001',
  '{"name":"Spare loan","type":"loan","entered_opening_amount_minor":"0","linked_category_id":"34000000-0000-4000-8000-000000000020"}'))$$,
  'loan with linked row');
select lives_ok($$select pg_temp.call(pg_temp.operation('plan.set_archived','34000000-0000-4000-8000-000000000020',
  '{"archived":true,"timezone":"Asia/Manila"}','1'))$$,'archive debt row');
select is(pg_temp.first(pg_temp.purge('34000000-0000-4000-8000-000000000020'))#>>'{record,is_plan_deleted}','true','unused debt row deleted');
select lives_ok($$select pg_temp.calls(jsonb_build_array(
  pg_temp.operation('account.update','24000000-0000-4000-8000-000000000001','{"name":"Spare loan 2"}','1'),
  pg_temp.operation('account.set_archived','24000000-0000-4000-8000-000000000001','{"archived":true}','2'),
  pg_temp.operation('account.set_archived','24000000-0000-4000-8000-000000000001','{"archived":false}','3')))$$,
  'rename, archive and unarchive the account');
select is((select (name,is_plan_deleted,is_plan_archived)::text from public.categories
  where id='34000000-0000-4000-8000-000000000020'),'("Spare loan 2",t,t)','account sync never revives a deleted plan');

-- Batches are atomic and retries replay.
select throws_ok($$select pg_temp.calls(jsonb_build_array(
  pg_temp.operation('category.create','34000000-0000-4000-8000-000000000030','{"name":"Rollback","kind":"spending"}'),
  pg_temp.plan('34000000-0000-4000-8000-000000000030','2026-11',null,'1'),
  pg_temp.plan('31000000-0000-4000-8000-000000000002','2026-11',null,'1')))$$,
  'P0001','category_not_spending','later failure rejects the batch');
select is((select count(*)::int from public.categories where id='34000000-0000-4000-8000-000000000030'),0,'earlier category rolled back');
select is((select count(*)::int from public.monthly_plans where category_id='34000000-0000-4000-8000-000000000030'),0,'earlier plan rolled back');
insert into pg_temp.responses values('retry',pg_temp.call(pg_temp.archive('33000000-0000-4000-8000-000000000004','Asia/Manila'),
  '64000000-0000-4000-8000-000000000001'));
select lives_ok($$select pg_temp.call(pg_temp.operation('plan.set_archived','33000000-0000-4000-8000-000000000004',
  '{"archived":false}','3'))$$,'state changes after the archive');
select is(public.fundly_apply_operations('64000000-0000-4000-8000-000000000001',jsonb_build_object('version',1,
  'items',jsonb_build_array(pg_temp.operation('plan.set_archived','33000000-0000-4000-8000-000000000004',
  '{"archived":true,"timezone":"Asia/Manila"}','2')))),(select value from pg_temp.responses where name='retry'),
  'same-key retry returns the original archive result');
select throws_ok($$select public.fundly_apply_operations('64000000-0000-4000-8000-000000000001',jsonb_build_object('version',1,
  'items',jsonb_build_array(pg_temp.operation('plan.set_archived','33000000-0000-4000-8000-000000000004',
  '{"archived":true,"timezone":"UTC"}','2'))))$$,'P0001','batch_key_reused','timezone is part of the fingerprint');

-- Clients still cannot write these tables directly.
select throws_ok($$insert into public.categories(id,owner_id,name,kind) values(gen_random_uuid(),
  'a1000000-0000-4000-8000-000000000001','Direct','spending')$$,'42501',null,'direct category write denied');
select throws_ok($$update public.monthly_plans set assigned_amount_minor=1$$,'42501',null,'direct plan write denied');
select throws_ok($$select fundly_private.remaining_allocations('a1000000-0000-4000-8000-000000000001',
  '33000000-0000-4000-8000-000000000001',null,'2026-01')$$,'42501',null,'private helpers not executable');

select * from finish();
rollback;
