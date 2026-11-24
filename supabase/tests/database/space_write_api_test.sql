-- Shared spaces C1.2: the write API per space (docs/SHARED_SPACES_C1_PLAN.md).
-- Every operation as owner, editor, viewer, non-member and removed member;
-- attribution; per-space retired IDs; imports. Everything is rolled back.
--
-- In C1 only Personal spaces hold records (owner_id must equal space_id), so
-- the shared space here is O's Personal space with members added in SQL.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

insert into auth.users(id, email) values
  ('a1200000-0000-4000-8000-000000000001', 'c12-owner@example.invalid'),
  ('b1200000-0000-4000-8000-000000000001', 'c12-editor@example.invalid'),
  ('c1200000-0000-4000-8000-000000000001', 'c12-viewer@example.invalid'),
  ('d1200000-0000-4000-8000-000000000001', 'c12-outsider@example.invalid'),
  ('e1200000-0000-4000-8000-000000000001', 'c12-removed@example.invalid');
select fundly_private.ensure_personal_space(id) from auth.users where email like 'c12-%';
insert into public.space_members(space_id, user_id, role) values
  ('a1200000-0000-4000-8000-000000000001', 'b1200000-0000-4000-8000-000000000001', 'editor'),
  ('a1200000-0000-4000-8000-000000000001', 'c1200000-0000-4000-8000-000000000001', 'viewer'),
  ('a1200000-0000-4000-8000-000000000001', 'e1200000-0000-4000-8000-000000000001', 'editor');

-- One batch as `actor`; `target` adds `space_id` to the envelope.
create function pg_temp.write(actor uuid, items jsonb, target uuid default null,
  batch uuid default gen_random_uuid()) returns jsonb language plpgsql as $$
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub', actor, 'role', 'authenticated')::text, true);
  return public.fundly_apply_operations(batch, jsonb_build_object('version', 1, 'items', items)
    || case when target is null then '{}'::jsonb else jsonb_build_object('space_id', target) end);
end;
$$;
create function pg_temp.import(actor uuid, mode text, target uuid) returns jsonb language plpgsql as $$
declare empty jsonb := jsonb_build_object('custom_account_types', 0, 'accounts', 0, 'categories', 0,
  'transactions', 0, 'monthly_plans', 0);
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub', actor, 'role', 'authenticated')::text, true);
  return public.fundly_import_dataset(gen_random_uuid(), jsonb_build_object('version', 1, 'mode', mode,
    'dataset', jsonb_build_object('custom_account_types', '[]'::jsonb, 'accounts', '[]'::jsonb,
      'categories', '[]'::jsonb, 'transactions', '[]'::jsonb, 'monthly_plans', '[]'::jsonb))
    || case when mode = 'replace' then jsonb_build_object('expected', empty) else '{}'::jsonb end
    || case when target is null then '{}'::jsonb else jsonb_build_object('space_id', target) end);
end;
$$;
grant execute on all functions in schema pg_temp to authenticated;
set local role authenticated;

-- The owner, without space_id (as every app sends today), sets up records.
select lives_ok($$select pg_temp.write('a1200000-0000-4000-8000-000000000001', jsonb_build_array(
    jsonb_build_object('operation', 'custom_type.create', 'id', '11200000-0000-4000-8000-000000000001',
      'data', jsonb_build_object('name', 'Wallets', 'base_type', 'savingsCash')),
    jsonb_build_object('operation', 'account.create', 'id', '21200000-0000-4000-8000-000000000001',
      'data', jsonb_build_object('name', 'Owner cash', 'type', 'savingsCash', 'entered_opening_amount_minor', '5000')),
    jsonb_build_object('operation', 'category.create', 'id', '31200000-0000-4000-8000-000000000001',
      'data', jsonb_build_object('name', 'Food', 'kind', 'spending'))))$$,
  'the owner writes to their Personal space without naming it');

-- Editor: every operation, in the shared space ------------------------------

