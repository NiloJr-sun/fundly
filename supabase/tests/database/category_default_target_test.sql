-- Default Target per category (20261125010000_category_default_target.sql).
-- category.create and category.update, an update from an older app, the
-- table rule, plan.save keeping an empty plan, and imports. Rolled back.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

insert into auth.users(id, email) values
  ('a2500000-0000-4000-8000-000000000001', 'dt-owner@example.invalid'),
  ('b2500000-0000-4000-8000-000000000001', 'dt-importer@example.invalid');
select fundly_private.ensure_personal_space(id) from auth.users where email like 'dt-%';

-- One batch as `actor`; errors are raised to the caller.
create function pg_temp.write(actor uuid, items jsonb) returns jsonb language plpgsql as $$
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub', actor, 'role', 'authenticated')::text, true);
  return public.fundly_apply_operations(gen_random_uuid(), jsonb_build_object('version', 1, 'items', items));
end;
$$;
create function pg_temp.op(operation text, id text, data jsonb, revision text default null) returns jsonb
language sql as $$
  select jsonb_build_object('operation', operation, 'id', id, 'data', data)
    || case when revision is null then '{}'::jsonb else jsonb_build_object('expected_revision', revision) end
$$;
create function pg_temp.default_target(category uuid) returns bigint language sql as $$
  select c.default_target_minor from public.categories c where c.id = category
$$;
-- 'ok', or the import error and where the server says the problem is.
create function pg_temp.import(actor uuid, categories jsonb) returns text language plpgsql as $$
declare message text; raw text; detail jsonb;
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub', actor, 'role', 'authenticated')::text, true);
  perform public.fundly_import_dataset(gen_random_uuid(), jsonb_build_object('version', 1, 'mode', 'into_empty',
    'dataset', jsonb_build_object('custom_account_types', '[]'::jsonb, 'accounts', '[]'::jsonb,
      'categories', categories, 'transactions', '[]'::jsonb, 'monthly_plans', '[]'::jsonb)));
  return 'ok';
exception when others then
  get stacked diagnostics message = message_text, raw = pg_exception_detail;
  detail := nullif(raw, '')::jsonb;
  return message || coalesce(' ' || (detail->>'table') || '[' || (detail->>'index') || '].'
    || (detail->>'field') || ' ' || (detail->>'rule'), '');
end;
$$;
grant execute on all functions in schema pg_temp to authenticated;
set local role authenticated;

-- category.create ------------------------------------------------------------

select lives_ok($$select pg_temp.write('a2500000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('category.create', '32500000-0000-4000-8000-000000000001',
      '{"name":"House rent","kind":"spending","default_target_minor":"500000"}'),
    pg_temp.op('category.create', '32500000-0000-4000-8000-000000000002',
      '{"name":"Gifts","kind":"spending"}'),
    pg_temp.op('category.create', '32500000-0000-4000-8000-000000000003',
      '{"name":"Pets","kind":"spending","default_target_minor":"0"}'),
    pg_temp.op('category.create', '32500000-0000-4000-8000-000000000004',
      '{"name":"Salary","kind":"inflow"}')))$$,
  'create accepts a default Target, none, or zero');
select is(pg_temp.default_target('32500000-0000-4000-8000-000000000001'), 500000::bigint, 'default Target stored');
select is(pg_temp.default_target('32500000-0000-4000-8000-000000000002'), null::bigint, 'no default Target when not sent');
select is(pg_temp.default_target('32500000-0000-4000-8000-000000000003'), 0::bigint, 'a zero default Target is kept');

select throws_ok(format('select pg_temp.write(%L, jsonb_build_array(pg_temp.op(''category.create'', %L, %L::jsonb)))',
    'a2500000-0000-4000-8000-000000000001', '32500000-0000-4000-8000-000000000009', data),
  state, message, description)
from (values
  ('{"name":"Bonus","kind":"inflow","default_target_minor":"100"}', '22023', 'invalid_request', 'inflow has no default Target'),
  ('{"name":"Bad","kind":"spending","default_target_minor":"-1"}', '22023', 'invalid_request', 'negative default Target refused'),
  ('{"name":"Bad","kind":"spending","default_target_minor":1.5}', '22023', 'invalid_request', 'default Target is whole minor units')
) cases(data, state, message, description);

-- category.update ------------------------------------------------------------

