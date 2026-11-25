-- Default Target on debt rows (20261127020000_debt_row_target.sql): a Credit
-- or Loan account's Plans row takes a default Target through category.update
-- with exactly that field; every other change is still managed_category; the
-- table allows it; an import accepts it. Rolled back.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

insert into auth.users(id, email) values
  ('a2700000-0000-4000-8000-000000000001', 'drt-owner@example.invalid'),
  ('b2700000-0000-4000-8000-000000000001', 'drt-importer@example.invalid');
select fundly_private.ensure_personal_space(id) from auth.users where email like 'drt-%';

-- One batch as `actor`: 'ok' or the error message.
create function pg_temp.try(actor uuid, items jsonb) returns text language plpgsql as $$
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub', actor, 'role', 'authenticated')::text, true);
  perform public.fundly_apply_operations(gen_random_uuid(), jsonb_build_object('version', 1, 'items', items));
  return 'ok';
exception when others then
  return sqlerrm;
end;
$$;
create function pg_temp.op(operation text, id text, data jsonb, revision text default null) returns jsonb
language sql as $$
  select jsonb_build_object('operation', operation, 'id', id, 'data', data)
    || case when revision is null then '{}'::jsonb else jsonb_build_object('expected_revision', revision) end
$$;
-- The Plans row linked to `account`.
create function pg_temp.row_of(account uuid) returns public.categories language sql as $$
  select c from public.categories c where c.linked_account_id = account
$$;
create function pg_temp.import(actor uuid, dataset jsonb) returns text language plpgsql as $$
declare message text; raw text; detail jsonb;
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub', actor, 'role', 'authenticated')::text, true);
  perform public.fundly_import_dataset(gen_random_uuid(), jsonb_build_object('version', 1, 'mode', 'into_empty',
    'dataset', jsonb_build_object('custom_account_types', '[]'::jsonb, 'transactions', '[]'::jsonb,
      'monthly_plans', '[]'::jsonb) || dataset));
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

select is(pg_temp.try('a2700000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('account.create', '22700000-0000-4000-8000-000000000001',
      '{"name":"Metrobank Rewards","type":"credit","entered_opening_amount_minor":"0"}'))),
  'ok', 'a credit account gets its Plans row');

-- The write API -------------------------------------------------------------

select is(pg_temp.try('a2700000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('category.update', (pg_temp.row_of('22700000-0000-4000-8000-000000000001')).id::text,
      '{"default_target_minor":"260750"}',
      (pg_temp.row_of('22700000-0000-4000-8000-000000000001')).revision::text))),
  'ok', 'a debt row takes a default Target');
select is((pg_temp.row_of('22700000-0000-4000-8000-000000000001')).default_target_minor, 260750::bigint,
  'the default Target is stored');
select is((pg_temp.row_of('22700000-0000-4000-8000-000000000001')).name, 'Metrobank Rewards',
  'its name is unchanged');
select is((pg_temp.row_of('22700000-0000-4000-8000-000000000001')).plan_group, 'liability',
  'its group is unchanged');

select is(pg_temp.try('a2700000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('category.update', (pg_temp.row_of('22700000-0000-4000-8000-000000000001')).id::text,
      '{"default_target_minor":null}',
      (pg_temp.row_of('22700000-0000-4000-8000-000000000001')).revision::text))),
  'ok', 'a debt row''s default Target can be removed');
select is((pg_temp.row_of('22700000-0000-4000-8000-000000000001')).default_target_minor, null::bigint,
  'the default Target is removed');

select is(pg_temp.try('a2700000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('category.update', (pg_temp.row_of('22700000-0000-4000-8000-000000000001')).id::text,
      payload, (pg_temp.row_of('22700000-0000-4000-8000-000000000001')).revision::text))),
  'managed_category', description)
from (values
  ('{"default_target_minor":"100","name":"Card"}'::jsonb, 'a Target with a rename is refused'),
  ('{"default_target_minor":"100","plan_group":"savings"}'::jsonb, 'a Target with a group change is refused'),
  ('{"name":"Card"}'::jsonb, 'a rename alone is still refused'),
  ('{}'::jsonb, 'an empty update is refused')) cases(payload, description);

select is(pg_temp.try('a2700000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('category.update', (pg_temp.row_of('22700000-0000-4000-8000-000000000001')).id::text,
      '{"default_target_minor":"-1"}',
      (pg_temp.row_of('22700000-0000-4000-8000-000000000001')).revision::text))),
  'invalid_request', 'a negative default Target is refused');
select is(pg_temp.try('a2700000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('category.set_archived', (pg_temp.row_of('22700000-0000-4000-8000-000000000001')).id::text,
      '{"archived":true}',
      (pg_temp.row_of('22700000-0000-4000-8000-000000000001')).revision::text))),
  'managed_category', 'archiving a debt row is still refused');
select is(pg_temp.try('a2700000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('category.update', (pg_temp.row_of('22700000-0000-4000-8000-000000000001')).id::text,
      '{"default_target_minor":"100"}', '999'))),
  'revision_conflict', 'a stale revision is refused');

-- Renaming the account keeps the default Target.
select is(pg_temp.try('a2700000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('category.update', (pg_temp.row_of('22700000-0000-4000-8000-000000000001')).id::text,
      '{"default_target_minor":"500"}',
      (pg_temp.row_of('22700000-0000-4000-8000-000000000001')).revision::text),
    pg_temp.op('account.update', '22700000-0000-4000-8000-000000000001',
      '{"name":"Metrobank Card"}', '1'))),
  'ok', 'set a Target, then rename the account');
select is((pg_temp.row_of('22700000-0000-4000-8000-000000000001')).name, 'Metrobank Card',
  'the row follows the account name');
select is((pg_temp.row_of('22700000-0000-4000-8000-000000000001')).default_target_minor, 500::bigint,
  'and keeps its default Target');

-- Imports --------------------------------------------------------------------

select is(pg_temp.import('b2700000-0000-4000-8000-000000000001', jsonb_build_object(
    'accounts', jsonb_build_array(jsonb_build_object('id', '22700000-0000-4000-8000-000000000101',
      'name', 'Card', 'type', 'credit', 'opening_balance_minor', '0', 'currency_code', 'PHP',
      'is_archived', false, 'custom_type_id', null, 'is_budget_account', false)),
    'categories', jsonb_build_array(jsonb_build_object('id', '32700000-0000-4000-8000-000000000101',
      'name', 'Card', 'kind', 'spending', 'is_archived', false, 'is_plan_archived', false,
      'is_plan_deleted', false, 'plan_group', 'liability',
      'linked_account_id', '22700000-0000-4000-8000-000000000101', 'default_target_minor', '300000')))),
  'ok', 'an import accepts a default Target on a debt row');
select is((pg_temp.row_of('22700000-0000-4000-8000-000000000101')).default_target_minor, 300000::bigint,
  'imported default Target on the debt row');

select * from finish();
rollback;