create temporary table editor_steps(n int, label text, item jsonb);
grant select on editor_steps to authenticated;
insert into editor_steps values
  (1, 'custom_type.create', '{"operation":"custom_type.create","id":"11200000-0000-4000-8000-000000000002","data":{"name":"Joint","base_type":"savingsCash"}}'),
  (2, 'custom_type.update', '{"operation":"custom_type.update","id":"11200000-0000-4000-8000-000000000002","expected_revision":"1","data":{"name":"Joint types"}}'),
  (3, 'account.create', '{"operation":"account.create","id":"21200000-0000-4000-8000-000000000002","data":{"name":"Joint cash","type":"savingsCash","entered_opening_amount_minor":"1000","custom_type_id":"11200000-0000-4000-8000-000000000002"}}'),
  (4, 'account.update', '{"operation":"account.update","id":"21200000-0000-4000-8000-000000000002","expected_revision":"1","data":{"name":"Joint wallet"}}'),
  (5, 'account.set_budget', '{"operation":"account.set_budget","id":"21200000-0000-4000-8000-000000000002","expected_revision":"2","data":{}}'),
  (6, 'account.clear_budget', '{"operation":"account.clear_budget","id":"21200000-0000-4000-8000-000000000002","expected_revision":"3","data":{}}'),
  (7, 'category.create', '{"operation":"category.create","id":"31200000-0000-4000-8000-000000000002","data":{"name":"Home","kind":"spending"}}'),
  (8, 'category.update', '{"operation":"category.update","id":"31200000-0000-4000-8000-000000000002","expected_revision":"1","data":{"name":"House"}}'),
  (9, 'transaction.create', '{"operation":"transaction.create","id":"41200000-0000-4000-8000-000000000001","data":{"type":"spending","amount_minor":"500","date":"2026-11-24","payee":"Store","source_account_id":"21200000-0000-4000-8000-000000000002","category_id":"31200000-0000-4000-8000-000000000002"}}'),
  (10, 'transaction.update', '{"operation":"transaction.update","id":"41200000-0000-4000-8000-000000000001","expected_revision":"1","data":{"note":"Edited"}}'),
  (11, 'transaction.delete', '{"operation":"transaction.delete","id":"41200000-0000-4000-8000-000000000001","expected_revision":"2"}'),
  (12, 'plan.save', '{"operation":"plan.save","id":"51200000-0000-4000-8000-000000000001","data":{"category_id":"31200000-0000-4000-8000-000000000002","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":"300","previous":null}}'),
  (13, 'plan.save (clear)', '{"operation":"plan.save","id":"51200000-0000-4000-8000-000000000001","data":{"category_id":"31200000-0000-4000-8000-000000000002","month":"2026-11","target_amount_minor":null,"assigned_amount_minor":"0","previous":{"id":"51200000-0000-4000-8000-000000000001","revision":"1"}}}'),
  (14, 'plan.set_archived', '{"operation":"plan.set_archived","id":"31200000-0000-4000-8000-000000000002","expected_revision":"2","data":{"archived":true,"timezone":"Asia/Manila"}}'),
  (15, 'plan.delete_permanently', '{"operation":"plan.delete_permanently","id":"31200000-0000-4000-8000-000000000002","expected_revision":"3","data":{}}'),
  (16, 'category.set_archived', '{"operation":"category.set_archived","id":"31200000-0000-4000-8000-000000000002","expected_revision":"4","data":{"archived":true}}'),
  (17, 'category.delete', '{"operation":"category.delete","id":"31200000-0000-4000-8000-000000000002","expected_revision":"5"}'),
  (18, 'account.set_archived', '{"operation":"account.set_archived","id":"21200000-0000-4000-8000-000000000002","expected_revision":"4","data":{"archived":true}}'),
  (19, 'account.delete', '{"operation":"account.delete","id":"21200000-0000-4000-8000-000000000002","expected_revision":"5"}'),
  (20, 'custom_type.delete', '{"operation":"custom_type.delete","id":"11200000-0000-4000-8000-000000000002","expected_revision":"2"}'),
  (21, 'dataset.initialize', '{"operation":"dataset.initialize","id":"61200000-0000-4000-8000-000000000001"}');

