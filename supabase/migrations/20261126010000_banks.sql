-- Banks on accounts, step B.1 (docs/BANKS_PLAN.md; app 1.5.0).
--
-- An account may name the bank it belongs to: a built-in bank by key (the
-- list lives in the app) or a custom bank the space created. Presentation
-- only: no balance, total or transaction rule changes. Additive: apps 1.2.x
-- to 1.4.x never send the new fields, so their account updates keep the bank,
-- their imports leave accounts without one, and they never see custom_banks.
--
-- 1. public.custom_banks, per space like custom_account_types.
-- 2. accounts.bank_key and accounts.custom_bank_id, at most one of them set.
-- 3. bank.create, bank.update and bank.delete; account.create and
--    account.update accept bank_key and custom_bank_id.
-- 4. Sync protocol, dataset import, counts, reset and space deletion know
--    custom_banks. Import requests may leave it out.
-- Write protocol 1 is unchanged. Rollback: supabase/rollback/20261126_banks_rollback.sql.

-- 1. Custom banks ------------------------------------------------------------

-- Column order follows the other record tables (space columns last), which
-- fundly_import_dataset relies on when it names columns by position.
create table public.custom_banks (
  id uuid primary key,
  owner_id uuid references auth.users(id) on delete restrict,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revision bigint not null default 1,
  space_id uuid not null,
  created_by uuid not null,
  updated_by uuid not null,
  constraint custom_banks_space_id_key unique (space_id, id),
  constraint custom_banks_name_length check (char_length(name) between 1 and 40),
  constraint custom_banks_revision_positive check (revision > 0),
  constraint custom_banks_space_fk foreign key (space_id) references public.spaces(id) on delete restrict,
  constraint custom_banks_created_by_fk foreign key (created_by) references auth.users(id) on delete restrict,
  constraint custom_banks_updated_by_fk foreign key (updated_by) references auth.users(id) on delete restrict,
  constraint custom_banks_owner_is_personal check (owner_id is null or owner_id = space_id)
);

