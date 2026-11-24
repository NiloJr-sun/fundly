-- Shared spaces C1 ROLLBACK (docs/SHARED_SPACES_C1_PLAN.md, "Rollback plan").
-- NOT a migration: kept outside supabase/migrations so it is never applied by
-- accident. Run only on the owner's decision, after the usual backups, as one
-- transaction (psql -1 / SQL editor), then record it in powersync/README.md.
--
-- Restores the write API, read rules and per-owner keys exactly as before C1
-- (every function definition below is the pre-C1 one, captured from the
-- database at migration 20261123020000). Data needs no repair: owner_id was
-- kept equal to space_id on every row. spaces, space_members and the new
-- columns stay in place, unused and nullable. Re-applying C1 afterwards needs
-- a new forward migration, not these files again.

-- 1. Stop the C1 triggers.
drop trigger fundly_space_bridge on public.custom_account_types;
drop trigger fundly_space_bridge on public.accounts;
drop trigger fundly_space_bridge on public.categories;
drop trigger fundly_space_bridge on public.transactions;
drop trigger fundly_space_bridge on public.monthly_plans;
drop trigger fundly_receipt_space on public.fundly_write_receipts;
drop trigger fundly_receipt_space on public.fundly_import_receipts;

-- 2. Remove the C1 functions (the pre-C1 ones are re-created in step 6).
drop function fundly_private.retired_space(text, jsonb);
drop function fundly_private.check_unretired(uuid, text, jsonb);
drop function fundly_private.dataset_counts(uuid);
drop function fundly_private.dataset_is_empty(uuid);
drop function fundly_private.check_custom_type(uuid, uuid, text);
drop function fundly_private.sync_liability_category(uuid, public.accounts, uuid);
drop function fundly_private.remaining_allocations(uuid, uuid, uuid, text);
drop function fundly_private.delete_category_plans(uuid, uuid);
drop function fundly_private.apply_transaction(uuid, jsonb);
drop function fundly_private.apply_custom_type(uuid, jsonb);
drop function fundly_private.apply_account(uuid, jsonb);
drop function fundly_private.apply_category(uuid, jsonb);
drop function fundly_private.apply_plan_save(uuid, jsonb);
drop function fundly_private.apply_plan_lifecycle(uuid, jsonb);
drop function fundly_private.apply_dataset_initialize(uuid, jsonb);
drop function fundly_private.apply_operation(uuid, jsonb);
drop function fundly_private.apply_item(uuid, jsonb, integer);
drop function fundly_private.space_role(uuid, uuid);
drop function fundly_private.request_space(uuid, jsonb);
drop function fundly_private.require_writer(uuid, uuid, boolean);
drop function fundly_private.bridge_space_owner();
drop function fundly_private.bridge_receipt_space();
drop function fundly_private.ensure_personal_space(uuid);

-- 3. Per-space keys, foreign keys and indexes out; C1's owner_id indexes out.
alter table public.accounts drop constraint accounts_custom_type_space_fk;
alter table public.categories drop constraint categories_linked_account_space_fk,
  drop constraint categories_linked_account_key;
alter table public.transactions drop constraint transactions_category_space_fk,
  drop constraint transactions_source_space_fk, drop constraint transactions_destination_space_fk;
alter table public.monthly_plans drop constraint monthly_plans_category_space_fk,
  drop constraint monthly_plans_space_category_month_key;
alter table public.custom_account_types drop constraint custom_account_types_space_id_key, drop constraint custom_account_types_owner_is_space,
  alter column space_id drop not null, alter column created_by drop not null,
  alter column updated_by drop not null;
alter table public.accounts drop constraint accounts_space_id_key, drop constraint accounts_owner_is_space,
  alter column space_id drop not null, alter column created_by drop not null,
  alter column updated_by drop not null;
alter table public.categories drop constraint categories_space_id_key, drop constraint categories_owner_is_space,
  alter column space_id drop not null, alter column created_by drop not null,
  alter column updated_by drop not null;
alter table public.transactions drop constraint transactions_space_id_key, drop constraint transactions_owner_is_space,
  alter column space_id drop not null, alter column created_by drop not null,
  alter column updated_by drop not null;
alter table public.monthly_plans drop constraint monthly_plans_space_id_key, drop constraint monthly_plans_owner_is_space,
  alter column space_id drop not null, alter column created_by drop not null,
  alter column updated_by drop not null;
drop index public.custom_account_types_space_name, public.accounts_space_name,
  public.categories_space_name, public.accounts_custom_type, public.monthly_plans_space_month,
  public.transactions_space_date, public.transactions_source_account,
  public.transactions_destination_account, public.transactions_category,
  public.custom_account_types_owner, public.accounts_owner, public.categories_owner,
  public.transactions_owner, public.monthly_plans_owner;
alter table public.fundly_deleted_records alter column space_id drop not null;
alter table public.fundly_write_receipts alter column space_id drop not null;
alter table public.fundly_import_receipts alter column space_id drop not null;

-- 4. Per-owner keys, foreign keys and indexes back, exactly as before C1.
alter table public.custom_account_types add constraint custom_account_types_owner_id_key unique (owner_id, id);
alter table public.accounts add constraint accounts_owner_id_key unique (owner_id, id);
alter table public.categories add constraint categories_owner_id_key unique (owner_id, id);
alter table public.transactions add constraint transactions_owner_id_key unique (owner_id, id);
alter table public.monthly_plans add constraint monthly_plans_owner_id_key unique (owner_id, id);
alter table public.accounts add constraint accounts_custom_type_owner_fk foreign key (owner_id, custom_type_id)
  references public.custom_account_types(owner_id, id) on delete restrict;
alter table public.categories add constraint categories_linked_account_key unique (owner_id, linked_account_id),
  add constraint categories_linked_account_owner_fk foreign key (owner_id, linked_account_id)
    references public.accounts(owner_id, id) on delete set null (linked_account_id);
alter table public.transactions
  add constraint transactions_category_owner_fk foreign key (owner_id, category_id)
    references public.categories(owner_id, id) on delete restrict,
  add constraint transactions_source_owner_fk foreign key (owner_id, source_account_id)
    references public.accounts(owner_id, id) on delete restrict,
  add constraint transactions_destination_owner_fk foreign key (owner_id, destination_account_id)
    references public.accounts(owner_id, id) on delete restrict;
alter table public.monthly_plans
  add constraint monthly_plans_owner_category_month_key unique (owner_id, category_id, month),
  add constraint monthly_plans_category_owner_fk foreign key (owner_id, category_id)
    references public.categories(owner_id, id) on delete cascade;