-- Viewer, outsider and removed member are refused before anything is applied,
-- so every operation is tried against the starting state.
select throws_ok(format($$select pg_temp.write('c1200000-0000-4000-8000-000000000001', jsonb_build_array(%L::jsonb),
    'a1200000-0000-4000-8000-000000000001')$$, item), 'P0001', 'space_read_only', 'viewer refused: ' || label)
  from editor_steps order by n;
select throws_ok(format($$select pg_temp.write('d1200000-0000-4000-8000-000000000001', jsonb_build_array(%L::jsonb),
    'a1200000-0000-4000-8000-000000000001')$$, item), 'P0001', 'not_space_member', 'outsider refused: ' || label)
  from editor_steps order by n;

-- R writes once while still a member, then is removed.
select lives_ok($$select pg_temp.write('e1200000-0000-4000-8000-000000000001', jsonb_build_array(
    '{"operation":"category.create","id":"31200000-0000-4000-8000-000000000009","data":{"name":"Before removal","kind":"spending"}}'::jsonb),
    'a1200000-0000-4000-8000-000000000001', '71200000-0000-4000-8000-000000000009')$$,
  'a member writes before being removed');
reset role;
delete from public.space_members where user_id = 'e1200000-0000-4000-8000-000000000001'
  and space_id = 'a1200000-0000-4000-8000-000000000001';
set local role authenticated;
select throws_ok(format($$select pg_temp.write('e1200000-0000-4000-8000-000000000001', jsonb_build_array(%L::jsonb),
    'a1200000-0000-4000-8000-000000000001')$$, item), 'P0001', 'not_space_member', 'removed member refused: ' || label)
  from editor_steps order by n;
select is(pg_temp.write('e1200000-0000-4000-8000-000000000001', jsonb_build_array(
    '{"operation":"category.create","id":"31200000-0000-4000-8000-000000000009","data":{"name":"Before removal","kind":"spending"}}'::jsonb),
    'a1200000-0000-4000-8000-000000000001', '71200000-0000-4000-8000-000000000009')->>'batch_id',
  '71200000-0000-4000-8000-000000000009',
  'a removed member''s retry of a batch applied earlier still answers from its receipt');

reset role;
select is((select count(*)::int from public.custom_account_types where space_id = 'a1200000-0000-4000-8000-000000000001'), 1,
  'refused writes changed nothing');
set local role authenticated;

select lives_ok(format($$select pg_temp.write('b1200000-0000-4000-8000-000000000001', jsonb_build_array(%L::jsonb),
    'a1200000-0000-4000-8000-000000000001')$$, item), 'editor may: ' || label)
  from editor_steps order by n;

-- Attribution and placement -------------------------------------------------

select lives_ok($$select pg_temp.write('b1200000-0000-4000-8000-000000000001', jsonb_build_array(
    '{"operation":"transaction.create","id":"41200000-0000-4000-8000-000000000002","data":{"type":"spending","amount_minor":"700","date":"2026-11-24","payee":"Bakery","source_account_id":"21200000-0000-4000-8000-000000000001","category_id":"31200000-0000-4000-8000-000000000001"}}'::jsonb),
    'a1200000-0000-4000-8000-000000000001')$$, 'the editor records a spending in the shared space');
select lives_ok($$select pg_temp.write('a1200000-0000-4000-8000-000000000001', jsonb_build_array(
    '{"operation":"transaction.update","id":"41200000-0000-4000-8000-000000000002","expected_revision":"1","data":{"note":"Checked"}}'::jsonb))$$,
  'the owner edits it');
reset role;
select results_eq($$select space_id::text, owner_id::text, created_by::text, updated_by::text
    from public.transactions where id = '41200000-0000-4000-8000-000000000002'$$,
  $$values ('a1200000-0000-4000-8000-000000000001', 'a1200000-0000-4000-8000-000000000001',
    'b1200000-0000-4000-8000-000000000001', 'a1200000-0000-4000-8000-000000000001')$$,
  'the record is in the space, created by the editor and last changed by the owner');
select is((select space_id::text from public.fundly_write_receipts
    where owner_id = 'b1200000-0000-4000-8000-000000000001' order by created_at desc limit 1),
  'a1200000-0000-4000-8000-000000000001', 'the editor''s receipt is theirs and names the space');
