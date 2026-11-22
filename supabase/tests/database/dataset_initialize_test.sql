begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select no_plan();

insert into auth.users(id,email) values
  ('a5300000-0000-4000-8000-000000000001','init-a@example.invalid'),
  ('b5300000-0000-4000-8000-000000000001','init-b@example.invalid');
-- User B already has a category, so initializing changes nothing for B.
insert into public.categories(id,owner_id,name,kind) values
  ('35300000-0000-4000-8000-000000000001','b5300000-0000-4000-8000-000000000001','Mine','spending');

create function pg_temp.init(batch uuid default gen_random_uuid(), data jsonb default null)
returns jsonb language sql as $$
  select public.fundly_apply_operations(batch, jsonb_build_object('version',1,'items',jsonb_build_array(
    jsonb_build_object('operation','dataset.initialize','id','65300000-0000-4000-8000-000000000001') ||
    case when data is null then '{}'::jsonb else jsonb_build_object('data',data) end)))
$$;

select set_config('request.jwt.claim.sub','a5300000-0000-4000-8000-000000000001',true);
set local role authenticated;

select is((pg_temp.init('75300000-0000-4000-8000-000000000001')->'results'->0->>'initialized'),'true',
  'a dataset without categories is initialized');
reset role;
select results_eq(
  $$select name, kind, plan_group, is_archived, linked_account_id is null, revision
    from public.categories where owner_id='a5300000-0000-4000-8000-000000000001'
    order by created_at, id$$,
  $$values ('Rent','spending','spending',false,true,1::bigint), ('Utilities','spending','spending',false,true,1),
    ('Internet','spending','spending',false,true,1), ('Subscriptions','spending','spending',false,true,1),
    ('Food & Groceries','spending','spending',false,true,1), ('Fuel','spending','spending',false,true,1),
    ('Miscellaneous','spending','spending',false,true,1), ('Salary','inflow','spending',false,true,1),
    ('Other income','inflow','spending',false,true,1)$$,
  'the nine defaults, in the app''s order');
select is((select count(distinct created_at)::int from public.categories
  where owner_id='a5300000-0000-4000-8000-000000000001'),9,'each default has its own creation time');
set local role authenticated;

select is(jsonb_array_length(pg_temp.init('75300000-0000-4000-8000-000000000001')->'results'->0->'changes'),9,
  'a retry with the same batch returns the original result');
select is((pg_temp.init()->'results'->0),
  '{"operation":"dataset.initialize","initialized":false,"changes":[]}'::jsonb,
  'a second initialization is a no-op');
select is((pg_temp.init(data => '{}'::jsonb)->'results'->0->>'initialized'),'false','empty data is accepted');
select throws_ok($$select pg_temp.init(data => '{"x":1}'::jsonb)$$,'22023','invalid_request','data must be empty');
select throws_ok($$select public.fundly_apply_operations(gen_random_uuid(),'{"version":1,"items":[
  {"operation":"dataset.initialize","id":"not-a-uuid"}]}'::jsonb)$$,'22023','invalid_request','id must be a UUID');
select throws_ok($$select public.fundly_apply_operations(gen_random_uuid(),'{"version":1,"items":[
  {"operation":"dataset.initialize","id":"65300000-0000-4000-8000-000000000001","expected_revision":"1"}]}'::jsonb)$$,
  '22023','invalid_request','no expected revision');

select set_config('request.jwt.claim.sub','b5300000-0000-4000-8000-000000000001',true);
select is((pg_temp.init()->'results'->0->>'initialized'),'false','an existing category blocks the defaults');
reset role;
select is((select count(*)::int from public.categories where owner_id='b5300000-0000-4000-8000-000000000001'),1,
  'the other owner keeps only their own category');

-- Deleting every category and initializing again restores the defaults
-- (the app only asks after a device's first complete download).
delete from public.categories where owner_id='b5300000-0000-4000-8000-000000000001';
set local role authenticated;
select is((pg_temp.init()->'results'->0->>'initialized'),'true','an emptied dataset is initialized again');

select * from finish();
rollback;
