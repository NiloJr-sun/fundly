-- Banks on accounts, step B.1 (20261126010000_banks.sql; docs/BANKS_PLAN.md).
-- bank.create/update/delete and their rules, roles and reads, the account's
-- bank (create, update, an older app's update, switching and clearing), the
-- table rules, tombstones, imports, counts and space deletion. Rolled back.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

insert into auth.users(id, email) values
  ('a5100000-0000-4000-8000-000000000001', 'bk-owner@example.invalid'),
  ('b5100000-0000-4000-8000-000000000001', 'bk-editor@example.invalid'),
  ('c5100000-0000-4000-8000-000000000001', 'bk-viewer@example.invalid'),
  ('d5100000-0000-4000-8000-000000000001', 'bk-outsider@example.invalid'),
  ('e5100000-0000-4000-8000-000000000001', 'bk-importer@example.invalid');
select fundly_private.ensure_personal_space(id) from auth.users where email like 'bk-%';
insert into public.space_members(space_id, user_id, role) values
  ('a5100000-0000-4000-8000-000000000001', 'b5100000-0000-4000-8000-000000000001', 'editor'),
  ('a5100000-0000-4000-8000-000000000001', 'c5100000-0000-4000-8000-000000000001', 'viewer');

create function pg_temp.act(actor uuid) returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object('sub', actor, 'role', 'authenticated')::text, true);
$$;
create function pg_temp.op(operation text, id text, data jsonb, revision text default null) returns jsonb
language sql as $$
  select jsonb_build_object('operation', operation, 'id', id)
    || case when data is null then '{}'::jsonb else jsonb_build_object('data', data) end
    || case when revision is null then '{}'::jsonb else jsonb_build_object('expected_revision', revision) end
$$;
-- 'ok', or the refusal's message; `target` names the space (default Personal).
create function pg_temp.try(actor uuid, items jsonb, target uuid default null) returns text
language plpgsql as $$
begin
  perform pg_temp.act(actor);
  perform public.fundly_apply_operations(gen_random_uuid(), jsonb_build_object('version', 1, 'items', items)
    || case when target is null then '{}'::jsonb else jsonb_build_object('space_id', target) end);
  return 'ok';
exception when others then
  return sqlerrm;
end;
$$;
-- The refusal's JSON detail.
create function pg_temp.detail(actor uuid, items jsonb) returns jsonb language plpgsql as $$
declare raw text;
begin
  perform pg_temp.act(actor);
  perform public.fundly_apply_operations(gen_random_uuid(), jsonb_build_object('version', 1, 'items', items));
  return null;
exception when others then
  get stacked diagnostics raw = pg_exception_detail;
  return nullif(raw, '')::jsonb;
end;
$$;
create function pg_temp.bank_of(account uuid) returns text language sql as $$
  select coalesce(a.bank_key, a.custom_bank_id::text, 'none') from public.accounts a where a.id = account
$$;
-- An import dataset with the given banks and accounts; nothing else.
create function pg_temp.dataset(banks jsonb, accounts jsonb) returns jsonb language sql as $$
  select jsonb_build_object('custom_account_types', '[]'::jsonb, 'accounts', accounts, 'categories', '[]'::jsonb,
    'transactions', '[]'::jsonb, 'monthly_plans', '[]'::jsonb, 'custom_banks', banks)
$$;
create function pg_temp.account_row(id text, name text, bank_key text, custom_bank_id text) returns jsonb
language sql as $$
  select jsonb_build_object('id', id, 'name', name, 'type', 'savingsCash', 'opening_balance_minor', '0',
    'currency_code', 'PHP', 'is_archived', false, 'custom_type_id', null, 'is_budget_account', false)
    || case when bank_key is null then '{}'::jsonb else jsonb_build_object('bank_key', bank_key) end
    || case when custom_bank_id is null then '{}'::jsonb else jsonb_build_object('custom_bank_id', custom_bank_id) end
$$;
-- 'ok', or the import error and where the server says the problem is.
create function pg_temp.import(actor uuid, request jsonb) returns text language plpgsql as $$
declare message text; raw text; detail jsonb;
begin
  perform pg_temp.act(actor);
  perform public.fundly_import_dataset(gen_random_uuid(), jsonb_build_object('version', 1) || request);
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