create unique index custom_account_types_owner_name on public.custom_account_types
  (owner_id, (translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') collate "C"));
create unique index accounts_owner_name on public.accounts
  (owner_id, (translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') collate "C"));
create unique index categories_owner_name on public.categories
  (owner_id, (translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') collate "C"));
create index accounts_custom_type on public.accounts(owner_id, custom_type_id);
create index monthly_plans_owner_month on public.monthly_plans(owner_id, month);
create index transactions_owner_date on public.transactions(owner_id, date, id);
create index transactions_source_account on public.transactions(owner_id, source_account_id);
create index transactions_destination_account on public.transactions(owner_id, destination_account_id);
create index transactions_category on public.transactions(owner_id, category_id);

-- 5. Read rules back to the owner.
drop policy read_member on public.custom_account_types;
create policy read_own on public.custom_account_types for select to authenticated
  using (owner_id = (select auth.uid()));
drop policy read_member on public.accounts;
create policy read_own on public.accounts for select to authenticated
  using (owner_id = (select auth.uid()));
drop policy read_member on public.categories;
create policy read_own on public.categories for select to authenticated
  using (owner_id = (select auth.uid()));
drop policy read_member on public.transactions;
create policy read_own on public.transactions for select to authenticated
  using (owner_id = (select auth.uid()));
drop policy read_member on public.monthly_plans;
create policy read_own on public.monthly_plans for select to authenticated
  using (owner_id = (select auth.uid()));

-- 6. Every pre-C1 function in fundly_private and public, verbatim, except
-- that fundly_import_dataset's row column lists include the three columns
-- left in place (it unnests whole table rows; same change as C1.1).

CREATE OR REPLACE FUNCTION fundly_private.account_wire(value accounts)
 RETURNS jsonb
 LANGUAGE sql
 STABLE STRICT
 SET search_path TO ''
AS $function$
  select fundly_private.metadata_wire(to_jsonb(value)) ||
    jsonb_build_object('opening_balance_minor',value.opening_balance_minor::text)
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.apply_account(actor uuid, item jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  operation text;
  record_id uuid;
  previous public.accounts%rowtype;
  row public.accounts%rowtype;
  category public.categories%rowtype;
  data jsonb;
  changes jsonb := '[]'::jsonb;
  account_name text;
  base text;
  opening bigint;
  custom_id uuid;
  linked_id uuid;
  archived boolean;
  violation text;
begin
  perform fundly_private.assert_keys(item,array['operation','id','expected_revision','data']);
  operation:=fundly_private.json_text(item->'operation');
  record_id:=fundly_private.json_uuid(item->'id');
  if operation='account.create' then
    if item ? 'expected_revision' then raise exception 'invalid_request' using errcode='22023'; end if;
  else
    perform fundly_private.positive_bigint(item->'expected_revision');
    select * into previous from public.accounts where id=record_id and owner_id=actor for update;
    if not found then raise exception 'record_not_accessible' using errcode='P0001'; end if;
    if previous.revision<>fundly_private.positive_bigint(item->'expected_revision') then
      raise exception 'revision_conflict' using errcode='P0001';
    end if;
  end if;
  data:=item->'data';
  if operation in ('account.delete','account.clear_budget') then
    if item ? 'data' and data<>'{}'::jsonb then raise exception 'invalid_request' using errcode='22023'; end if;
    if operation='account.clear_budget' then
      -- Clearing an account that is not a budget account changes nothing.
      if not previous.is_budget_account then row:=previous;
      else
        update public.accounts set is_budget_account=false,updated_at=clock_timestamp()
          where id=record_id and owner_id=actor returning * into row;
      end if;
    else
      if not previous.is_archived then raise exception 'account_not_archived' using errcode='P0001'; end if;
      if exists(select 1 from public.transactions where owner_id=actor
        and (source_account_id=record_id or destination_account_id=record_id)) then
        raise exception 'account_has_transactions' using errcode='P0001';
      end if;
      -- Detach explicitly so the single category revision also has an updated audit time.
      update public.categories set linked_account_id=null,updated_at=clock_timestamp()
        where owner_id=actor and linked_account_id=record_id returning * into category;
      if found then changes:=jsonb_build_array(jsonb_build_object('entity','categories','id',category.id,
        'revision',category.revision::text,'record',fundly_private.metadata_wire(to_jsonb(category)))); end if;
      delete from public.accounts where id=record_id and owner_id=actor;
      return jsonb_build_object('operation',operation,'entity','accounts','id',record_id,
        'revision',previous.revision::text,'deleted',true,'changes',changes);
    end if;
  elsif operation='account.set_budget' then
    -- Any number of accounts can be budget accounts; other budget accounts
    -- are left alone. App 1.1.0 still sends `previous_budget`; it is accepted
    -- and ignored.
    if data is not null then perform fundly_private.assert_keys(data,array['previous_budget']); end if;
    if previous.type<>'savingsCash' or previous.is_archived then raise exception 'invalid_account' using errcode='P0001'; end if;
    if previous.is_budget_account then row:=previous;
    else
      update public.accounts set is_budget_account=true,updated_at=clock_timestamp()
        where id=record_id and owner_id=actor returning * into row;
    end if;
  elsif operation='account.set_archived' then
    perform fundly_private.assert_keys(data,array['archived']);
    if jsonb_typeof(data->'archived') is distinct from 'boolean' then raise exception 'invalid_request' using errcode='22023'; end if;
    archived:=(data->>'archived')::boolean;
    update public.accounts set is_archived=archived,
      is_budget_account=case when archived then false else is_budget_account end,updated_at=clock_timestamp()
      where id=record_id and owner_id=actor returning * into row;
    changes:=fundly_private.sync_liability_category(actor,row);
  else
    if operation='account.create' then
      perform fundly_private.assert_keys(data,array['name','type','entered_opening_amount_minor','currency_code','custom_type_id','linked_category_id']);
      account_name:=fundly_private.valid_name(data->'name');
      base:=fundly_private.json_text(data->'type');
      opening:=fundly_private.nonnegative_bigint(data->'entered_opening_amount_minor');
      if data ? 'currency_code' and fundly_private.json_text(data->'currency_code')<>'PHP' then
        raise exception 'invalid_account' using errcode='P0001';
      end if;
      custom_id:=fundly_private.json_uuid(data->'custom_type_id',true);
      if data ? 'linked_category_id' then linked_id:=fundly_private.json_uuid(data->'linked_category_id'); end if;
      if base='savingsCash' and data ? 'linked_category_id' then raise exception 'invalid_request' using errcode='22023'; end if;
    else
      perform fundly_private.assert_keys(data,array['name','entered_opening_amount_minor','custom_type_id']);
      if data='{}'::jsonb then raise exception 'invalid_request' using errcode='22023'; end if;
      account_name:=case when data ? 'name' then fundly_private.valid_name(data->'name') else previous.name end;
      base:=previous.type;
      if data ? 'entered_opening_amount_minor' then opening:=fundly_private.nonnegative_bigint(data->'entered_opening_amount_minor');
      else opening:=previous.opening_balance_minor; end if;
      custom_id:=case when data ? 'custom_type_id' then fundly_private.json_uuid(data->'custom_type_id',true) else previous.custom_type_id end;
    end if;
    if base not in ('savingsCash','credit','loan') then raise exception 'invalid_account' using errcode='P0001'; end if;
    perform fundly_private.check_custom_type(actor,custom_id,base);
    if base<>'savingsCash' and (operation='account.create' or data ? 'entered_opening_amount_minor') then opening:=-opening; end if;
    begin
      if operation='account.create' then
        insert into public.accounts(id,owner_id,name,type,opening_balance_minor,custom_type_id,created_at,updated_at)
        values(record_id,actor,account_name,base,opening,custom_id,clock_timestamp(),clock_timestamp()) returning * into row;
      else
        update public.accounts set name=account_name,opening_balance_minor=opening,custom_type_id=custom_id,updated_at=clock_timestamp()
          where id=record_id and owner_id=actor returning * into row;
      end if;
    exception when unique_violation then
      get stacked diagnostics violation=constraint_name;
      if violation='accounts_owner_name' then raise exception 'name_taken' using errcode='P0001'; end if;
      raise exception 'record_id_unavailable' using errcode='P0001';
    end;
    changes:=fundly_private.sync_liability_category(actor,row,linked_id);
  end if;
  return jsonb_build_object('operation',operation,'entity','accounts','id',row.id,
    'revision',row.revision::text,'record',fundly_private.account_wire(row),'changes',changes);
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.apply_category(actor uuid, item jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  operation text;
  record_id uuid;
  data jsonb;
  previous public.categories%rowtype;
  row public.categories%rowtype;
  changes jsonb := '[]'::jsonb;
  category_name text;
  category_kind text;
  group_name text;
  violation text;
begin
  perform fundly_private.assert_keys(item, array['operation','id','expected_revision','data']);
  operation := fundly_private.json_text(item->'operation');
  record_id := fundly_private.json_uuid(item->'id');
  data := item->'data';
  if operation = 'category.create' then
    if item ? 'expected_revision' then raise exception 'invalid_request' using errcode = '22023'; end if;
  else
    perform fundly_private.positive_bigint(item->'expected_revision');
    select * into previous from public.categories
      where id = record_id and owner_id = actor for update;
    if not found then raise exception 'record_not_accessible' using errcode = 'P0001'; end if;
    if previous.revision <> fundly_private.positive_bigint(item->'expected_revision') then
      raise exception 'revision_conflict' using errcode = 'P0001';
    end if;
    if previous.linked_account_id is not null then
      raise exception 'managed_category' using errcode = 'P0001';
    end if;
  end if;

  if operation = 'category.delete' then
    if item ? 'data' and data <> '{}'::jsonb then raise exception 'invalid_request' using errcode = '22023'; end if;
    if exists(select 1 from public.transactions where owner_id = actor and category_id = record_id) then
      raise exception 'category_in_use' using errcode = 'P0001';
    end if;
    changes := fundly_private.delete_category_plans(actor, record_id);
    delete from public.categories where id = record_id and owner_id = actor;
    return jsonb_build_object('operation', operation, 'entity', 'categories', 'id', record_id,
      'revision', previous.revision::text, 'deleted', true, 'changes', changes);
  end if;

  if operation = 'category.set_archived' then
    perform fundly_private.assert_keys(data, array['archived']);
    if jsonb_typeof(data->'archived') is distinct from 'boolean' then
      raise exception 'invalid_request' using errcode = '22023';
    end if;
    update public.categories set is_archived = (data->>'archived')::boolean, updated_at = clock_timestamp()
      where id = record_id and owner_id = actor returning * into row;
  else
    if operation = 'category.create' then
      perform fundly_private.assert_keys(data, array['name','kind','plan_group']);
      if not data ?& array['name','kind'] then raise exception 'invalid_request' using errcode = '22023'; end if;
      category_kind := fundly_private.json_text(data->'kind');
      group_name := case when data ? 'plan_group'
        then fundly_private.json_text(data->'plan_group') else 'spending' end;
    else
      perform fundly_private.assert_keys(data, array['name','plan_group']);
      if data = '{}'::jsonb then raise exception 'invalid_request' using errcode = '22023'; end if;
      category_kind := previous.kind;
      group_name := case when data ? 'plan_group'
        then fundly_private.json_text(data->'plan_group') else previous.plan_group end;
    end if;
    -- Inflow categories are never planned, so they keep the default group.
    if category_kind not in ('spending','inflow')
      or group_name not in ('spending','savings','liability')
      or (category_kind = 'inflow' and group_name <> 'spending') then
      raise exception 'invalid_request' using errcode = '22023';
    end if;
    category_name := case when operation = 'category.create' or data ? 'name'
      then fundly_private.valid_name(data->'name') else previous.name end;
    begin
      if operation = 'category.create' then
        insert into public.categories(id, owner_id, name, kind, plan_group, created_at, updated_at)
        values(record_id, actor, category_name, category_kind, group_name, clock_timestamp(), clock_timestamp())
        returning * into row;
      else
        update public.categories set name = category_name, plan_group = group_name, updated_at = clock_timestamp()
          where id = record_id and owner_id = actor returning * into row;
      end if;
    exception when unique_violation then
      get stacked diagnostics violation = constraint_name;
      if violation = 'categories_owner_name' then raise exception 'name_taken' using errcode = 'P0001'; end if;
      raise exception 'record_id_unavailable' using errcode = 'P0001';
    end;
  end if;
  return jsonb_build_object('operation', operation, 'entity', 'categories', 'id', row.id,
    'revision', row.revision::text, 'record', fundly_private.category_wire(row), 'changes', changes);
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.apply_custom_type(actor uuid, item jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  operation text;
  record_id uuid;
  previous public.custom_account_types%rowtype;
  row public.custom_account_types%rowtype;
  data jsonb;
  type_name text;
  base text;
  violation text;
begin
  perform fundly_private.assert_keys(item,array['operation','id','expected_revision','data']);
  operation := fundly_private.json_text(item->'operation');
  record_id := fundly_private.json_uuid(item->'id');
  if operation='custom_type.create' then
    if item ? 'expected_revision' then raise exception 'invalid_request' using errcode='22023'; end if;
  else
    perform fundly_private.positive_bigint(item->'expected_revision');
    select * into previous from public.custom_account_types where id=record_id and owner_id=actor for update;
    if not found then raise exception 'record_not_accessible' using errcode='P0001'; end if;
    if previous.revision <> fundly_private.positive_bigint(item->'expected_revision') then
      raise exception 'revision_conflict' using errcode='P0001';
    end if;
  end if;
  if operation='custom_type.delete' then
    if item ? 'data' and item->'data' <> '{}'::jsonb then raise exception 'invalid_request' using errcode='22023'; end if;
    if exists(select 1 from public.accounts where owner_id=actor and custom_type_id=record_id) then
      raise exception 'custom_type_in_use' using errcode='P0001';
    end if;
    delete from public.custom_account_types where id=record_id and owner_id=actor;
    return jsonb_build_object('operation',operation,'entity','custom_account_types','id',record_id,
      'revision',previous.revision::text,'deleted',true);
  end if;
  data := item->'data';
  perform fundly_private.assert_keys(data,array['name','base_type']);
  if data='{}'::jsonb then raise exception 'invalid_request' using errcode='22023'; end if;
  if operation='custom_type.create' or data ? 'name' then type_name:=fundly_private.valid_name(data->'name');
  else type_name:=previous.name; end if;
  if operation='custom_type.create' or data ? 'base_type' then base:=fundly_private.json_text(data->'base_type');
  else base:=previous.base_type; end if;
  if lower(type_name) in ('savings / cash','credit','loan') then raise exception 'name_taken' using errcode='P0001'; end if;
  if base not in ('savingsCash','credit','loan') then raise exception 'invalid_custom_type' using errcode='P0001'; end if;
  if operation='custom_type.update' and base<>previous.base_type and
    exists(select 1 from public.accounts where owner_id=actor and custom_type_id=record_id) then
    raise exception 'custom_type_in_use' using errcode='P0001';
  end if;
  begin
    if operation='custom_type.create' then
      insert into public.custom_account_types(id,owner_id,name,base_type,created_at,updated_at)
      values(record_id,actor,type_name,base,clock_timestamp(),clock_timestamp()) returning * into row;
    else
      update public.custom_account_types set name=type_name,base_type=base,updated_at=clock_timestamp()
        where id=record_id and owner_id=actor returning * into row;
    end if;
  exception when unique_violation then
    get stacked diagnostics violation=constraint_name;
    if violation='custom_account_types_owner_name' then raise exception 'name_taken' using errcode='P0001'; end if;
    raise exception 'record_id_unavailable' using errcode='P0001';
  end;
  return jsonb_build_object('operation',operation,'entity','custom_account_types','id',row.id,
    'revision',row.revision::text,'record',fundly_private.metadata_wire(to_jsonb(row)));
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.apply_dataset_initialize(actor uuid, item jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  changes jsonb := '[]'::jsonb;
  row public.categories%rowtype;
  defaults constant text[][] := array[
    ['Rent','spending'], ['Utilities','spending'], ['Internet','spending'],
    ['Subscriptions','spending'], ['Food & Groceries','spending'], ['Fuel','spending'],
    ['Miscellaneous','spending'], ['Salary','inflow'], ['Other income','inflow']];
begin
  perform fundly_private.assert_keys(item, array['operation','id','data']);
  perform fundly_private.json_uuid(item->'id');
  if item ? 'data' and item->'data' <> '{}'::jsonb then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  if not exists(select 1 from public.categories where owner_id = actor) then
    for n in 1 .. array_length(defaults, 1) loop
      -- One clock reading per row keeps creation order equal to list order.
      insert into public.categories(id, owner_id, name, kind, created_at, updated_at)
      values(gen_random_uuid(), actor, defaults[n][1], defaults[n][2],
        clock_timestamp(), clock_timestamp())
      returning * into row;
      changes := changes || jsonb_build_array(jsonb_build_object('entity', 'categories',
        'id', row.id, 'revision', row.revision::text, 'record', fundly_private.category_wire(row)));
    end loop;
  end if;
  return jsonb_build_object('operation', 'dataset.initialize', 'initialized', jsonb_array_length(changes) > 0,
    'changes', changes);
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.apply_item(actor uuid, item jsonb, item_index integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  operation text;
  data jsonb := '{}'::jsonb;
  error_message text;
  error_state text;
  raw_detail text;
  detail jsonb;
  candidate record;
begin
  if jsonb_typeof(item) = 'object' then
    if jsonb_typeof(item->'operation') = 'string' then operation := item->>'operation'; end if;
    if jsonb_typeof(item->'data') = 'object' then data := item->'data'; end if;
  end if;
  begin
    if operation in ('transaction.create', 'custom_type.create', 'account.create', 'category.create')
      or (operation = 'plan.save' and data->'previous' = 'null'::jsonb) then
      perform fundly_private.check_unretired(actor, fundly_private.item_entity(operation), item->'id');
    end if;
    if operation = 'account.create' then
      perform fundly_private.check_unretired(actor, 'categories', data->'linked_category_id');
    end if;
    return fundly_private.apply_operation(actor, item);
  exception when sqlstate 'P0001' or sqlstate '22023' then
    get stacked diagnostics error_message = message_text, error_state = returned_sqlstate,
      raw_detail = pg_exception_detail;
  end;

  begin
    detail := nullif(raw_detail, '')::jsonb;
  exception when others then
    detail := null;
  end;
  if jsonb_typeof(detail) is distinct from 'object' then detail := '{}'::jsonb; end if;

  if error_message = 'record_not_accessible' then
    -- A missing record or reference that this owner deleted is reported as such.
    for candidate in
      select v.entity, v.value from (values
        (1, fundly_private.item_entity(operation), item->'id'),
        (2, 'accounts', data->'source_account_id'),
        (3, 'accounts', data->'destination_account_id'),
        (4, 'categories', data->'category_id'),
        (5, 'custom_account_types', data->'custom_type_id')
      ) v(rank, entity, value) order by v.rank
    loop
      if fundly_private.retired_owner(candidate.entity, candidate.value) = actor then
        error_message := 'record_deleted';
        detail := detail || jsonb_build_object('entity', candidate.entity,
          'deleted_id', candidate.value #>> '{}');
        exit;
      end if;
    end loop;
  elsif error_message = 'revision_conflict' then
    detail := detail || jsonb_build_object('current_revision', case fundly_private.item_entity(operation)
      when 'transactions' then (select revision::text from public.transactions
        where id = (item->>'id')::uuid and owner_id = actor)
      when 'custom_account_types' then (select revision::text from public.custom_account_types
        where id = (item->>'id')::uuid and owner_id = actor)
      when 'accounts' then (select revision::text from public.accounts
        where id = (item->>'id')::uuid and owner_id = actor)
      when 'categories' then (select revision::text from public.categories
        where id = (item->>'id')::uuid and owner_id = actor)
    end);
  elsif error_message = 'plan_conflict' then
    detail := detail || jsonb_build_object('current', (
      select jsonb_build_object('id', p.id, 'revision', p.revision::text)
      from public.monthly_plans p
      where p.owner_id = actor and p.category_id = (data->>'category_id')::uuid
        and p.month = data->>'month'));
  elsif error_message = 'budget_conflict' then
    detail := detail || jsonb_build_object('current', (
      select jsonb_build_object('id', a.id, 'revision', a.revision::text)
      from public.accounts a where a.owner_id = actor and a.is_budget_account));
  end if;

  detail := detail || jsonb_build_object('index', item_index);
  if jsonb_typeof(item) = 'object' and jsonb_typeof(item->'operation') = 'string' then
    detail := detail || jsonb_build_object('operation', item->'operation');
  end if;
  if jsonb_typeof(item) = 'object' and jsonb_typeof(item->'id') = 'string' then
    detail := detail || jsonb_build_object('id', item->'id');
  end if;
  raise exception using message = error_message, errcode = error_state, detail = detail::text;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.apply_operation(actor uuid, item jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare operation text;
begin
  perform fundly_private.assert_keys(item, array['operation','id','expected_revision','data']);
  operation := fundly_private.json_text(item->'operation');
  if operation in ('transaction.create','transaction.update','transaction.delete') then
    return fundly_private.apply_transaction(actor, item);
  elsif operation in ('custom_type.create','custom_type.update','custom_type.delete') then
    return fundly_private.apply_custom_type(actor, item);
  elsif operation in ('account.create','account.update','account.set_archived','account.delete',
    'account.set_budget','account.clear_budget') then
    return fundly_private.apply_account(actor, item);
  elsif operation in ('category.create','category.update','category.set_archived','category.delete') then
    return fundly_private.apply_category(actor, item);
  elsif operation = 'plan.save' then
    return fundly_private.apply_plan_save(actor, item);
  elsif operation in ('plan.set_archived','plan.delete_permanently') then
    return fundly_private.apply_plan_lifecycle(actor, item);
  elsif operation = 'dataset.initialize' then
    return fundly_private.apply_dataset_initialize(actor, item);
  end if;
  raise exception 'unsupported_operation' using errcode = 'P0001';
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.apply_plan_lifecycle(actor uuid, item jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  operation text;
  record_id uuid;
  data jsonb;
  archived boolean;
  zone text;
  blocked jsonb;
  reason text;
  changes jsonb := '[]'::jsonb;
  previous public.categories%rowtype;
  row public.categories%rowtype;
begin
  perform fundly_private.assert_keys(item, array['operation','id','expected_revision','data']);
  operation := fundly_private.json_text(item->'operation');
  record_id := fundly_private.json_uuid(item->'id');
  data := item->'data';
  perform fundly_private.positive_bigint(item->'expected_revision');
  select * into previous from public.categories
    where id = record_id and owner_id = actor for update;
  if not found then raise exception 'record_not_accessible' using errcode = 'P0001'; end if;
  if previous.revision <> fundly_private.positive_bigint(item->'expected_revision') then
    raise exception 'revision_conflict' using errcode = 'P0001';
  end if;

  if operation = 'plan.set_archived' then
    perform fundly_private.assert_keys(data, array['archived','timezone']);
    if jsonb_typeof(data->'archived') is distinct from 'boolean' then
      raise exception 'invalid_request' using errcode = '22023';
    end if;
    archived := (data->>'archived')::boolean;
    -- Only archiving depends on the caller's current month.
    if archived <> (data ? 'timezone') then raise exception 'invalid_request' using errcode = '22023'; end if;
    if archived then zone := fundly_private.valid_timezone(data->'timezone'); end if;
    if previous.kind <> 'spending' then raise exception 'category_not_spending' using errcode = 'P0001'; end if;
    if previous.is_plan_deleted then raise exception 'plan_deleted' using errcode = 'P0001'; end if;
    if not archived and previous.is_archived then
      raise exception 'category_archived' using errcode = 'P0001';
    end if;
    if archived = previous.is_plan_archived then
      row := previous;
    else
      if archived then
        blocked := fundly_private.remaining_allocations(actor, previous.id, previous.linked_account_id,
          fundly_private.local_month(zone, clock_timestamp()));
        if blocked <> '[]'::jsonb then
          raise exception 'plan_allocation_remaining' using errcode = 'P0001',
            detail = jsonb_build_object('months', blocked)::text;
        end if;
      end if;
      update public.categories set is_plan_archived = archived, updated_at = clock_timestamp()
        where id = record_id and owner_id = actor returning * into row;
    end if;
  else
    if item ? 'data' and data <> '{}'::jsonb then raise exception 'invalid_request' using errcode = '22023'; end if;
    reason := case
      when previous.kind <> 'spending' then 'category_not_spending'
      when previous.is_plan_deleted then 'already_deleted'
      when not previous.is_archived and not previous.is_plan_archived then 'not_archived'
      when exists(select 1 from public.monthly_plans p where p.owner_id = actor
        and p.category_id = record_id and p.assigned_amount_minor <> 0) then 'has_assigned_money'
      when exists(select 1 from public.transactions t where t.owner_id = actor and (
        (previous.linked_account_id is null and t.type = 'spending' and t.category_id = record_id)
        or (previous.linked_account_id is not null and t.type in ('transfer','creditCardPayment')
          and t.destination_account_id = previous.linked_account_id))) then 'has_activity'
    end;
    if reason is not null then
      raise exception 'plan_delete_blocked' using errcode = 'P0001',
        detail = jsonb_build_object('reason', reason)::text;
    end if;
    changes := fundly_private.delete_category_plans(actor, record_id);
    update public.categories set is_plan_archived = true, is_plan_deleted = true, updated_at = clock_timestamp()
      where id = record_id and owner_id = actor returning * into row;
  end if;
  return jsonb_build_object('operation', operation, 'entity', 'categories', 'id', row.id,
    'revision', row.revision::text, 'record', fundly_private.category_wire(row), 'changes', changes);
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.apply_plan_save(actor uuid, item jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  record_id uuid;
  data jsonb;
  prior jsonb;
  prior_id uuid;
  prior_revision bigint;
  plan_category uuid;
  plan_month text;
  target bigint;
  assigned bigint;
  category public.categories%rowtype;
  existing public.monthly_plans%rowtype;
  row public.monthly_plans%rowtype;
begin
  perform fundly_private.assert_keys(item, array['operation','id','data']);
  record_id := fundly_private.json_uuid(item->'id');
  data := item->'data';
  perform fundly_private.assert_keys(data, array[
    'category_id','month','target_amount_minor','assigned_amount_minor','previous']);
  if not data ?& array['category_id','month','target_amount_minor','assigned_amount_minor','previous'] then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  plan_category := fundly_private.json_uuid(data->'category_id');
  plan_month := fundly_private.calendar_month(data->'month');
  if data->'target_amount_minor' <> 'null'::jsonb then
    target := fundly_private.nonnegative_bigint(data->'target_amount_minor');
  end if;
  assigned := fundly_private.nonnegative_bigint(data->'assigned_amount_minor');
  prior := data->'previous';
  if prior <> 'null'::jsonb then
    perform fundly_private.assert_keys(prior, array['id','revision']);
    if not prior ?& array['id','revision'] then raise exception 'invalid_request' using errcode = '22023'; end if;
    prior_id := fundly_private.json_uuid(prior->'id');
    prior_revision := fundly_private.positive_bigint(prior->'revision');
    -- An existing record keeps its identity; the item names it.
    if prior_id <> record_id then raise exception 'invalid_request' using errcode = '22023'; end if;
  end if;

  select * into category from public.categories c
    where c.id = plan_category and c.owner_id = actor for share;
  if not found then raise exception 'record_not_accessible' using errcode = 'P0001'; end if;
  if category.kind <> 'spending' then raise exception 'category_not_spending' using errcode = 'P0001'; end if;
  if category.is_plan_deleted then raise exception 'plan_deleted' using errcode = 'P0001'; end if;
  if category.is_plan_archived then raise exception 'plan_archived' using errcode = 'P0001'; end if;

  select * into existing from public.monthly_plans p
    where p.owner_id = actor and p.category_id = category.id and p.month = plan_month for update;
  if (prior = 'null'::jsonb and existing.id is not null)
    or (prior <> 'null'::jsonb and (existing.id is null or existing.id <> prior_id
      or existing.revision <> prior_revision)) then
    raise exception 'plan_conflict' using errcode = 'P0001';
  end if;

  -- No Target and nothing assigned says nothing, so the record is removed.
  if target is null and assigned = 0 then
    if existing.id is null then
      return jsonb_build_object('operation', 'plan.save', 'entity', 'monthly_plans',
        'id', record_id, 'record', null, 'changes', '[]'::jsonb);
    end if;
    delete from public.monthly_plans where id = existing.id and owner_id = actor;
    return jsonb_build_object('operation', 'plan.save', 'entity', 'monthly_plans', 'id', existing.id,
      'revision', existing.revision::text, 'deleted', true, 'changes', '[]'::jsonb);
  end if;

  if existing.id is not null then
    update public.monthly_plans set target_amount_minor = target, assigned_amount_minor = assigned,
      updated_at = clock_timestamp()
      where id = existing.id and owner_id = actor returning * into row;
  else
    -- An archived category may keep editing an existing plan, not gain a new one.
    if category.is_archived then raise exception 'category_archived' using errcode = 'P0001'; end if;
    begin
      insert into public.monthly_plans(id, owner_id, month, category_id, target_amount_minor,
        assigned_amount_minor, created_at, updated_at)
      values(record_id, actor, plan_month, category.id, target, assigned, clock_timestamp(), clock_timestamp())
      returning * into row;
    exception when unique_violation then
      raise exception 'record_id_unavailable' using errcode = 'P0001';
    end;
  end if;
  return jsonb_build_object('operation', 'plan.save', 'entity', 'monthly_plans', 'id', row.id,
    'revision', row.revision::text, 'record', fundly_private.plan_wire(row), 'changes', '[]'::jsonb);
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.apply_transaction(actor uuid, item jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  operation text;
  record_id uuid;
  expected bigint;
  previous public.transactions%rowtype;
  candidate public.transactions%rowtype;
  account_row public.accounts%rowtype;
  source_type text;
  category_row public.categories%rowtype;
  data jsonb;
  patch jsonb;
  changed_at timestamptz;
begin
  perform fundly_private.assert_keys(item, array['operation','id','expected_revision','data']);
  operation := fundly_private.json_text(item->'operation');
  if operation not in ('transaction.create','transaction.update','transaction.delete') then
    raise exception 'unsupported_operation' using errcode = 'P0001';
  end if;
  record_id := fundly_private.json_uuid(item->'id');
  if operation = 'transaction.create' then
    if item ? 'expected_revision' then
      raise exception 'invalid_request' using errcode = '22023';
    end if;
  else
    expected := fundly_private.positive_bigint(item->'expected_revision');
    select * into previous from public.transactions
      where id = record_id and owner_id = actor for update;
    if not found then raise exception 'record_not_accessible' using errcode = 'P0001'; end if;
    if previous.revision <> expected then
      raise exception 'revision_conflict' using errcode = 'P0001';
    end if;
  end if;

  if operation = 'transaction.delete' then
    if item ? 'data' and item->'data' <> '{}'::jsonb then
      raise exception 'invalid_request' using errcode = '22023';
    end if;
    delete from public.transactions where id = record_id and owner_id = actor;
    return jsonb_build_object('operation', operation, 'id', record_id,
      'revision', previous.revision::text, 'deleted', true);
  end if;

  patch := item->'data';
  perform fundly_private.assert_keys(patch, array[
    'type','amount_minor','currency_code','date','payee','note',
    'category_id','source_account_id','destination_account_id']);
  if operation = 'transaction.create' then
    if not (patch ?& array['type','amount_minor','date']) then
      raise exception 'invalid_request' using errcode = '22023';
    end if;
    data := '{"currency_code":"PHP","payee":"","note":"","category_id":null,
      "source_account_id":null,"destination_account_id":null}'::jsonb || patch;
  else
    if patch = '{}'::jsonb then raise exception 'invalid_request' using errcode = '22023'; end if;
    data := fundly_private.transaction_wire(previous) || patch;
  end if;
  candidate.id := record_id;
  candidate.owner_id := actor;
  candidate.type := fundly_private.json_text(data->'type');
  candidate.amount_minor := fundly_private.positive_bigint(data->'amount_minor');
  candidate.currency_code := fundly_private.json_text(data->'currency_code');
  candidate.date := fundly_private.iso_date(data->'date');
  candidate.payee := fundly_private.trim_text(fundly_private.json_text(data->'payee'));
  candidate.note := fundly_private.trim_text(fundly_private.json_text(data->'note'));
  candidate.category_id := fundly_private.json_uuid(data->'category_id', true);
  candidate.source_account_id := fundly_private.json_uuid(data->'source_account_id', true);
  candidate.destination_account_id := fundly_private.json_uuid(data->'destination_account_id', true);

  if candidate.type not in ('spending','inflow','transfer','creditCardPayment')
    or candidate.currency_code <> 'PHP'
    or fundly_private.utf16_length(candidate.payee) > 60
    or fundly_private.utf16_length(candidate.note) > 500
    or (candidate.type in ('spending','inflow') and candidate.payee = '')
    or (operation = 'transaction.update' and candidate.type <> previous.type)
    or candidate.source_account_id = candidate.destination_account_id then
    raise exception 'invalid_transaction' using errcode = 'P0001';
  end if;
  if not (
    (candidate.type = 'spending' and candidate.source_account_id is not null
      and candidate.destination_account_id is null and candidate.category_id is not null)
    or (candidate.type = 'inflow' and candidate.source_account_id is null and candidate.destination_account_id is not null)
    or (candidate.type in ('transfer','creditCardPayment') and candidate.source_account_id is not null
      and candidate.destination_account_id is not null and candidate.category_id is null)
  ) then raise exception 'invalid_transaction' using errcode = 'P0001'; end if;

  if candidate.source_account_id is not null then
    select * into account_row from public.accounts
      where id = candidate.source_account_id and owner_id = actor for share;
    if not found then raise exception 'record_not_accessible' using errcode = 'P0001'; end if;
    if (account_row.is_archived and (operation = 'transaction.create'
        or candidate.source_account_id is distinct from previous.source_account_id))
      or (candidate.type = 'spending' and account_row.type not in ('savingsCash','credit'))
      or (candidate.type = 'transfer' and account_row.type not in ('savingsCash','credit'))
      or (candidate.type = 'creditCardPayment' and account_row.type <> 'savingsCash') then
      raise exception 'invalid_transaction' using errcode = 'P0001';
    end if;
    source_type := account_row.type;
  end if;
  if candidate.destination_account_id is not null then
    select * into account_row from public.accounts
      where id = candidate.destination_account_id and owner_id = actor for share;
    if not found then raise exception 'record_not_accessible' using errcode = 'P0001'; end if;
    if (account_row.is_archived and (operation = 'transaction.create'
        or candidate.destination_account_id is distinct from previous.destination_account_id))
      or (candidate.type = 'inflow' and account_row.type not in ('savingsCash','credit'))
      or (candidate.type = 'transfer' and account_row.type not in ('savingsCash','loan'))
      or (candidate.type = 'transfer' and source_type = 'credit' and account_row.type <> 'savingsCash')
      or (candidate.type = 'creditCardPayment' and account_row.type <> 'credit') then
      raise exception 'invalid_transaction' using errcode = 'P0001';
    end if;
  end if;
  if candidate.category_id is not null then
    select * into category_row from public.categories
      where id = candidate.category_id and owner_id = actor for share;
    if not found then raise exception 'record_not_accessible' using errcode = 'P0001'; end if;
    if category_row.linked_account_id is not null
      or category_row.kind <> (case when candidate.type = 'spending' then 'spending' else 'inflow' end)
      or (category_row.is_archived and (operation = 'transaction.create'
        or candidate.category_id is distinct from previous.category_id)) then
      raise exception 'invalid_transaction' using errcode = 'P0001';
    end if;
  end if;

  changed_at := clock_timestamp();
  if operation = 'transaction.create' then
    begin
      insert into public.transactions(id, owner_id, type, amount_minor, currency_code,
        date, payee, note, category_id, source_account_id, destination_account_id, created_at, updated_at)
      values(record_id, actor, candidate.type, candidate.amount_minor, candidate.currency_code,
        candidate.date, candidate.payee, candidate.note, candidate.category_id,
        candidate.source_account_id, candidate.destination_account_id, changed_at, changed_at)
      returning * into candidate;
    exception when unique_violation then
      -- Same-owner duplicate and cross-owner UUID collisions are indistinguishable.
      raise exception 'transaction_id_unavailable' using errcode = 'P0001';
    end;
  else
    update public.transactions set type = candidate.type, amount_minor = candidate.amount_minor,
      currency_code = candidate.currency_code, date = candidate.date, payee = candidate.payee,
      note = candidate.note, category_id = candidate.category_id,
      source_account_id = candidate.source_account_id,
      destination_account_id = candidate.destination_account_id, updated_at = changed_at
      where id = record_id and owner_id = actor returning * into candidate;
  end if;
  return jsonb_build_object('operation', operation, 'id', record_id,
    'revision', candidate.revision::text, 'record', fundly_private.transaction_wire(candidate));
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.assert_keys(value jsonb, allowed text[])
 RETURNS void
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
begin
  if jsonb_typeof(value) is distinct from 'object' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  if exists (select 1 from jsonb_object_keys(value) k where not (k = any(allowed))) then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.calendar_month(value jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
declare parsed text;
begin
  parsed := fundly_private.json_text(value);
  if parsed !~ '^[0-9]{4}-(0[1-9]|1[0-2])$' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  return parsed;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.category_wire(value categories)
 RETURNS jsonb
 LANGUAGE sql
 STABLE STRICT
 SET search_path TO ''
AS $function$
  select fundly_private.metadata_wire(to_jsonb(value))
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.check_custom_type(actor uuid, type_id uuid, base text)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare row public.custom_account_types%rowtype;
begin
  if type_id is null then return; end if;
  select * into row from public.custom_account_types where id=type_id and owner_id=actor for share;
  if not found then raise exception 'record_not_accessible' using errcode='P0001'; end if;
  if row.base_type <> base then raise exception 'invalid_account' using errcode='P0001'; end if;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.check_unretired(actor uuid, entity text, value jsonb)
 RETURNS void
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare owner uuid;
begin
  owner := fundly_private.retired_owner(entity, value);
  if owner = actor then
    raise exception 'record_deleted' using errcode = 'P0001',
      detail = jsonb_build_object('entity', entity, 'deleted_id', value #>> '{}')::text;
  elsif owner is not null then
    raise exception 'record_id_unavailable' using errcode = 'P0001';
  end if;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.dataset_counts(actor uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  select jsonb_build_object(
    'custom_account_types', (select count(*) from public.custom_account_types where owner_id = actor),
    'accounts', (select count(*) from public.accounts where owner_id = actor),
    'categories', (select count(*) from public.categories where owner_id = actor),
    'transactions', (select count(*) from public.transactions where owner_id = actor),
    'monthly_plans', (select count(*) from public.monthly_plans where owner_id = actor))
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.dataset_is_empty(actor uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  select not exists(select 1 from public.custom_account_types where owner_id = actor)
    and not exists(select 1 from public.accounts where owner_id = actor)
    and not exists(select 1 from public.transactions where owner_id = actor)
    and not exists(select 1 from public.monthly_plans where owner_id = actor)
    and not exists(select 1 from public.categories c where c.owner_id = actor and (
      c.revision <> 1 or c.is_archived or c.is_plan_archived or c.is_plan_deleted
      or c.plan_group <> 'spending' or c.linked_account_id is not null
      or (c.name, c.kind) not in (values ('Rent','spending'), ('Utilities','spending'),
        ('Internet','spending'), ('Subscriptions','spending'), ('Food & Groceries','spending'),
        ('Fuel','spending'), ('Miscellaneous','spending'), ('Salary','inflow'),
        ('Other income','inflow'))))
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.delete_category_plans(actor uuid, target_category uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare changes jsonb;
begin
  with gone as (
    delete from public.monthly_plans
    where owner_id = actor and category_id = target_category returning *
  )
  select coalesce(jsonb_agg(jsonb_build_object('entity', 'monthly_plans', 'id', id,
    'revision', revision::text, 'deleted', true) order by month), '[]'::jsonb)
  into changes from gone;
  return changes;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.import_check(found_at bigint, entity text, field text, rule text)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  if found_at is not null then
    perform fundly_private.import_fail(entity, (found_at - 1)::integer, field, rule);
  end if;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.import_fail(entity text, item_index integer, field text, rule text)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  raise exception 'invalid_import' using errcode = 'P0001',
    detail = jsonb_build_object('table', entity, 'index', item_index, 'field', field, 'rule', rule)::text;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.import_keys(entity text, item_index integer, item jsonb, required text[], optional text[])
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare key text;
begin
  if jsonb_typeof(item) is distinct from 'object' then
    perform fundly_private.import_fail(entity, item_index, null, 'not_an_object');
  end if;
  for key in select k from jsonb_object_keys(item) k order by k loop
    if not (key = any(required) or key = any(optional)) then
      perform fundly_private.import_fail(entity, item_index, key, 'unknown_field');
    end if;
  end loop;
  foreach key in array required loop
    if not item ? key then perform fundly_private.import_fail(entity, item_index, key, 'missing'); end if;
  end loop;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.import_name_key(value text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO ''
AS $function$
  select translate(value, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') collate "C"
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.import_name_valid(value text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO ''
AS $function$
  select value = fundly_private.trim_text(value) and value <> ''
    and fundly_private.utf16_length(value) <= 40
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.iso_date(value jsonb)
 RETURNS date
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
declare parsed text; year_number integer;
begin
  parsed := fundly_private.json_text(value);
  if parsed !~ '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  year_number := substr(parsed, 1, 4)::integer;
  begin
    return make_date(case when year_number = 0 then -1 else year_number end,
      substr(parsed, 6, 2)::integer, substr(parsed, 9, 2)::integer);
  exception when datetime_field_overflow then
    raise exception 'invalid_request' using errcode = '22023';
  end;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.item_entity(operation text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select case
    when operation like 'transaction.%' then 'transactions'
    when operation like 'custom!_type.%' escape '!' then 'custom_account_types'
    when operation like 'account.%' then 'accounts'
    when operation = 'plan.save' then 'monthly_plans'
    when operation like 'category.%' or operation like 'plan.%' then 'categories'
  end
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.json_boolean(value jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
begin
  if jsonb_typeof(value) is distinct from 'boolean' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  return value::text::boolean;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.json_text(value jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
begin
  if jsonb_typeof(value) is distinct from 'string' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  return value #>> '{}';
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.json_uuid(value jsonb, nullable boolean DEFAULT false)
 RETURNS uuid
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
declare parsed text;
begin
  if nullable and (value is null or value = 'null'::jsonb) then return null; end if;
  parsed := fundly_private.json_text(value);
  if parsed !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  return parsed::uuid;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.local_month(zone text, instant timestamp with time zone)
 RETURNS text
 LANGUAGE sql
 STABLE STRICT
 SET search_path TO ''
AS $function$
  select to_char(pg_catalog.timezone(zone, instant), 'YYYY-MM')
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.metadata_wire(value jsonb)
 RETURNS jsonb
 LANGUAGE sql
 STABLE STRICT
 SET search_path TO ''
AS $function$
  select value || jsonb_build_object('revision',value->>'revision',
    'created_at',to_char((value->>'created_at')::timestamptz at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'updated_at',to_char((value->>'updated_at')::timestamptz at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'))
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.nonnegative_bigint(value jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
begin
  if value = '"0"'::jsonb then return 0; end if;
  return fundly_private.positive_bigint(value);
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.plan_wire(value monthly_plans)
 RETURNS jsonb
 LANGUAGE sql
 STABLE STRICT
 SET search_path TO ''
AS $function$
  select fundly_private.metadata_wire(to_jsonb(value)) || jsonb_build_object(
    'target_amount_minor', value.target_amount_minor::text,
    'assigned_amount_minor', value.assigned_amount_minor::text)
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.positive_bigint(value jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
declare parsed text; number bigint;
begin
  parsed := fundly_private.json_text(value);
  if length(parsed) > 19 or parsed !~ '^[1-9][0-9]*$' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  begin
    number := parsed::bigint;
  exception when numeric_value_out_of_range then
    raise exception 'invalid_request' using errcode = '22023';
  end;
  return number;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.record_deletion()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  insert into public.fundly_deleted_records(entity, id, owner_id, revision)
  values (tg_table_name, old.id, old.owner_id, old.revision)
  on conflict (entity, id) do update set owner_id = excluded.owner_id,
    revision = excluded.revision, deleted_at = excluded.deleted_at;
  return null;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.remaining_allocations(actor uuid, target_category uuid, linked_account uuid, from_month text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  with remaining as (
    select p.month, p.assigned_amount_minor::numeric - coalesce((
      select sum(t.amount_minor)
      from public.transactions t
      join public.accounts b on b.id = t.source_account_id
        and b.owner_id = actor and b.is_budget_account
      where t.owner_id = actor
        and t.date >= to_date(p.month || '-01', 'YYYY-MM-DD')
        and t.date < (to_date(p.month || '-01', 'YYYY-MM-DD') + interval '1 month')
        and case when linked_account is null
          then t.type = 'spending' and t.category_id = target_category
          else t.type in ('transfer', 'creditCardPayment')
            and t.destination_account_id = linked_account end
    ), 0) as amount
    from public.monthly_plans p
    where p.owner_id = actor and p.category_id = target_category and p.month >= from_month
  )
  select coalesce(jsonb_agg(jsonb_build_object('month', month, 'remaining_minor', amount::text)
    order by month), '[]'::jsonb)
  from remaining where amount > 0
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.retired_owner(entity text, value jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare owner uuid;
begin
  if jsonb_typeof(value) is distinct from 'string'
    or (value #>> '{}') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    return null;
  end if;
  select d.owner_id into owner from public.fundly_deleted_records d
    where d.entity = retired_owner.entity and d.id = (value #>> '{}')::uuid;
  return owner;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.signed_bigint(value jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare parsed text;
begin
  parsed := fundly_private.json_text(value);
  if left(parsed, 1) = '-' then
    return -fundly_private.positive_bigint(to_jsonb(substr(parsed, 2)));
  end if;
  return fundly_private.nonnegative_bigint(value);
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.sync_liability_category(actor uuid, account accounts, requested_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  row public.categories%rowtype;
  desired_name text := account.name;
  suffix text;
  counter integer := 0;
begin
  if account.type not in ('credit','loan') then return '[]'::jsonb; end if;
  select * into row from public.categories
    where owner_id=actor and linked_account_id=account.id for update;
  if row.id is null and account.is_archived then return '[]'::jsonb; end if;
  if requested_id is not null and row.id is not null and requested_id <> row.id then
    raise exception 'record_id_unavailable' using errcode='P0001';
  end if;
  while exists(select 1 from public.categories c where c.owner_id=actor and c.id is distinct from row.id
    and (translate(c.name,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz') collate "C") =
        (translate(desired_name,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz') collate "C")) loop
    if counter >= 1000 then raise exception 'name_taken' using errcode='P0001'; end if;
    suffix := ' (debt ' || left(account.id::text,8) ||
      case when counter=0 then '' else '-'||counter::text end || ')';
    desired_name := fundly_private.utf16_prefix(account.name,40-fundly_private.utf16_length(suffix)) || suffix;
    counter := counter+1;
  end loop;
  if row.id is null then
    begin
      insert into public.categories(id,owner_id,name,kind,plan_group,linked_account_id,is_archived,created_at,updated_at)
      values(coalesce(requested_id,gen_random_uuid()),actor,desired_name,'spending','liability',account.id,
        account.is_archived,clock_timestamp(),clock_timestamp()) returning * into row;
    exception when unique_violation then
      raise exception 'record_id_unavailable' using errcode='P0001';
    end;
  elsif row.name is distinct from desired_name or row.is_archived is distinct from account.is_archived then
    -- Preserve independent plan archive/deletion flags, history and assignments.
    update public.categories set name=desired_name,is_archived=account.is_archived,
      updated_at=clock_timestamp() where id=row.id and owner_id=actor returning * into row;
  else
    return '[]'::jsonb;
  end if;
  return jsonb_build_array(jsonb_build_object('entity','categories','id',row.id,
    'revision',row.revision::text,'record',fundly_private.metadata_wire(to_jsonb(row))));
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.transaction_wire(value transactions)
 RETURNS jsonb
 LANGUAGE sql
 STABLE STRICT
 SET search_path TO ''
AS $function$
  select to_jsonb(value) || jsonb_build_object(
    'amount_minor', value.amount_minor::text,
    'revision', value.revision::text,
    'date', case when extract(year from value.date) = -1
      then '0000-' || to_char(value.date, 'MM-DD') else to_char(value.date, 'YYYY-MM-DD') end,
    'created_at', to_char(value.created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'updated_at', to_char(value.updated_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'))
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.trim_text(value text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO ''
AS $function$
  select btrim(value, chr(9)||chr(10)||chr(11)||chr(12)||chr(13)||chr(32)||
    chr(133)||chr(160)||chr(5760)||chr(8192)||chr(8193)||chr(8194)||chr(8195)||
    chr(8196)||chr(8197)||chr(8198)||chr(8199)||chr(8200)||chr(8201)||chr(8202)||
    chr(8232)||chr(8233)||chr(8239)||chr(8287)||chr(12288)||chr(65279))
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.utc_timestamp(value jsonb)
 RETURNS timestamp with time zone
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare parsed text;
begin
  if value is null or value = 'null'::jsonb then return null; end if;
  parsed := fundly_private.json_text(value);
  if parsed !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{1,6})?Z$' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  begin
    return (replace(parsed, 'Z', '+00:00'))::timestamptz;
  exception when datetime_field_overflow or invalid_datetime_format then
    raise exception 'invalid_request' using errcode = '22023';
  end;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.utf16_length(value text)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO ''
AS $function$
  select coalesce(sum(case when ascii(substr(value, i, 1)) > 65535 then 2 else 1 end), 0)::integer
  from generate_series(1, char_length(value)) i
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.utf16_prefix(value text, maximum integer)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE STRICT
 SET search_path TO ''
AS $function$
declare result text := ''; used integer := 0; character text; width integer;
begin
  for i in 1..char_length(value) loop
    character := substr(value,i,1);
    width := case when ascii(character) > 65535 then 2 else 1 end;
    exit when used + width > maximum;
    result := result || character;
    used := used + width;
  end loop;
  return result;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.valid_name(value jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
declare name text := fundly_private.trim_text(fundly_private.json_text(value));
begin
  if name = '' or fundly_private.utf16_length(name) > 40 then
    raise exception 'invalid_name' using errcode = 'P0001';
  end if;
  return name;
end;
$function$
;

CREATE OR REPLACE FUNCTION fundly_private.valid_timezone(value jsonb)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare zone text;
begin
  zone := fundly_private.json_text(value);
  if char_length(zone) > 64
    or not exists(select 1 from pg_catalog.pg_timezone_names n where n.name = zone) then
    raise exception 'invalid_timezone' using errcode = 'P0001';
  end if;
  return zone;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.fundly_apply_operations(batch_id uuid, operations jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  actor uuid := auth.uid();
  fingerprint bytea;
  receipt public.fundly_write_receipts%rowtype;
  results jsonb := '[]'::jsonb;
  item jsonb;
  item_index integer;
  response jsonb;
begin
  if actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  if batch_id is null then raise exception 'invalid_request' using errcode = '22023'; end if;
  perform fundly_private.assert_keys(operations, array['version','items']);
  if operations->'version' is distinct from '1'::jsonb
    or jsonb_typeof(operations->'version') <> 'number'
    or operations->>'version' <> '1'
    or octet_length(operations::text) > 262144 then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  if jsonb_typeof(operations->'items') is distinct from 'array' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  if jsonb_array_length(operations->'items') not between 1 and 100 then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  fingerprint := sha256(convert_to(operations::text, 'UTF8'));
  perform pg_advisory_xact_lock(hashtextextended('fundly:' || actor::text, 0));
  select * into receipt from public.fundly_write_receipts r
    where r.owner_id = actor and r.batch_id = fundly_apply_operations.batch_id;
  if found then
    if receipt.request_fingerprint <> fingerprint then
      raise exception 'batch_key_reused' using errcode = 'P0001';
    end if;
    return receipt.result;
  end if;
  for item, item_index in
    select e.value, (e.ordinality - 1)::integer
    from jsonb_array_elements(operations->'items') with ordinality e
  loop
    results := results || jsonb_build_array(fundly_private.apply_item(actor, item, item_index));
  end loop;
  response := jsonb_build_object('version', 1, 'batch_id', batch_id, 'results', results);
  insert into public.fundly_write_receipts(owner_id, batch_id, request_fingerprint, protocol_version, result)
    values(actor, batch_id, fingerprint, 1, response);
  return response;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.fundly_import_dataset(import_id uuid, request jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  actor uuid := auth.uid();
  fingerprint bytea;
  receipt public.fundly_import_receipts%rowtype;
  import_mode text;
  expected jsonb;
  dataset jsonb;
  entity text;
  field text;
  item jsonb;
  at_index integer;
  current_counts jsonb;
  response jsonb;
  types public.custom_account_types[] := '{}'::public.custom_account_types[];
  accounts public.accounts[] := '{}'::public.accounts[];
  categories public.categories[] := '{}'::public.categories[];
  transactions public.transactions[] := '{}'::public.transactions[];
  plans public.monthly_plans[] := '{}'::public.monthly_plans[];
  t public.custom_account_types;
  a public.accounts;
  c public.categories;
  x public.transactions;
  p public.monthly_plans;
begin
  if actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  -- 1. Size and envelope shape, before any work.
  if import_id is null or octet_length(request::text) > 8388608 then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  perform fundly_private.assert_keys(request, array['version','mode','expected','dataset']);
  if jsonb_typeof(request->'version') is distinct from 'number' or request->>'version' <> '1' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  import_mode := fundly_private.json_text(request->'mode');
  if import_mode not in ('into_empty', 'replace') then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  expected := request->'expected';
  if expected is not null then
    perform fundly_private.assert_keys(expected, array['custom_account_types','accounts',
      'categories','transactions','monthly_plans']);
    if (select count(*) from jsonb_each(expected) e
        where jsonb_typeof(e.value) = 'number' and e.value::text ~ '^(0|[1-9][0-9]{0,9})$') <> 5 then
      raise exception 'invalid_request' using errcode = '22023';
    end if;
  elsif import_mode = 'replace' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  dataset := request->'dataset';
  perform fundly_private.assert_keys(dataset, array['custom_account_types','accounts',
    'categories','transactions','monthly_plans']);
  if (select count(*) from jsonb_each(dataset) e where jsonb_typeof(e.value) = 'array') <> 5 then
    raise exception 'invalid_request' using errcode = '22023';
  end if;

  -- 2-3. Serialize with uploads, then answer a retry from its receipt.
  fingerprint := sha256(convert_to(request::text, 'UTF8'));
  perform pg_advisory_xact_lock(hashtextextended('fundly:' || actor::text, 0));
  select * into receipt from public.fundly_import_receipts r
    where r.owner_id = actor and r.import_id = fundly_import_dataset.import_id;
  if found then
    if receipt.request_fingerprint <> fingerprint then
      raise exception 'import_key_reused' using errcode = 'P0001';
    end if;
    return receipt.result;
  end if;

  -- 4. The account must still be what the user confirmed.
  current_counts := fundly_private.dataset_counts(actor);
  if import_mode = 'into_empty' and not fundly_private.dataset_is_empty(actor) then
    raise exception 'dataset_not_empty' using errcode = 'P0001',
      detail = jsonb_build_object('current', current_counts)::text;
  end if;
  if import_mode = 'replace'
    and (select bool_or(e.value::text::bigint <> (current_counts->>e.key)::bigint) from jsonb_each(expected) e) then
    raise exception 'dataset_changed' using errcode = 'P0001',
      detail = jsonb_build_object('current', current_counts)::text;
  end if;

  -- 5. Parse every record. `entity`, `at_index` and `field` say where a
  -- malformed value is; local variables keep their values in the handler.
  begin
    entity := 'custom_account_types';
    for item, at_index in select e.value, (e.ordinality - 1)::integer
        from jsonb_array_elements(dataset->entity) with ordinality e loop
      field := null;
      perform fundly_private.import_keys(entity, at_index, item,
        array['id','name','base_type'], array['created_at','updated_at']);
      t := null;
      t.owner_id := actor;
      t.revision := 1;
      field := 'id'; t.id := fundly_private.json_uuid(item->'id');
      field := 'name'; t.name := fundly_private.json_text(item->'name');
      field := 'base_type'; t.base_type := fundly_private.json_text(item->'base_type');
      field := 'created_at'; t.created_at := coalesce(fundly_private.utc_timestamp(item->'created_at'), now());
      field := 'updated_at'; t.updated_at := coalesce(fundly_private.utc_timestamp(item->'updated_at'), t.created_at);
      if not fundly_private.import_name_valid(t.name) then
        perform fundly_private.import_fail(entity, at_index, 'name', 'invalid_name');
      end if;
      if lower(t.name) in ('savings / cash','credit','loan') then
        perform fundly_private.import_fail(entity, at_index, 'name', 'name_taken');
      end if;
      if t.base_type not in ('savingsCash','credit','loan') then
        perform fundly_private.import_fail(entity, at_index, 'base_type', 'invalid_value');
      end if;
      types[at_index + 1] := t;
    end loop;

    entity := 'accounts';
    for item, at_index in select e.value, (e.ordinality - 1)::integer
        from jsonb_array_elements(dataset->entity) with ordinality e loop
      field := null;
      perform fundly_private.import_keys(entity, at_index, item,
        array['id','name','type','opening_balance_minor','currency_code','is_archived',
          'custom_type_id','is_budget_account'], array['created_at','updated_at']);
      a := null;
      a.owner_id := actor;
      a.revision := 1;
      field := 'id'; a.id := fundly_private.json_uuid(item->'id');
      field := 'name'; a.name := fundly_private.json_text(item->'name');
      field := 'type'; a.type := fundly_private.json_text(item->'type');
      field := 'opening_balance_minor';
      a.opening_balance_minor := fundly_private.signed_bigint(item->'opening_balance_minor');
      field := 'currency_code'; a.currency_code := fundly_private.json_text(item->'currency_code');
      field := 'is_archived'; a.is_archived := fundly_private.json_boolean(item->'is_archived');
      field := 'custom_type_id'; a.custom_type_id := fundly_private.json_uuid(item->'custom_type_id', true);
      field := 'is_budget_account'; a.is_budget_account := fundly_private.json_boolean(item->'is_budget_account');
      field := 'created_at'; a.created_at := coalesce(fundly_private.utc_timestamp(item->'created_at'), now());
      field := 'updated_at'; a.updated_at := coalesce(fundly_private.utc_timestamp(item->'updated_at'), a.created_at);
      if not fundly_private.import_name_valid(a.name) then
        perform fundly_private.import_fail(entity, at_index, 'name', 'invalid_name');
      end if;
      if a.type not in ('savingsCash','credit','loan') then
        perform fundly_private.import_fail(entity, at_index, 'type', 'invalid_value');
      end if;
      if a.currency_code <> 'PHP' then
        perform fundly_private.import_fail(entity, at_index, 'currency_code', 'invalid_value');
      end if;
      if (a.type = 'savingsCash' and a.opening_balance_minor < 0)
        or (a.type <> 'savingsCash' and a.opening_balance_minor > 0) then
        perform fundly_private.import_fail(entity, at_index, 'opening_balance_minor', 'wrong_sign');
      end if;
      if a.is_budget_account and (a.type <> 'savingsCash' or a.is_archived) then
        perform fundly_private.import_fail(entity, at_index, 'is_budget_account', 'not_eligible');
      end if;
      accounts[at_index + 1] := a;
    end loop;

    entity := 'categories';
    for item, at_index in select e.value, (e.ordinality - 1)::integer
        from jsonb_array_elements(dataset->entity) with ordinality e loop
      field := null;
      perform fundly_private.import_keys(entity, at_index, item,
        array['id','name','kind','is_archived','is_plan_archived','is_plan_deleted','plan_group',
          'linked_account_id'], array['created_at','updated_at']);
      c := null;
      c.owner_id := actor;
      c.revision := 1;
      field := 'id'; c.id := fundly_private.json_uuid(item->'id');
      field := 'name'; c.name := fundly_private.json_text(item->'name');
      field := 'kind'; c.kind := fundly_private.json_text(item->'kind');
      field := 'is_archived'; c.is_archived := fundly_private.json_boolean(item->'is_archived');
      field := 'is_plan_archived'; c.is_plan_archived := fundly_private.json_boolean(item->'is_plan_archived');
      field := 'is_plan_deleted'; c.is_plan_deleted := fundly_private.json_boolean(item->'is_plan_deleted');
      field := 'plan_group'; c.plan_group := fundly_private.json_text(item->'plan_group');
      field := 'linked_account_id'; c.linked_account_id := fundly_private.json_uuid(item->'linked_account_id', true);
      field := 'created_at'; c.created_at := coalesce(fundly_private.utc_timestamp(item->'created_at'), now());
      field := 'updated_at'; c.updated_at := coalesce(fundly_private.utc_timestamp(item->'updated_at'), c.created_at);
      if not fundly_private.import_name_valid(c.name) then
        perform fundly_private.import_fail(entity, at_index, 'name', 'invalid_name');
      end if;
      if c.kind not in ('spending','inflow') then
        perform fundly_private.import_fail(entity, at_index, 'kind', 'invalid_value');
      end if;
      if c.plan_group not in ('spending','savings','liability')
        or (c.kind = 'inflow' and c.plan_group <> 'spending') then
        perform fundly_private.import_fail(entity, at_index, 'plan_group', 'invalid_value');
      end if;
      if c.is_plan_archived and c.kind <> 'spending' then
        perform fundly_private.import_fail(entity, at_index, 'is_plan_archived', 'invalid_value');
      end if;
      if c.is_plan_deleted and not c.is_plan_archived then
        perform fundly_private.import_fail(entity, at_index, 'is_plan_deleted', 'invalid_value');
      end if;
      categories[at_index + 1] := c;
    end loop;

    entity := 'transactions';
    for item, at_index in select e.value, (e.ordinality - 1)::integer
        from jsonb_array_elements(dataset->entity) with ordinality e loop
      field := null;
      perform fundly_private.import_keys(entity, at_index, item,
        array['id','type','amount_minor','currency_code','date','payee','category_id',
          'source_account_id','destination_account_id','note'], array['created_at','updated_at']);
      x := null;
      x.owner_id := actor;
      x.revision := 1;
      field := 'id'; x.id := fundly_private.json_uuid(item->'id');
      field := 'type'; x.type := fundly_private.json_text(item->'type');
      field := 'amount_minor'; x.amount_minor := fundly_private.positive_bigint(item->'amount_minor');
      field := 'currency_code'; x.currency_code := fundly_private.json_text(item->'currency_code');
      field := 'date'; x.date := fundly_private.iso_date(item->'date');
      field := 'payee'; x.payee := fundly_private.json_text(item->'payee');
      field := 'category_id'; x.category_id := fundly_private.json_uuid(item->'category_id', true);
      field := 'source_account_id'; x.source_account_id := fundly_private.json_uuid(item->'source_account_id', true);
      field := 'destination_account_id';
      x.destination_account_id := fundly_private.json_uuid(item->'destination_account_id', true);
      field := 'note'; x.note := fundly_private.json_text(item->'note');
      field := 'created_at'; x.created_at := coalesce(fundly_private.utc_timestamp(item->'created_at'), now());
      field := 'updated_at'; x.updated_at := coalesce(fundly_private.utc_timestamp(item->'updated_at'), x.created_at);
      if x.type not in ('spending','inflow','transfer','creditCardPayment') then
        perform fundly_private.import_fail(entity, at_index, 'type', 'invalid_value');
      end if;
      if x.currency_code <> 'PHP' then
        perform fundly_private.import_fail(entity, at_index, 'currency_code', 'invalid_value');
      end if;
      if fundly_private.utf16_length(x.payee) > 60
        or (x.type in ('spending','inflow') and fundly_private.trim_text(x.payee) = '') then
        perform fundly_private.import_fail(entity, at_index, 'payee', 'invalid_value');
      end if;
      if fundly_private.utf16_length(x.note) > 500 then
        perform fundly_private.import_fail(entity, at_index, 'note', 'invalid_value');
      end if;
      if not (
        (x.type = 'spending' and x.source_account_id is not null
          and x.destination_account_id is null and x.category_id is not null)
        or (x.type = 'inflow' and x.source_account_id is null and x.destination_account_id is not null)
        or (x.type in ('transfer','creditCardPayment') and x.source_account_id is not null
          and x.destination_account_id is not null and x.category_id is null)
      ) then
        perform fundly_private.import_fail(entity, at_index, null, 'invalid_shape');
      end if;
      if x.source_account_id = x.destination_account_id then
        perform fundly_private.import_fail(entity, at_index, 'destination_account_id', 'same_account');
      end if;
      transactions[at_index + 1] := x;
    end loop;

    entity := 'monthly_plans';
    for item, at_index in select e.value, (e.ordinality - 1)::integer
        from jsonb_array_elements(dataset->entity) with ordinality e loop
      field := null;
      perform fundly_private.import_keys(entity, at_index, item,
        array['id','month','category_id','target_amount_minor','assigned_amount_minor','currency_code'],
        array['created_at','updated_at']);
      p := null;
      p.owner_id := actor;
      p.revision := 1;
      field := 'id'; p.id := fundly_private.json_uuid(item->'id');
      field := 'month'; p.month := fundly_private.calendar_month(item->'month');
      field := 'category_id'; p.category_id := fundly_private.json_uuid(item->'category_id');
      field := 'target_amount_minor';
      p.target_amount_minor := case when item->'target_amount_minor' = 'null'::jsonb then null
        else fundly_private.nonnegative_bigint(item->'target_amount_minor') end;
      field := 'assigned_amount_minor';
      p.assigned_amount_minor := fundly_private.nonnegative_bigint(item->'assigned_amount_minor');
      field := 'currency_code'; p.currency_code := fundly_private.json_text(item->'currency_code');
      field := 'created_at'; p.created_at := coalesce(fundly_private.utc_timestamp(item->'created_at'), now());
      field := 'updated_at'; p.updated_at := coalesce(fundly_private.utc_timestamp(item->'updated_at'), p.created_at);
      if p.currency_code <> 'PHP' then
        perform fundly_private.import_fail(entity, at_index, 'currency_code', 'invalid_value');
      end if;
      plans[at_index + 1] := p;
    end loop;
  exception when sqlstate '22023' then
    perform fundly_private.import_fail(entity, at_index, field, 'invalid_value');
  end;

  -- 6. The final state, across records. Positions are 1-based here.
  perform fundly_private.import_check((select min(r.n) from (
      select n, row_number() over (partition by id order by n) k from unnest(types) with ordinality u(id, owner_id, name, base_type, created_at, updated_at, revision, space_id, created_by, updated_by, n)
    ) r where r.k > 1), 'custom_account_types', 'id', 'duplicate_id');
  perform fundly_private.import_check((select min(r.n) from (
      select n, row_number() over (partition by fundly_private.import_name_key(u.name) order by n) k
      from unnest(types) with ordinality u(id, owner_id, name, base_type, created_at, updated_at, revision, space_id, created_by, updated_by, n)
    ) r where r.k > 1), 'custom_account_types', 'name', 'name_taken');

  perform fundly_private.import_check((select min(r.n) from (
      select u.n, row_number() over (partition by u.id order by u.n) k
      from unnest(accounts) with ordinality u(id, owner_id, name, type, opening_balance_minor, currency_code,
        is_archived, custom_type_id, is_budget_account, created_at, updated_at, revision, space_id, created_by, updated_by, n)
    ) r where r.k > 1), 'accounts', 'id', 'duplicate_id');
  perform fundly_private.import_check((select min(r.n) from (
      select u.n, row_number() over (partition by fundly_private.import_name_key(u.name) order by u.n) k
      from unnest(accounts) with ordinality u(id, owner_id, name, type, opening_balance_minor, currency_code,
        is_archived, custom_type_id, is_budget_account, created_at, updated_at, revision, space_id, created_by, updated_by, n)
    ) r where r.k > 1), 'accounts', 'name', 'name_taken');
  perform fundly_private.import_check((select min(u.n)
      from unnest(accounts) with ordinality u(id, owner_id, name, type, opening_balance_minor, currency_code,
        is_archived, custom_type_id, is_budget_account, created_at, updated_at, revision, space_id, created_by, updated_by, n)
      where u.custom_type_id is not null and not exists(select 1 from unnest(types) ct
        where ct.id = u.custom_type_id and ct.base_type = u.type)),
    'accounts', 'custom_type_id', 'invalid_reference');

  perform fundly_private.import_check((select min(r.n) from (
      select u.n, row_number() over (partition by u.id order by u.n) k
      from unnest(categories) with ordinality u(id, owner_id, name, kind, is_archived, is_plan_archived,
        is_plan_deleted, plan_group, linked_account_id, created_at, updated_at, revision, space_id, created_by, updated_by, n)
    ) r where r.k > 1), 'categories', 'id', 'duplicate_id');
  perform fundly_private.import_check((select min(r.n) from (
      select u.n, row_number() over (partition by fundly_private.import_name_key(u.name) order by u.n) k
      from unnest(categories) with ordinality u(id, owner_id, name, kind, is_archived, is_plan_archived,
        is_plan_deleted, plan_group, linked_account_id, created_at, updated_at, revision, space_id, created_by, updated_by, n)
    ) r where r.k > 1), 'categories', 'name', 'name_taken');
  -- A linked Plans row belongs to one liability account and follows its archive status.
  perform fundly_private.import_check((select min(r.n) from (
      select u.n, u.kind, u.plan_group, u.is_archived, ac.type, ac.is_archived as account_archived,
        row_number() over (partition by u.linked_account_id order by u.n) k
      from unnest(categories) with ordinality u(id, owner_id, name, kind, is_archived, is_plan_archived,
        is_plan_deleted, plan_group, linked_account_id, created_at, updated_at, revision, space_id, created_by, updated_by, n)
      left join unnest(accounts) ac on ac.id = u.linked_account_id
      where u.linked_account_id is not null
    ) r where r.k > 1 or r.type is null or r.type = 'savingsCash' or r.kind <> 'spending'
      or r.plan_group <> 'liability' or r.is_archived <> r.account_archived),
    'categories', 'linked_account_id', 'invalid_link');
  perform fundly_private.import_check((select min(u.n)
      from unnest(accounts) with ordinality u(id, owner_id, name, type, opening_balance_minor, currency_code,
        is_archived, custom_type_id, is_budget_account, created_at, updated_at, revision, space_id, created_by, updated_by, n)
      where u.type <> 'savingsCash' and not u.is_archived
        and not exists(select 1 from unnest(categories) ca where ca.linked_account_id = u.id)),
    'accounts', 'id', 'missing_linked_category');

  perform fundly_private.import_check((select min(r.n) from (
      select u.n, row_number() over (partition by u.id order by u.n) k
      from unnest(transactions) with ordinality u(id, owner_id, type, amount_minor, currency_code, date, payee,
        category_id, source_account_id, destination_account_id, note, created_at, updated_at, revision, space_id, created_by, updated_by, n)
    ) r where r.k > 1), 'transactions', 'id', 'duplicate_id');
  -- Archived accounts and categories may hold history, as in a local restore.
  perform fundly_private.import_check((select min(u.n)
      from unnest(transactions) with ordinality u(id, owner_id, type, amount_minor, currency_code, date, payee,
        category_id, source_account_id, destination_account_id, note, created_at, updated_at, revision, space_id, created_by, updated_by, n)
      left join unnest(accounts) ac on ac.id = u.source_account_id
      where u.source_account_id is not null and ac.id is null),
    'transactions', 'source_account_id', 'invalid_reference');
  perform fundly_private.import_check((select min(u.n)
      from unnest(transactions) with ordinality u(id, owner_id, type, amount_minor, currency_code, date, payee,
        category_id, source_account_id, destination_account_id, note, created_at, updated_at, revision, space_id, created_by, updated_by, n)
      left join unnest(accounts) ac on ac.id = u.destination_account_id
      where u.destination_account_id is not null and ac.id is null),
    'transactions', 'destination_account_id', 'invalid_reference');
  perform fundly_private.import_check((select min(u.n)
      from unnest(transactions) with ordinality u(id, owner_id, type, amount_minor, currency_code, date, payee,
        category_id, source_account_id, destination_account_id, note, created_at, updated_at, revision, space_id, created_by, updated_by, n)
      left join unnest(categories) ca on ca.id = u.category_id
      where u.category_id is not null and ca.id is null),
    'transactions', 'category_id', 'invalid_reference');
  perform fundly_private.import_check((select min(u.n)
      from unnest(transactions) with ordinality u(id, owner_id, type, amount_minor, currency_code, date, payee,
        category_id, source_account_id, destination_account_id, note, created_at, updated_at, revision, space_id, created_by, updated_by, n)
      join unnest(accounts) ac on ac.id = u.source_account_id
      where (u.type = 'spending' and ac.type not in ('savingsCash','credit'))
        or (u.type = 'transfer' and ac.type not in ('savingsCash','credit'))
        or (u.type = 'creditCardPayment' and ac.type <> 'savingsCash')),
    'transactions', 'source_account_id', 'account_not_allowed');
  perform fundly_private.import_check((select min(u.n)
      from unnest(transactions) with ordinality u(id, owner_id, type, amount_minor, currency_code, date, payee,
        category_id, source_account_id, destination_account_id, note, created_at, updated_at, revision, space_id, created_by, updated_by, n)
      join unnest(accounts) ac on ac.id = u.destination_account_id
      left join unnest(accounts) src on src.id = u.source_account_id
      where (u.type = 'inflow' and ac.type not in ('savingsCash','credit'))
        or (u.type = 'transfer' and ac.type not in ('savingsCash','loan'))
        or (u.type = 'transfer' and src.type = 'credit' and ac.type <> 'savingsCash')
        or (u.type = 'creditCardPayment' and ac.type <> 'credit')),
    'transactions', 'destination_account_id', 'account_not_allowed');
  perform fundly_private.import_check((select min(u.n)
      from unnest(transactions) with ordinality u(id, owner_id, type, amount_minor, currency_code, date, payee,
        category_id, source_account_id, destination_account_id, note, created_at, updated_at, revision, space_id, created_by, updated_by, n)
      join unnest(categories) ca on ca.id = u.category_id
      where ca.linked_account_id is not null
        or ca.kind <> case when u.type = 'spending' then 'spending' else 'inflow' end),
    'transactions', 'category_id', 'category_not_allowed');

  perform fundly_private.import_check((select min(r.n) from (
      select u.n, row_number() over (partition by u.id order by u.n) k
      from unnest(plans) with ordinality u(id, owner_id, month, category_id, target_amount_minor,
        assigned_amount_minor, currency_code, created_at, updated_at, revision, space_id, created_by, updated_by, n)
    ) r where r.k > 1), 'monthly_plans', 'id', 'duplicate_id');
  perform fundly_private.import_check((select min(u.n)
      from unnest(plans) with ordinality u(id, owner_id, month, category_id, target_amount_minor,
        assigned_amount_minor, currency_code, created_at, updated_at, revision, space_id, created_by, updated_by, n)
      left join unnest(categories) ca on ca.id = u.category_id
      where ca.id is null), 'monthly_plans', 'category_id', 'invalid_reference');
  perform fundly_private.import_check((select min(u.n)
      from unnest(plans) with ordinality u(id, owner_id, month, category_id, target_amount_minor,
        assigned_amount_minor, currency_code, created_at, updated_at, revision, space_id, created_by, updated_by, n)
      join unnest(categories) ca on ca.id = u.category_id
      where ca.kind <> 'spending' or ca.is_plan_deleted), 'monthly_plans', 'category_id', 'category_not_allowed');
  perform fundly_private.import_check((select min(r.n) from (
      select u.n, row_number() over (partition by u.category_id, u.month order by u.n) k
      from unnest(plans) with ordinality u(id, owner_id, month, category_id, target_amount_minor,
        assigned_amount_minor, currency_code, created_at, updated_at, revision, space_id, created_by, updated_by, n)
    ) r where r.k > 1), 'monthly_plans', 'month', 'duplicate_plan');

  -- IDs must be new to every owner and never retired. Which owner holds a
  -- clashing ID is never revealed.
  for entity, at_index in
    select v.entity, v.n from (
      select 'custom_account_types' entity, u.n from unnest(types) with ordinality u(id, owner_id, name, base_type,
        created_at, updated_at, revision, space_id, created_by, updated_by, n)
        where exists(select 1 from public.custom_account_types r where r.id = u.id)
      union all select 'accounts', u.n from unnest(accounts) with ordinality u(id, owner_id, name, type,
        opening_balance_minor, currency_code, is_archived, custom_type_id, is_budget_account, created_at,
        updated_at, revision, space_id, created_by, updated_by, n) where exists(select 1 from public.accounts r where r.id = u.id)
      union all select 'categories', u.n from unnest(categories) with ordinality u(id, owner_id, name, kind,
        is_archived, is_plan_archived, is_plan_deleted, plan_group, linked_account_id, created_at, updated_at,
        revision, space_id, created_by, updated_by, n) where exists(select 1 from public.categories r where r.id = u.id)
      union all select 'transactions', u.n from unnest(transactions) with ordinality u(id, owner_id, type,
        amount_minor, currency_code, date, payee, category_id, source_account_id, destination_account_id, note,
        created_at, updated_at, revision, space_id, created_by, updated_by, n) where exists(select 1 from public.transactions r where r.id = u.id)
      union all select 'monthly_plans', u.n from unnest(plans) with ordinality u(id, owner_id, month,
        category_id, target_amount_minor, assigned_amount_minor, currency_code, created_at, updated_at,
        revision, space_id, created_by, updated_by, n) where exists(select 1 from public.monthly_plans r where r.id = u.id)
      union all select d.entity, u.n from (
          select 'custom_account_types' entity, t2.id, t2.n from unnest(types) with ordinality t2(id, o, nm, b,
            ca, ua, rv, sp, cb, ub, n)
          union all select 'accounts', a2.id, a2.n from unnest(accounts) with ordinality a2(id, o, nm, ty, ob,
            cc, ar, ct, bu, ca, ua, rv, sp, cb, ub, n)
          union all select 'categories', c2.id, c2.n from unnest(categories) with ordinality c2(id, o, nm, k, ar,
            pa, pd, pg, la, ca, ua, rv, sp, cb, ub, n)
          union all select 'transactions', x2.id, x2.n from unnest(transactions) with ordinality x2(id, o, ty,
            am, cc, dt, py, ci, si, di, nt, ca, ua, rv, sp, cb, ub, n)
          union all select 'monthly_plans', p2.id, p2.n from unnest(plans) with ordinality p2(id, o, mo, ci,
            ta, aa, cc, ca, ua, rv, sp, cb, ub, n)
        ) u join public.fundly_deleted_records d on d.entity = u.entity and d.id = u.id
    ) v order by v.entity, v.n limit 1
  loop
    raise exception 'record_id_unavailable' using errcode = 'P0001',
      detail = jsonb_build_object('table', entity, 'index', at_index - 1, 'field', 'id')::text;
  end loop;

  -- 7. Remove the current dataset; the delete triggers write tombstones.
  delete from public.monthly_plans where owner_id = actor;
  delete from public.transactions where owner_id = actor;
  delete from public.categories where owner_id = actor;
  delete from public.accounts where owner_id = actor;
  delete from public.custom_account_types where owner_id = actor;

  -- 8. Insert in reference order; the revision trigger sets revision 1.
  begin
    insert into public.custom_account_types select * from unnest(types);
    insert into public.accounts select * from unnest(accounts);
    insert into public.categories select * from unnest(categories);
    insert into public.transactions select * from unnest(transactions);
    insert into public.monthly_plans select * from unnest(plans);
  exception when integrity_constraint_violation then
    -- Step 6 should have caught it: report it rather than leak a constraint name.
    raise exception 'invalid_import' using errcode = 'P0001',
      detail = jsonb_build_object('rule', 'constraint')::text;
  end;

  -- 9. Receipt and result.
  response := jsonb_build_object('version', 1, 'import_id', import_id, 'mode', import_mode,
    'counts', jsonb_build_object(
      'custom_account_types', cardinality(types), 'accounts', cardinality(accounts),
      'categories', cardinality(categories), 'transactions', cardinality(transactions),
      'monthly_plans', cardinality(plans)));
  insert into public.fundly_import_receipts(owner_id, import_id, request_fingerprint, mode, result)
    values(actor, import_id, fingerprint, import_mode, response);
  return response;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.fundly_set_revision()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  if tg_op = 'INSERT' then
    new.revision := 1;
  else
    if new.id is distinct from old.id or new.owner_id is distinct from old.owner_id then
      raise exception 'Fundly record identity and owner are immutable' using errcode = '23514';
    end if;
    new.revision := old.revision + 1;
  end if;
  return new;
end;
$function$
;

revoke all on all functions in schema fundly_private from public, anon, authenticated, service_role;