select is((select count(*)::int from public.categories where space_id = 'b1200000-0000-4000-8000-000000000001'), 0,
  'nothing the editor wrote went to the editor''s own Personal space');
set local role authenticated;

-- Retired IDs are per space -------------------------------------------------

select throws_ok($$select pg_temp.write('b1200000-0000-4000-8000-000000000001', jsonb_build_array(
    '{"operation":"category.create","id":"31200000-0000-4000-8000-000000000002","data":{"name":"Again","kind":"spending"}}'::jsonb),
    'a1200000-0000-4000-8000-000000000001')$$, 'P0001', 'record_deleted',
  'reusing a deleted ID in its own space reports it as deleted');
select throws_ok($$select pg_temp.write('b1200000-0000-4000-8000-000000000001', jsonb_build_array(
    '{"operation":"category.create","id":"31200000-0000-4000-8000-000000000002","data":{"name":"Again","kind":"spending"}}'::jsonb))$$,
  'P0001', 'record_id_unavailable', 'in another space the deleted ID is just unavailable');

-- Spaces the caller names -----------------------------------------------------

select throws_ok($$select pg_temp.write('d1200000-0000-4000-8000-000000000001', jsonb_build_array(
    '{"operation":"dataset.initialize","id":"61200000-0000-4000-8000-000000000002"}'::jsonb),
    'f1200000-0000-4000-8000-000000000001')$$, 'P0001', 'not_space_member',
  'a space that does not exist is refused like any other');
select throws_ok($$select public.fundly_apply_operations(gen_random_uuid(),
    '{"version":1,"space_id":"not-a-uuid","items":[{"operation":"dataset.initialize","id":"61200000-0000-4000-8000-000000000003"}]}')$$,
  '22023', 'invalid_request', 'a malformed space_id is an invalid request');
select throws_ok($$select public.fundly_apply_operations(gen_random_uuid(),
    '{"version":1,"space_id":null,"items":[{"operation":"dataset.initialize","id":"61200000-0000-4000-8000-000000000004"}]}')$$,
  '22023', 'invalid_request', 'an explicit null space_id is an invalid request (leave it out instead)');
select lives_ok($$select pg_temp.write('a1200000-0000-4000-8000-000000000001', jsonb_build_array(
    '{"operation":"category.update","id":"31200000-0000-4000-8000-000000000001","expected_revision":"1","data":{"name":"Groceries"}}'::jsonb),
    'a1200000-0000-4000-8000-000000000001')$$, 'the owner may also name their Personal space');

-- Imports are for owners ------------------------------------------------------

select throws_ok($$select pg_temp.import('b1200000-0000-4000-8000-000000000001', 'replace',
    'a1200000-0000-4000-8000-000000000001')$$, 'P0001', 'space_owner_only', 'an editor cannot replace a space');
select throws_ok($$select pg_temp.import('b1200000-0000-4000-8000-000000000001', 'into_empty',
    'a1200000-0000-4000-8000-000000000001')$$, 'P0001', 'space_owner_only', 'an editor cannot import into a space');
select throws_ok($$select pg_temp.import('c1200000-0000-4000-8000-000000000001', 'replace',
    'a1200000-0000-4000-8000-000000000001')$$, 'P0001', 'space_read_only', 'a viewer cannot replace a space');
select throws_ok($$select pg_temp.import('d1200000-0000-4000-8000-000000000001', 'replace',
    'a1200000-0000-4000-8000-000000000001')$$, 'P0001', 'not_space_member', 'an outsider cannot replace a space');
select throws_ok($$select pg_temp.import('a1200000-0000-4000-8000-000000000001', 'into_empty',
    'a1200000-0000-4000-8000-000000000001')$$, 'P0001', 'dataset_not_empty',
  'the owner passes the role check (then the usual empty-space rule applies)');
select lives_ok($$select pg_temp.import('d1200000-0000-4000-8000-000000000001', 'into_empty', null)$$,
  'without space_id an import goes to the caller''s own Personal space');

select * from finish();
rollback;