-- bank.create --------------------------------------------------------------------

select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.create', '15100000-0000-4000-8000-000000000001', '{"name":"  My Coop "}'))),
  'ok', 'the owner creates a custom bank');
select results_eq($$select name, space_id::text, owner_id::text, created_by::text, revision
    from public.custom_banks where id = '15100000-0000-4000-8000-000000000001'$$,
  $$values ('My Coop', 'a5100000-0000-4000-8000-000000000001', 'a5100000-0000-4000-8000-000000000001',
    'a5100000-0000-4000-8000-000000000001', 1::bigint)$$,
  'stored trimmed, in the space, with its creator and revision 1');
select is(pg_temp.try('b5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.create', '15100000-0000-4000-8000-000000000002', '{"name":"Credit union"}')),
    'a5100000-0000-4000-8000-000000000001'),
  'ok', 'an editor creates one in the space');
select is(pg_temp.try('c5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.create', '15100000-0000-4000-8000-000000000003', '{"name":"Viewer bank"}')),
    'a5100000-0000-4000-8000-000000000001'),
  'space_read_only', 'a viewer cannot');
select is(pg_temp.try('d5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.create', '15100000-0000-4000-8000-000000000003', '{"name":"Outsider bank"}')),
    'a5100000-0000-4000-8000-000000000001'),
  'not_space_member', 'an outsider cannot');

select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.create', '15100000-0000-4000-8000-000000000009', data))), message, description)
from (values
  ('{"name":"bdo"}'::jsonb, 'name_taken', 'a built-in bank''s name is refused, ignoring case'),
  ('{"name":" Land Bank "}', 'name_taken', 'a built-in name with outer spaces is refused'),
  ('{"name":"my coop"}', 'name_taken', 'names are unique in the space, ignoring case'),
  ('{"name":"   "}', 'invalid_name', 'a blank name is refused'),
  (jsonb_build_object('name', repeat('x', 41)), 'invalid_name', 'names are at most 40 characters'),
  ('{}', 'invalid_request', 'a name is required'),
  ('{"name":"Ok","colour":"red"}', 'invalid_request', 'unknown fields are refused')
) cases(data, message, description);
select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.create', '15100000-0000-4000-8000-000000000009', '{"name":"Ok"}', '1'))),
  'invalid_request', 'a create has no expected revision');
select is(pg_temp.try('d5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.create', '15100000-0000-4000-8000-000000000004', '{"name":"My Coop"}'))),
  'ok', 'another space may use the same name');

-- bank.update ----------------------------------------------------------------------

select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.update', '15100000-0000-4000-8000-000000000001', '{"name":"Town Coop"}', '1'))),
  'ok', 'a custom bank is renamed');
select results_eq($$select name, revision from public.custom_banks where id = '15100000-0000-4000-8000-000000000001'$$,
  $$values ('Town Coop', 2::bigint)$$, 'the rename advances the revision');
select is(pg_temp.detail('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.update', '15100000-0000-4000-8000-000000000001', '{"name":"Stale"}', '1')))->>'current_revision',
  '2', 'a stale rename is a revision conflict that names the current revision');
select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.update', '15100000-0000-4000-8000-000000000001', '{"name":"Credit Union"}', '2'))),
  'name_taken', 'a rename to another bank''s name is refused');
select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.update', '15100000-0000-4000-8000-000000000004', '{"name":"Mine now"}', '1'))),
  'record_not_accessible', 'another space''s bank cannot be changed');

-- Reads -----------------------------------------------------------------------------

select pg_temp.act('c5100000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.custom_banks), 2, 'a viewer reads the space''s banks');
select pg_temp.act('d5100000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.custom_banks), 1, 'an outsider reads only their own space''s banks');

-- The account's bank ----------------------------------------------------------------

select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('account.create', '25100000-0000-4000-8000-000000000001',
      '{"name":"BDO Savings","type":"savingsCash","entered_opening_amount_minor":"0","bank_key":"bdo"}'),
    pg_temp.op('account.create', '25100000-0000-4000-8000-000000000002',
      '{"name":"Coop Savings","type":"savingsCash","entered_opening_amount_minor":"0",
        "custom_bank_id":"15100000-0000-4000-8000-000000000001"}'),
    pg_temp.op('account.create', '25100000-0000-4000-8000-000000000003',
      '{"name":"BPI Card","type":"credit","entered_opening_amount_minor":"0","bank_key":"bpi"}'),
    pg_temp.op('account.create', '25100000-0000-4000-8000-000000000004',
      '{"name":"Cash wallet","type":"savingsCash","entered_opening_amount_minor":"0"}'))),
  'ok', 'accounts are created with a built-in bank, a custom bank, or none, of any type');