select lives_ok($$select pg_temp.write('a2500000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('category.update', '32500000-0000-4000-8000-000000000002', '{"default_target_minor":"250000"}', '1')))$$,
  'update sets a default Target');
select is(pg_temp.default_target('32500000-0000-4000-8000-000000000002'), 250000::bigint, 'default Target set by update');

select lives_ok($$select pg_temp.write('a2500000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('category.update', '32500000-0000-4000-8000-000000000002', '{"name":"Presents","plan_group":"savings"}', '2')))$$,
  'an older app updates without the field');
select is(pg_temp.default_target('32500000-0000-4000-8000-000000000002'), 250000::bigint,
  'an update without the field keeps the saved default Target');

select lives_ok($$select pg_temp.write('a2500000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('category.update', '32500000-0000-4000-8000-000000000002', '{"default_target_minor":null}', '3')))$$,
  'update removes the default Target with null');
select is(pg_temp.default_target('32500000-0000-4000-8000-000000000002'), null::bigint, 'default Target removed');

-- The table rule backs the API up.
reset role;
select throws_ok($$update public.categories set default_target_minor = -1
    where id = '32500000-0000-4000-8000-000000000001'$$, '23514', null, 'the table refuses a negative default Target');
select throws_ok($$update public.categories set default_target_minor = 1
    where id = '32500000-0000-4000-8000-000000000004'$$, '23514', null,
  'the table refuses a default Target on an inflow category');
set local role authenticated;

-- plan.save ------------------------------------------------------------------

select lives_ok($$select pg_temp.write('a2500000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('plan.save', '52500000-0000-4000-8000-000000000001', jsonb_build_object(
      'category_id', '32500000-0000-4000-8000-000000000001', 'month', '2026-11',
      'target_amount_minor', null, 'assigned_amount_minor', '0', 'previous', null))))$$,
  'with a default Target, an empty plan is accepted');
select is((select count(*) from public.monthly_plans where id = '52500000-0000-4000-8000-000000000001'), 1::bigint,
  'with a default Target, the empty plan is kept');

select lives_ok($$select pg_temp.write('a2500000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('plan.save', '52500000-0000-4000-8000-000000000002', jsonb_build_object(
      'category_id', '32500000-0000-4000-8000-000000000002', 'month', '2026-11',
      'target_amount_minor', null, 'assigned_amount_minor', '100', 'previous', null)),
    pg_temp.op('plan.save', '52500000-0000-4000-8000-000000000002', jsonb_build_object(
      'category_id', '32500000-0000-4000-8000-000000000002', 'month', '2026-11',
      'target_amount_minor', null, 'assigned_amount_minor', '0',
      'previous', jsonb_build_object('id', '52500000-0000-4000-8000-000000000002', 'revision', '1')))))$$,
  'without a default Target, clearing a plan is accepted');
select is((select count(*) from public.monthly_plans where id = '52500000-0000-4000-8000-000000000002'), 0::bigint,
  'without a default Target, the empty plan is still removed');

-- Imports --------------------------------------------------------------------

select is(pg_temp.import('b2500000-0000-4000-8000-000000000001', jsonb_build_array(
    jsonb_build_object('id', '32500000-0000-4000-8000-000000000101', 'name', 'Bonus', 'kind', 'inflow',
      'is_archived', false, 'is_plan_archived', false, 'is_plan_deleted', false, 'plan_group', 'spending',
      'linked_account_id', null, 'default_target_minor', '100'))),
  'invalid_import categories[0].default_target_minor invalid_value', 'an import refuses one on an inflow category');
select is(pg_temp.import('b2500000-0000-4000-8000-000000000001', jsonb_build_array(
    jsonb_build_object('id', '32500000-0000-4000-8000-000000000101', 'name', 'Rent', 'kind', 'spending',
      'is_archived', false, 'is_plan_archived', false, 'is_plan_deleted', false, 'plan_group', 'spending',
      'linked_account_id', null, 'default_target_minor', '-5'))),
  'invalid_import categories[0].default_target_minor invalid_value', 'an import refuses a negative one');
select is(pg_temp.import('b2500000-0000-4000-8000-000000000001', jsonb_build_array(
    jsonb_build_object('id', '32500000-0000-4000-8000-000000000101', 'name', 'Rent', 'kind', 'spending',
      'is_archived', false, 'is_plan_archived', false, 'is_plan_deleted', false, 'plan_group', 'spending',
      'linked_account_id', null, 'default_target_minor', '700000'),
    jsonb_build_object('id', '32500000-0000-4000-8000-000000000102', 'name', 'Salary', 'kind', 'inflow',
      'is_archived', false, 'is_plan_archived', false, 'is_plan_deleted', false, 'plan_group', 'spending',
      'linked_account_id', null))),
  'ok', 'an import accepts a default Target, and categories without the field');
select is(pg_temp.default_target('32500000-0000-4000-8000-000000000101'), 700000::bigint, 'imported default Target');
select is(pg_temp.default_target('32500000-0000-4000-8000-000000000102'), null::bigint, 'imported without one');

select * from finish();
rollback;