-- Unique per space ignoring ASCII case, like account and custom type names.
create unique index custom_banks_space_name on public.custom_banks
  (space_id, (translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') collate "C"));
create index custom_banks_owner on public.custom_banks(owner_id);

create trigger fundly_set_revision before insert or update on public.custom_banks
  for each row execute function public.fundly_set_revision();
create trigger fundly_space_bridge before insert or update on public.custom_banks
  for each row execute function fundly_private.bridge_space_owner();
create trigger fundly_record_deletion after delete on public.custom_banks
  for each row execute function fundly_private.record_deletion();

alter table public.custom_banks enable row level security;
revoke all on table public.custom_banks from public, anon, authenticated;
grant select on table public.custom_banks to authenticated;
grant all on table public.custom_banks to service_role;
create policy read_member on public.custom_banks for select to authenticated
  using (space_id in (select fundly_access.my_space_ids()));

alter table public.fundly_deleted_records drop constraint fundly_deleted_records_entity_check,
  add constraint fundly_deleted_records_entity_check check (entity in
    ('custom_account_types', 'accounts', 'categories', 'transactions', 'monthly_plans', 'custom_banks'));

-- 2. The account's bank ------------------------------------------------------

-- The key is checked for shape only; the app owns the list, so a later app can
-- add banks without a migration. An app that does not know a key shows No bank.
alter table public.accounts
  add column bank_key text,
  add column custom_bank_id uuid,
  add constraint accounts_bank_key_format check (bank_key is null or bank_key ~ '^[a-z0-9]{1,32}$'),
  add constraint accounts_one_bank check (bank_key is null or custom_bank_id is null),
  add constraint accounts_custom_bank_space_fk foreign key (space_id, custom_bank_id)
    references public.custom_banks(space_id, id) on delete restrict;
create index accounts_custom_bank on public.accounts(space_id, custom_bank_id);

-- 3. Helpers -----------------------------------------------------------------

-- Whether `value` is a built-in bank's name, ignoring ASCII case. Must match
-- the app's list (lib/features/accounts/domain/bank.dart).
create function fundly_private.builtin_bank_name(value text)
returns boolean language sql immutable strict set search_path = '' as $$
  select fundly_private.import_name_key(value) = any(array['bdo', 'bpi', 'metrobank', 'land bank', 'pnb',
    'security bank', 'unionbank', 'rcbc', 'china bank', 'eastwest', 'gcash', 'maya', 'gotyme', 'seabank',
    'cimb', 'tonik'])
$$;

-- A built-in bank key, or null for a missing or JSON null value.
create function fundly_private.bank_key(value jsonb)
returns text language plpgsql immutable set search_path = '' as $$
declare key text;
begin
  if value is null or value = 'null'::jsonb then return null; end if;
  key := fundly_private.json_text(value);
  if key !~ '^[a-z0-9]{1,32}$' then raise exception 'invalid_request' using errcode = '22023'; end if;
  return key;
end;
$$;

create function fundly_private.check_custom_bank(space uuid, bank_id uuid)
returns void language plpgsql set search_path = '' as $$
begin
  if bank_id is null then return; end if;
  perform 1 from public.custom_banks where id = bank_id and space_id = space for share;
  if not found then raise exception 'record_not_accessible' using errcode = 'P0001'; end if;
end;
$$;

-- 4. bank.create, bank.update, bank.delete -----------------------------------

-- Same rules as custom account types: a name, not a built-in bank's name,
-- unique in the space; deleted only when no account (archived included)
-- uses it.
create function fundly_private.apply_custom_bank(space uuid, item jsonb)
returns jsonb language plpgsql set search_path = '' as $$
declare
  operation text;
  record_id uuid;
  previous public.custom_banks%rowtype;
  row public.custom_banks%rowtype;
  data jsonb;
  bank_name text;
  violation text;
begin
  perform fundly_private.assert_keys(item, array['operation','id','expected_revision','data']);
  operation := fundly_private.json_text(item->'operation');
  record_id := fundly_private.json_uuid(item->'id');
  if operation = 'bank.create' then
    if item ? 'expected_revision' then raise exception 'invalid_request' using errcode = '22023'; end if;
  else
    perform fundly_private.positive_bigint(item->'expected_revision');
    select * into previous from public.custom_banks where id = record_id and space_id = space for update;
    if not found then raise exception 'record_not_accessible' using errcode = 'P0001'; end if;
    if previous.revision <> fundly_private.positive_bigint(item->'expected_revision') then
      raise exception 'revision_conflict' using errcode = 'P0001';
    end if;
  end if;

  if operation = 'bank.delete' then
    if item ? 'data' and item->'data' <> '{}'::jsonb then raise exception 'invalid_request' using errcode = '22023'; end if;
    if exists(select 1 from public.accounts where space_id = space and custom_bank_id = record_id) then
      raise exception 'custom_bank_in_use' using errcode = 'P0001';
    end if;
    delete from public.custom_banks where id = record_id and space_id = space;
    return jsonb_build_object('operation', operation, 'entity', 'custom_banks', 'id', record_id,
      'revision', previous.revision::text, 'deleted', true);
  end if;

  data := item->'data';
  perform fundly_private.assert_keys(data, array['name']);
  if not data ? 'name' then raise exception 'invalid_request' using errcode = '22023'; end if;
  bank_name := fundly_private.valid_name(data->'name');
  if fundly_private.builtin_bank_name(bank_name) then raise exception 'name_taken' using errcode = 'P0001'; end if;
  begin
    if operation = 'bank.create' then
      insert into public.custom_banks(id, space_id, name, created_at, updated_at)
      values(record_id, space, bank_name, clock_timestamp(), clock_timestamp()) returning * into row;
    else
      update public.custom_banks set name = bank_name, updated_at = clock_timestamp()
        where id = record_id and space_id = space returning * into row;
    end if;
  exception when unique_violation then
    get stacked diagnostics violation = constraint_name;
    if violation = 'custom_banks_space_name' then raise exception 'name_taken' using errcode = 'P0001'; end if;
    raise exception 'record_id_unavailable' using errcode = 'P0001';
  end;
  return jsonb_build_object('operation', operation, 'entity', 'custom_banks', 'id', row.id,
    'revision', row.revision::text, 'record', fundly_private.metadata_wire(to_jsonb(row)));
end;
$$;

-- 5. Changed functions: their current definitions with only the bank changes.

CREATE OR REPLACE FUNCTION fundly_private.item_entity(operation text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select case
    when operation like 'transaction.%' then 'transactions'
    when operation like 'custom!_type.%' escape '!' then 'custom_account_types'
    when operation like 'bank.%' then 'custom_banks'
    when operation like 'account.%' then 'accounts'
    when operation = 'plan.save' then 'monthly_plans'
    when operation like 'category.%' or operation like 'plan.%' then 'categories'
  end
$function$;

CREATE OR REPLACE FUNCTION fundly_private.apply_operation(space uuid, item jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare operation text;
begin
  perform fundly_private.assert_keys(item, array['operation','id','expected_revision','data']);
  operation := fundly_private.json_text(item->'operation');
  if operation in ('transaction.create','transaction.update','transaction.delete') then
    return fundly_private.apply_transaction(space, item);
  elsif operation in ('custom_type.create','custom_type.update','custom_type.delete') then
    return fundly_private.apply_custom_type(space, item);
  elsif operation in ('bank.create','bank.update','bank.delete') then
    return fundly_private.apply_custom_bank(space, item);
  elsif operation in ('account.create','account.update','account.set_archived','account.delete',
    'account.set_budget','account.clear_budget') then
    return fundly_private.apply_account(space, item);
  elsif operation in ('category.create','category.update','category.set_archived','category.delete') then
    return fundly_private.apply_category(space, item);
  elsif operation = 'plan.save' then
    return fundly_private.apply_plan_save(space, item);
  elsif operation in ('plan.set_archived','plan.delete_permanently') then
    return fundly_private.apply_plan_lifecycle(space, item);
  elsif operation = 'dataset.initialize' then
    return fundly_private.apply_dataset_initialize(space, item);
  end if;
  raise exception 'unsupported_operation' using errcode = 'P0001';
end;
$function$;

CREATE OR REPLACE FUNCTION fundly_private.apply_account(space uuid, item jsonb)
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
  bank text;
  custom_bank uuid;
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
    select * into previous from public.accounts where id=record_id and space_id=space for update;
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
          where id=record_id and space_id=space returning * into row;
      end if;
    else
      if not previous.is_archived then raise exception 'account_not_archived' using errcode='P0001'; end if;
      if exists(select 1 from public.transactions where space_id=space
        and (source_account_id=record_id or destination_account_id=record_id)) then
        raise exception 'account_has_transactions' using errcode='P0001';
      end if;
      -- Detach explicitly so the single category revision also has an updated audit time.
      update public.categories set linked_account_id=null,updated_at=clock_timestamp()
        where space_id=space and linked_account_id=record_id returning * into category;
      if found then changes:=jsonb_build_array(jsonb_build_object('entity','categories','id',category.id,
        'revision',category.revision::text,'record',fundly_private.metadata_wire(to_jsonb(category)))); end if;
      delete from public.accounts where id=record_id and space_id=space;
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
        where id=record_id and space_id=space returning * into row;
    end if;
  elsif operation='account.set_archived' then
    perform fundly_private.assert_keys(data,array['archived']);
    if jsonb_typeof(data->'archived') is distinct from 'boolean' then raise exception 'invalid_request' using errcode='22023'; end if;
    archived:=(data->>'archived')::boolean;
    update public.accounts set is_archived=archived,
      is_budget_account=case when archived then false else is_budget_account end,updated_at=clock_timestamp()
      where id=record_id and space_id=space returning * into row;
    changes:=fundly_private.sync_liability_category(space,row);
  else
    if operation='account.create' then
      perform fundly_private.assert_keys(data,array['name','type','entered_opening_amount_minor','currency_code','custom_type_id','linked_category_id',
        'bank_key','custom_bank_id']);
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
      perform fundly_private.assert_keys(data,array['name','entered_opening_amount_minor','custom_type_id','bank_key','custom_bank_id']);
      if data='{}'::jsonb then raise exception 'invalid_request' using errcode='22023'; end if;
      account_name:=case when data ? 'name' then fundly_private.valid_name(data->'name') else previous.name end;
      base:=previous.type;
      if data ? 'entered_opening_amount_minor' then opening:=fundly_private.nonnegative_bigint(data->'entered_opening_amount_minor');
      else opening:=previous.opening_balance_minor; end if;
      custom_id:=case when data ? 'custom_type_id' then fundly_private.json_uuid(data->'custom_type_id',true) else previous.custom_type_id end;
    end if;
    -- An account has one bank or none. The two fields are set together: when
    -- either is sent, the account's bank is exactly what is sent (a missing
    -- field is none). Apps before 1.5.0 send neither, so an update keeps it.
    if operation='account.create' or data ? 'bank_key' or data ? 'custom_bank_id' then
      bank:=fundly_private.bank_key(data->'bank_key');
      custom_bank:=fundly_private.json_uuid(data->'custom_bank_id',true);
    else
      bank:=previous.bank_key;
      custom_bank:=previous.custom_bank_id;
    end if;
    if base not in ('savingsCash','credit','loan') then raise exception 'invalid_account' using errcode='P0001'; end if;
    if bank is not null and custom_bank is not null then raise exception 'invalid_account' using errcode='P0001'; end if;
    perform fundly_private.check_custom_bank(space,custom_bank);
    perform fundly_private.check_custom_type(space,custom_id,base);
    if base<>'savingsCash' and (operation='account.create' or data ? 'entered_opening_amount_minor') then opening:=-opening; end if;
    begin
      if operation='account.create' then
        insert into public.accounts(id,space_id,name,type,opening_balance_minor,custom_type_id,bank_key,custom_bank_id,
          created_at,updated_at)
        values(record_id,space,account_name,base,opening,custom_id,bank,custom_bank,clock_timestamp(),clock_timestamp()) returning * into row;
      else
        update public.accounts set name=account_name,opening_balance_minor=opening,custom_type_id=custom_id,
          bank_key=bank,custom_bank_id=custom_bank,updated_at=clock_timestamp()
          where id=record_id and space_id=space returning * into row;
      end if;
    exception when unique_violation then
      get stacked diagnostics violation=constraint_name;
      if violation='accounts_space_name' then raise exception 'name_taken' using errcode='P0001'; end if;
      raise exception 'record_id_unavailable' using errcode='P0001';
    end;
    changes:=fundly_private.sync_liability_category(space,row,linked_id);
  end if;
  return jsonb_build_object('operation',operation,'entity','accounts','id',row.id,
    'revision',row.revision::text,'record',fundly_private.account_wire(row),'changes',changes);
end;
$function$;

CREATE OR REPLACE FUNCTION fundly_private.apply_item(space uuid, item jsonb, item_index integer)
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
    if operation in ('transaction.create', 'custom_type.create', 'account.create', 'category.create',
        'bank.create')
      or (operation = 'plan.save' and data->'previous' = 'null'::jsonb) then
      perform fundly_private.check_unretired(space, fundly_private.item_entity(operation), item->'id');
    end if;
    if operation = 'account.create' then
      perform fundly_private.check_unretired(space, 'categories', data->'linked_category_id');
    end if;
    return fundly_private.apply_operation(space, item);
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
        (5, 'custom_account_types', data->'custom_type_id'),
        (6, 'custom_banks', data->'custom_bank_id')
      ) v(rank, entity, value) order by v.rank
    loop
      if fundly_private.retired_space(candidate.entity, candidate.value) = space then
        error_message := 'record_deleted';
        detail := detail || jsonb_build_object('entity', candidate.entity,
          'deleted_id', candidate.value #>> '{}');
        exit;
      end if;
    end loop;
  elsif error_message = 'revision_conflict' then
    detail := detail || jsonb_build_object('current_revision', case fundly_private.item_entity(operation)
      when 'transactions' then (select revision::text from public.transactions
        where id = (item->>'id')::uuid and space_id = space)
      when 'custom_account_types' then (select revision::text from public.custom_account_types
        where id = (item->>'id')::uuid and space_id = space)
      when 'custom_banks' then (select revision::text from public.custom_banks
        where id = (item->>'id')::uuid and space_id = space)
      when 'accounts' then (select revision::text from public.accounts
        where id = (item->>'id')::uuid and space_id = space)
      when 'categories' then (select revision::text from public.categories
        where id = (item->>'id')::uuid and space_id = space)
    end);
  elsif error_message = 'plan_conflict' then
    detail := detail || jsonb_build_object('current', (
      select jsonb_build_object('id', p.id, 'revision', p.revision::text)
      from public.monthly_plans p
      where p.space_id = space and p.category_id = (data->>'category_id')::uuid
        and p.month = data->>'month'));
  elsif error_message = 'budget_conflict' then
    detail := detail || jsonb_build_object('current', (
      select jsonb_build_object('id', a.id, 'revision', a.revision::text)
      from public.accounts a where a.space_id = space and a.is_budget_account));
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
$function$;

CREATE OR REPLACE FUNCTION fundly_private.dataset_counts(space uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  select jsonb_build_object(
    'custom_account_types', (select count(*) from public.custom_account_types where space_id = space),
    'accounts', (select count(*) from public.accounts where space_id = space),
    'categories', (select count(*) from public.categories where space_id = space),
    'transactions', (select count(*) from public.transactions where space_id = space),
    'monthly_plans', (select count(*) from public.monthly_plans where space_id = space),
    'custom_banks', (select count(*) from public.custom_banks where space_id = space))
$function$;

CREATE OR REPLACE FUNCTION fundly_private.dataset_is_empty(space uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  select not exists(select 1 from public.custom_account_types where space_id = space)
    and not exists(select 1 from public.custom_banks where space_id = space)
    and not exists(select 1 from public.accounts where space_id = space)
    and not exists(select 1 from public.transactions where space_id = space)
    and not exists(select 1 from public.monthly_plans where space_id = space)
    and not exists(select 1 from public.categories c where c.space_id = space and (
      c.revision <> 1 or c.is_archived or c.is_plan_archived or c.is_plan_deleted
      or c.plan_group <> 'spending' or c.linked_account_id is not null
      or (c.name, c.kind) not in (values ('Rent','spending'), ('Utilities','spending'),
        ('Internet','spending'), ('Subscriptions','spending'), ('Food & Groceries','spending'),
        ('Fuel','spending'), ('Miscellaneous','spending'), ('Salary','inflow'),
        ('Other income','inflow'))))
$function$;

CREATE OR REPLACE FUNCTION public.fundly_delete_space(space_id uuid, name text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  target public.spaces;
  counts jsonb;
begin
  perform fundly_private.manage_space(fundly_delete_space.space_id, auth.uid());
  select * into target from public.spaces s where s.id = fundly_delete_space.space_id;
  if lower(fundly_private.trim_text(coalesce(name, ''))) is distinct from lower(target.name) then
    raise exception 'space_name_mismatch' using errcode = 'P0001';
  end if;
  counts := fundly_private.dataset_counts(target.id);
  delete from public.monthly_plans p where p.space_id = target.id;
  delete from public.transactions t where t.space_id = target.id;
  delete from public.categories c where c.space_id = target.id;
  delete from public.accounts a where a.space_id = target.id;
  delete from public.custom_account_types t where t.space_id = target.id;
  delete from public.custom_banks b where b.space_id = target.id;
  delete from public.space_members m where m.space_id = target.id;
  delete from public.spaces s where s.id = target.id;
  return jsonb_build_object('space_id', target.id, 'deleted', counts);
end;
$function$;

CREATE OR REPLACE FUNCTION public.fundly_import_dataset(import_id uuid, request jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  actor uuid := auth.uid();
  space uuid;
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
  banks public.custom_banks[] := '{}'::public.custom_banks[];
  t public.custom_account_types;
  a public.accounts;
  c public.categories;
  x public.transactions;
  p public.monthly_plans;
  b public.custom_banks;
begin
  if actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  -- 1. Size and envelope shape, before any work.
  if import_id is null or octet_length(request::text) > 8388608 then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  perform fundly_private.assert_keys(request, array['version','mode','expected','dataset','space_id']);
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
      'categories','transactions','monthly_plans','custom_banks']);
    -- custom_banks is optional: apps before 1.5.0 never send it.
    if not expected ?& array['custom_account_types','accounts','categories','transactions','monthly_plans']
      or exists(select 1 from jsonb_each(expected) e
        where not (jsonb_typeof(e.value) = 'number' and e.value::text ~ '^(0|[1-9][0-9]{0,9})$')) then
      raise exception 'invalid_request' using errcode = '22023';
    end if;
  elsif import_mode = 'replace' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  dataset := request->'dataset';
  perform fundly_private.assert_keys(dataset, array['custom_account_types','accounts',
    'categories','transactions','monthly_plans','custom_banks']);
  if not dataset ?& array['custom_account_types','accounts','categories','transactions','monthly_plans']
    or exists(select 1 from jsonb_each(dataset) e where jsonb_typeof(e.value) <> 'array') then
    raise exception 'invalid_request' using errcode = '22023';
  end if;

  -- 2-3. Serialize with uploads, then answer a retry from its receipt.
  space := fundly_private.request_space(actor, request);
  fingerprint := sha256(convert_to(request::text, 'UTF8'));
  perform pg_advisory_xact_lock(hashtextextended('fundly:' || space::text, 0));
  select * into receipt from public.fundly_import_receipts r
    where r.owner_id = actor and r.import_id = fundly_import_dataset.import_id;
  if found then
    if receipt.request_fingerprint <> fingerprint then
      raise exception 'import_key_reused' using errcode = 'P0001';
    end if;
    return receipt.result;
  end if;
  -- Importing or replacing a whole space is for its owners.
  perform fundly_private.require_writer(space, actor, owner_only => true);

  -- 4. The account must still be what the user confirmed.
  current_counts := fundly_private.dataset_counts(space);
  if import_mode = 'into_empty' and not fundly_private.dataset_is_empty(space) then
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
      t.space_id := space;
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

    entity := 'custom_banks';
    for item, at_index in select e.value, (e.ordinality - 1)::integer
        from jsonb_array_elements(coalesce(dataset->entity, '[]'::jsonb)) with ordinality e loop
      field := null;
      perform fundly_private.import_keys(entity, at_index, item,
        array['id','name'], array['created_at','updated_at']);
      b := null;
      b.space_id := space;
      b.revision := 1;
      field := 'id'; b.id := fundly_private.json_uuid(item->'id');
      field := 'name'; b.name := fundly_private.json_text(item->'name');
      field := 'created_at'; b.created_at := coalesce(fundly_private.utc_timestamp(item->'created_at'), now());
      field := 'updated_at'; b.updated_at := coalesce(fundly_private.utc_timestamp(item->'updated_at'), b.created_at);
      if not fundly_private.import_name_valid(b.name) then
        perform fundly_private.import_fail(entity, at_index, 'name', 'invalid_name');
      end if;
      if fundly_private.builtin_bank_name(b.name) then
        perform fundly_private.import_fail(entity, at_index, 'name', 'name_taken');
      end if;
      banks[at_index + 1] := b;
    end loop;

    entity := 'accounts';
    for item, at_index in select e.value, (e.ordinality - 1)::integer
        from jsonb_array_elements(dataset->entity) with ordinality e loop
      field := null;
      perform fundly_private.import_keys(entity, at_index, item,
        array['id','name','type','opening_balance_minor','currency_code','is_archived',
          'custom_type_id','is_budget_account'], array['created_at','updated_at','bank_key','custom_bank_id']);
      a := null;
      a.space_id := space;
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
      field := 'bank_key'; a.bank_key := fundly_private.bank_key(item->'bank_key');
      field := 'custom_bank_id'; a.custom_bank_id := fundly_private.json_uuid(item->'custom_bank_id', true);
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
      if a.bank_key is not null and a.custom_bank_id is not null then
        perform fundly_private.import_fail(entity, at_index, 'custom_bank_id', 'invalid_value');
      end if;
      accounts[at_index + 1] := a;
    end loop;

    entity := 'categories';
    for item, at_index in select e.value, (e.ordinality - 1)::integer
        from jsonb_array_elements(dataset->entity) with ordinality e loop
      field := null;
      perform fundly_private.import_keys(entity, at_index, item,
        array['id','name','kind','is_archived','is_plan_archived','is_plan_deleted','plan_group',
          'linked_account_id'], array['created_at','updated_at','default_target_minor']);
      c := null;
      c.space_id := space;
      c.revision := 1;
      field := 'id'; c.id := fundly_private.json_uuid(item->'id');
      field := 'name'; c.name := fundly_private.json_text(item->'name');
      field := 'kind'; c.kind := fundly_private.json_text(item->'kind');
      field := 'is_archived'; c.is_archived := fundly_private.json_boolean(item->'is_archived');
      field := 'is_plan_archived'; c.is_plan_archived := fundly_private.json_boolean(item->'is_plan_archived');
      field := 'is_plan_deleted'; c.is_plan_deleted := fundly_private.json_boolean(item->'is_plan_deleted');
      field := 'plan_group'; c.plan_group := fundly_private.json_text(item->'plan_group');
      field := 'linked_account_id'; c.linked_account_id := fundly_private.json_uuid(item->'linked_account_id', true);
      field := 'default_target_minor';
      c.default_target_minor := case when coalesce(item->'default_target_minor', 'null'::jsonb) = 'null'::jsonb
        then null else fundly_private.nonnegative_bigint(item->'default_target_minor') end;
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
      if c.default_target_minor is not null
        and (c.kind <> 'spending' or c.linked_account_id is not null) then
        perform fundly_private.import_fail(entity, at_index, 'default_target_minor', 'invalid_value');
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
      x.space_id := space;
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
      p.space_id := space;
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
      select n, row_number() over (partition by id order by n) k from unnest(banks) with ordinality u(id, owner_id, name, created_at, updated_at, revision, space_id, created_by, updated_by, n)
    ) r where r.k > 1), 'custom_banks', 'id', 'duplicate_id');
  perform fundly_private.import_check((select min(r.n) from (
      select n, row_number() over (partition by fundly_private.import_name_key(u.name) order by n) k
      from unnest(banks) with ordinality u(id, owner_id, name, created_at, updated_at, revision, space_id, created_by, updated_by, n)
    ) r where r.k > 1), 'custom_banks', 'name', 'name_taken');

  perform fundly_private.import_check((select min(r.n) from (
      select u.n, row_number() over (partition by u.id order by u.n) k
      from unnest(accounts) with ordinality u(id, owner_id, name, type, opening_balance_minor, currency_code,
        is_archived, custom_type_id, is_budget_account, created_at, updated_at, revision, space_id, created_by, updated_by, bank_key, custom_bank_id, n)
    ) r where r.k > 1), 'accounts', 'id', 'duplicate_id');
  perform fundly_private.import_check((select min(r.n) from (
      select u.n, row_number() over (partition by fundly_private.import_name_key(u.name) order by u.n) k
      from unnest(accounts) with ordinality u(id, owner_id, name, type, opening_balance_minor, currency_code,
        is_archived, custom_type_id, is_budget_account, created_at, updated_at, revision, space_id, created_by, updated_by, bank_key, custom_bank_id, n)
    ) r where r.k > 1), 'accounts', 'name', 'name_taken');
  perform fundly_private.import_check((select min(u.n)
      from unnest(accounts) with ordinality u(id, owner_id, name, type, opening_balance_minor, currency_code,
        is_archived, custom_type_id, is_budget_account, created_at, updated_at, revision, space_id, created_by, updated_by, bank_key, custom_bank_id, n)
      where u.custom_type_id is not null and not exists(select 1 from unnest(types) ct
        where ct.id = u.custom_type_id and ct.base_type = u.type)),
    'accounts', 'custom_type_id', 'invalid_reference');
  perform fundly_private.import_check((select min(u.n)
      from unnest(accounts) with ordinality u(id, owner_id, name, type, opening_balance_minor, currency_code,
        is_archived, custom_type_id, is_budget_account, created_at, updated_at, revision, space_id, created_by, updated_by,
        bank_key, custom_bank_id, n)
      where u.custom_bank_id is not null and not exists(select 1 from unnest(banks) bk
        where bk.id = u.custom_bank_id)),
    'accounts', 'custom_bank_id', 'invalid_reference');

  perform fundly_private.import_check((select min(r.n) from (
      select u.n, row_number() over (partition by u.id order by u.n) k
      from unnest(categories) with ordinality u(id, owner_id, name, kind, is_archived, is_plan_archived,
        is_plan_deleted, plan_group, linked_account_id, created_at, updated_at, revision, space_id, created_by, updated_by, default_target_minor, n)
    ) r where r.k > 1), 'categories', 'id', 'duplicate_id');
  perform fundly_private.import_check((select min(r.n) from (
      select u.n, row_number() over (partition by fundly_private.import_name_key(u.name) order by u.n) k
      from unnest(categories) with ordinality u(id, owner_id, name, kind, is_archived, is_plan_archived,
        is_plan_deleted, plan_group, linked_account_id, created_at, updated_at, revision, space_id, created_by, updated_by, default_target_minor, n)
    ) r where r.k > 1), 'categories', 'name', 'name_taken');
  -- A linked Plans row belongs to one liability account and follows its archive status.
  perform fundly_private.import_check((select min(r.n) from (
      select u.n, u.kind, u.plan_group, u.is_archived, ac.type, ac.is_archived as account_archived,
        row_number() over (partition by u.linked_account_id order by u.n) k
      from unnest(categories) with ordinality u(id, owner_id, name, kind, is_archived, is_plan_archived,
        is_plan_deleted, plan_group, linked_account_id, created_at, updated_at, revision, space_id, created_by, updated_by, default_target_minor, n)
      left join unnest(accounts) ac on ac.id = u.linked_account_id
      where u.linked_account_id is not null
    ) r where r.k > 1 or r.type is null or r.type = 'savingsCash' or r.kind <> 'spending'
      or r.plan_group <> 'liability' or r.is_archived <> r.account_archived),
    'categories', 'linked_account_id', 'invalid_link');
  perform fundly_private.import_check((select min(u.n)
      from unnest(accounts) with ordinality u(id, owner_id, name, type, opening_balance_minor, currency_code,
        is_archived, custom_type_id, is_budget_account, created_at, updated_at, revision, space_id, created_by, updated_by, bank_key, custom_bank_id, n)
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
      union all select 'custom_banks', u.n from unnest(banks) with ordinality u(id, owner_id, name, created_at, updated_at, revision, space_id, created_by, updated_by, n)
        where exists(select 1 from public.custom_banks r where r.id = u.id)
      union all select 'accounts', u.n from unnest(accounts) with ordinality u(id, owner_id, name, type,
        opening_balance_minor, currency_code, is_archived, custom_type_id, is_budget_account, created_at,
        updated_at, revision, space_id, created_by, updated_by, bank_key, custom_bank_id, n) where exists(select 1 from public.accounts r where r.id = u.id)
      union all select 'categories', u.n from unnest(categories) with ordinality u(id, owner_id, name, kind,
        is_archived, is_plan_archived, is_plan_deleted, plan_group, linked_account_id, created_at, updated_at,
        revision, space_id, created_by, updated_by, default_target_minor, n) where exists(select 1 from public.categories r where r.id = u.id)
      union all select 'transactions', u.n from unnest(transactions) with ordinality u(id, owner_id, type,
        amount_minor, currency_code, date, payee, category_id, source_account_id, destination_account_id, note,
        created_at, updated_at, revision, space_id, created_by, updated_by, n) where exists(select 1 from public.transactions r where r.id = u.id)
      union all select 'monthly_plans', u.n from unnest(plans) with ordinality u(id, owner_id, month,
        category_id, target_amount_minor, assigned_amount_minor, currency_code, created_at, updated_at,
        revision, space_id, created_by, updated_by, n) where exists(select 1 from public.monthly_plans r where r.id = u.id)
      union all select d.entity, u.n from (
          select 'custom_account_types' entity, t2.id, t2.n from unnest(types) with ordinality t2(id, o, nm, b,
            ca, ua, rv, sp, cb, ub, n)
          union all select 'custom_banks', b2.id, b2.n from unnest(banks) with ordinality b2(id, o, nm,
            ca, ua, rv, sp, cb, ub, n)
          union all select 'accounts', a2.id, a2.n from unnest(accounts) with ordinality a2(id, o, nm, ty, ob,
            cc, ar, ct, bu, ca, ua, rv, sp, cb, ub, bank_key, custom_bank_id, n)
          union all select 'categories', c2.id, c2.n from unnest(categories) with ordinality c2(id, o, nm, k, ar,
            pa, pd, pg, la, ca, ua, rv, sp, cb, ub, dtm, n)
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
  delete from public.monthly_plans where space_id = space;
  delete from public.transactions where space_id = space;
  delete from public.categories where space_id = space;
  delete from public.accounts where space_id = space;
  delete from public.custom_account_types where space_id = space;
  delete from public.custom_banks where space_id = space;

  -- 8. Insert in reference order; the revision trigger sets revision 1.
  begin
    insert into public.custom_account_types select * from unnest(types);
    insert into public.custom_banks select * from unnest(banks);
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
      'custom_account_types', cardinality(types), 'custom_banks', cardinality(banks),
      'accounts', cardinality(accounts),
      'categories', cardinality(categories), 'transactions', cardinality(transactions),
      'monthly_plans', cardinality(plans)));
  insert into public.fundly_import_receipts(owner_id, space_id, import_id, request_fingerprint, mode, result)
    values(actor, space, import_id, fingerprint, import_mode, response);
  return response;
end;
$function$;

-- 6. Replication ---------------------------------------------------------------

-- The PowerSync replication role (its name is per instance) reads custom_banks
-- like the other record tables. Publish it with powersync/publication.sql.
do $$
declare replication_role text;
begin
  for replication_role in select rolname from pg_catalog.pg_roles
      where rolname like 'powersync\_%' and rolreplication loop
    execute format('grant select on public.custom_banks to %I', replication_role);
  end loop;
end;
$$;

revoke all on all functions in schema fundly_private from public, anon, authenticated, service_role;