select results_eq($$select pg_temp.bank_of(id) from public.accounts
    where id::text like '25100000-0000-4000-8000-00000000000%' order by id$$,
  $$values ('bdo'), ('15100000-0000-4000-8000-000000000001'), ('bpi'), ('none')$$, 'each account keeps its bank');

select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('account.create', '25100000-0000-4000-8000-000000000009', data))), message, description)
from (values
  ('{"name":"Both","type":"savingsCash","entered_opening_amount_minor":"0","bank_key":"bdo",
     "custom_bank_id":"15100000-0000-4000-8000-000000000001"}'::jsonb, 'invalid_account', 'an account has one bank'),
  ('{"name":"Bad","type":"savingsCash","entered_opening_amount_minor":"0","bank_key":"BDO"}',
     'invalid_request', 'keys are lower case'),
  (jsonb_build_object('name', 'Bad', 'type', 'savingsCash', 'entered_opening_amount_minor', '0',
     'bank_key', repeat('b', 33)), 'invalid_request', 'keys are at most 32 characters'),
  ('{"name":"Bad","type":"savingsCash","entered_opening_amount_minor":"0","bank_key":7}',
     'invalid_request', 'keys are strings'),
  ('{"name":"Bad","type":"savingsCash","entered_opening_amount_minor":"0",
     "custom_bank_id":"15100000-0000-4000-8000-000000000099"}', 'record_not_accessible', 'an unknown custom bank'),
  ('{"name":"Bad","type":"savingsCash","entered_opening_amount_minor":"0",
     "custom_bank_id":"15100000-0000-4000-8000-000000000004"}', 'record_not_accessible',
     'another space''s custom bank')
) cases(data, message, description);

select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('account.update', '25100000-0000-4000-8000-000000000002', '{"name":"Coop Savings 2"}', '1'))),
  'ok', 'an older app updates without the bank fields');
select is(pg_temp.bank_of('25100000-0000-4000-8000-000000000002'), '15100000-0000-4000-8000-000000000001',
  'an update without the bank fields keeps the bank');
select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('account.update', '25100000-0000-4000-8000-000000000002', '{"bank_key":"maya"}', '2'))),
  'ok', 'switching to a built-in bank');
select is(pg_temp.bank_of('25100000-0000-4000-8000-000000000002'), 'maya',
  'sending one bank field replaces the bank: the custom bank is cleared');
select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('account.update', '25100000-0000-4000-8000-000000000001',
      '{"custom_bank_id":"15100000-0000-4000-8000-000000000001"}', '1'))),
  'ok', 'switching to a custom bank');
select is(pg_temp.bank_of('25100000-0000-4000-8000-000000000001'), '15100000-0000-4000-8000-000000000001',
  'the built-in key is cleared');
select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('account.update', '25100000-0000-4000-8000-000000000003', '{"bank_key":null}', '1'))),
  'ok', 'clearing the bank');
select is(pg_temp.bank_of('25100000-0000-4000-8000-000000000003'), 'none', 'the account has no bank');
select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('account.update', '25100000-0000-4000-8000-000000000003',
      '{"bank_key":"bpi","custom_bank_id":"15100000-0000-4000-8000-000000000001"}', '2'))),
  'invalid_account', 'an update cannot set both');
select is((select opening_balance_minor from public.accounts where id = '25100000-0000-4000-8000-000000000003'),
  0::bigint, 'bank edits leave the opening balance alone');

-- bank.delete -------------------------------------------------------------------------

select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('account.set_archived', '25100000-0000-4000-8000-000000000001', '{"archived":true}', '2'),
    pg_temp.op('bank.delete', '15100000-0000-4000-8000-000000000001', null, '2'))),
  'custom_bank_in_use', 'a bank used by an archived account cannot be deleted');
select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('account.update', '25100000-0000-4000-8000-000000000001', '{"custom_bank_id":null}', '2'),
    pg_temp.op('bank.delete', '15100000-0000-4000-8000-000000000001', null, '2'))),
  'ok', 'an unused bank is deleted');
reset role;
select is((select revision from public.fundly_deleted_records
    where entity = 'custom_banks' and id = '15100000-0000-4000-8000-000000000001'), 2::bigint,
  'the deletion leaves a tombstone with the last revision');
set local role authenticated;
select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.create', '15100000-0000-4000-8000-000000000001', '{"name":"Back again"}'))),
  'record_deleted', 'a deleted bank''s id is never reused');
select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('account.update', '25100000-0000-4000-8000-000000000004',
      '{"custom_bank_id":"15100000-0000-4000-8000-000000000001"}', '1'))),
  'record_deleted', 'a reference to a deleted bank says it was deleted');
select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.delete', '15100000-0000-4000-8000-000000000002', '{"name":"x"}', '1'))),
  'invalid_request', 'a delete carries no data');

-- Table rules -------------------------------------------------------------------------

reset role;
select throws_ok($$update public.accounts set bank_key = 'bdo',
    custom_bank_id = '15100000-0000-4000-8000-000000000002' where id = '25100000-0000-4000-8000-000000000004'$$,
  '23514', null, 'the table refuses two banks');
select throws_ok($$update public.accounts set bank_key = 'Not a key'
    where id = '25100000-0000-4000-8000-000000000004'$$, '23514', null, 'the table refuses a malformed key');
select throws_ok($$update public.accounts set custom_bank_id = '15100000-0000-4000-8000-000000000004'
    where id = '25100000-0000-4000-8000-000000000004'$$, '23503', null,
  'the table refuses another space''s bank');
select is((fundly_private.dataset_counts('a5100000-0000-4000-8000-000000000001')->>'custom_banks')::int, 1,
  'dataset counts include custom banks');
set local role authenticated;

-- Imports -------------------------------------------------------------------------------

select is(pg_temp.import('e5100000-0000-4000-8000-000000000001', jsonb_build_object('mode', 'into_empty',
    'dataset', pg_temp.dataset(banks, accounts))), message, description)
from (values
  ('[{"id":"15100000-0000-4000-8000-000000000101","name":"GCash"}]'::jsonb, '[]'::jsonb,
    'invalid_import custom_banks[0].name name_taken', 'an import refuses a built-in bank''s name'),
  ('[{"id":"15100000-0000-4000-8000-000000000101","name":"Coop"},
     {"id":"15100000-0000-4000-8000-000000000102","name":"COOP"}]', '[]',
    'invalid_import custom_banks[1].name name_taken', 'an import refuses duplicate names'),
  ('[{"id":"15100000-0000-4000-8000-000000000101","name":""}]', '[]',
    'invalid_import custom_banks[0].name invalid_name', 'an import refuses a blank name'),
  ('[]', jsonb_build_array(pg_temp.account_row('25100000-0000-4000-8000-000000000101', 'A', null,
     '15100000-0000-4000-8000-000000000199')),
    'invalid_import accounts[0].custom_bank_id invalid_reference', 'an import refuses a missing custom bank'),
  ('[{"id":"15100000-0000-4000-8000-000000000101","name":"Coop"}]',
   jsonb_build_array(pg_temp.account_row('25100000-0000-4000-8000-000000000101', 'A', 'bdo',
     '15100000-0000-4000-8000-000000000101')),
    'invalid_import accounts[0].custom_bank_id invalid_value', 'an import refuses two banks'),
  ('[]', jsonb_build_array(pg_temp.account_row('25100000-0000-4000-8000-000000000101', 'A', 'B D O', null)),
    'invalid_import accounts[0].bank_key invalid_value', 'an import refuses a malformed key'),
  ('[{"id":"15100000-0000-4000-8000-000000000002","name":"Taken id"}]', '[]',
    'record_id_unavailable', 'an import refuses an id used elsewhere'),
  ('[{"id":"15100000-0000-4000-8000-000000000001","name":"Retired id"}]', '[]',
    'record_id_unavailable', 'an import refuses a retired id')
) cases(banks, accounts, message, description);

select is(pg_temp.import('e5100000-0000-4000-8000-000000000001', jsonb_build_object('mode', 'into_empty',
    'dataset', pg_temp.dataset('[{"id":"15100000-0000-4000-8000-000000000101","name":"Coop"}]',
      jsonb_build_array(
        pg_temp.account_row('25100000-0000-4000-8000-000000000101', 'Coop Savings', null,
          '15100000-0000-4000-8000-000000000101'),
        pg_temp.account_row('25100000-0000-4000-8000-000000000102', 'GCash Wallet', 'gcash', null),
        pg_temp.account_row('25100000-0000-4000-8000-000000000103', 'Cash', null, null))))),
  'ok', 'an import accepts custom banks and accounts with or without a bank');
select results_eq($$select pg_temp.bank_of(id) from public.accounts
    where id::text like '25100000-0000-4000-8000-0000000001%' order by id$$,
  $$values ('15100000-0000-4000-8000-000000000101'), ('gcash'), ('none')$$, 'imported banks');

select is(pg_temp.import('e5100000-0000-4000-8000-000000000001', jsonb_build_object('mode', 'replace',
    'expected', jsonb_build_object('custom_account_types', 0, 'accounts', 3, 'categories', 0, 'transactions', 0,
      'monthly_plans', 0, 'custom_banks', 0),
    'dataset', pg_temp.dataset('[]', '[]'))),
  'dataset_changed', 'a replace compares the custom bank count when sent');
select is(pg_temp.import('e5100000-0000-4000-8000-000000000001', jsonb_build_object('mode', 'replace',
    'expected', jsonb_build_object('custom_account_types', 0, 'accounts', 3, 'categories', 0, 'transactions', 0,
      'monthly_plans', 0),
    'dataset', jsonb_build_object('custom_account_types', '[]'::jsonb, 'accounts', '[]'::jsonb,
      'categories', '[]'::jsonb, 'transactions', '[]'::jsonb, 'monthly_plans', '[]'::jsonb))),
  'ok', 'an older app''s replace, without custom banks, is accepted');
reset role;
select is((select count(*)::int from public.custom_banks where space_id = 'e5100000-0000-4000-8000-000000000001'),
  0, 'a replace removes the custom banks');
select ok(exists(select 1 from public.fundly_deleted_records where entity = 'custom_banks'
    and id = '15100000-0000-4000-8000-000000000101'), 'and tombstones them');
set local role authenticated;

select is(pg_temp.try('e5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.create', '15100000-0000-4000-8000-000000000201', '{"name":"Only a bank"}'))),
  'ok', 'a space with only a custom bank');
select is(pg_temp.import('e5100000-0000-4000-8000-000000000001', jsonb_build_object('mode', 'into_empty',
    'dataset', pg_temp.dataset('[]', '[]'))),
  'dataset_not_empty', 'is not empty');

-- Space deletion -------------------------------------------------------------------------

select pg_temp.act('a5100000-0000-4000-8000-000000000001');
select lives_ok($$select public.fundly_create_space('f5100000-0000-4000-8000-000000000001', 'Household')$$,
  'the owner creates a space');
select is(pg_temp.try('a5100000-0000-4000-8000-000000000001', jsonb_build_array(
    pg_temp.op('bank.create', '15100000-0000-4000-8000-000000000301', '{"name":"Household bank"}'),
    pg_temp.op('account.create', '25100000-0000-4000-8000-000000000301',
      '{"name":"Joint","type":"savingsCash","entered_opening_amount_minor":"0",
        "custom_bank_id":"15100000-0000-4000-8000-000000000301"}')),
    'f5100000-0000-4000-8000-000000000001'),
  'ok', 'the space gets a custom bank and an account using it');
select pg_temp.act('a5100000-0000-4000-8000-000000000001');
select is((public.fundly_delete_space('f5100000-0000-4000-8000-000000000001', 'household')
    ->'deleted'->>'custom_banks')::int, 1, 'deleting the space reports its custom banks');
reset role;
select is((select count(*)::int from public.custom_banks where space_id = 'f5100000-0000-4000-8000-000000000001'),
  0, 'and removes them');

select * from finish();
rollback;
