-- Shared spaces C1.2 (docs/SHARED_SPACES_C1_PLAN.md): the write API works per
-- space. Every private function takes the target space instead of the actor
-- (a mechanical rename of each current definition: actor -> space, owner_id ->
-- space_id), and the two RPCs resolve the space and check the caller's role.
-- Write protocol 1 is unchanged: without `space_id` a request goes to the
-- caller's Personal space, exactly as every app sends today.
--
-- Refusals use P0001 with a message, which apps 1.2.x log in Refused changes
-- and move past; 42501 would block their queue (SYNC_PROTOCOL.md):
--   not_space_member  the caller is not (or no longer) a member
--   space_read_only   the caller is a viewer
--   space_owner_only  import or replace by a non-owner

-- The member's role in a space, or null.
create function fundly_private.space_role(space uuid, member uuid)
returns text language sql stable set search_path = '' as $$
  select m.role from public.space_members m where m.space_id = space and m.user_id = member
$$;

-- Who wrote a record: the RPCs set fundly.actor for their transaction, and
-- this trigger stamps it. Writes outside the RPCs (maintenance) keep the
-- C1.1 behaviour: the space's user on insert, unchanged on update.
create or replace function fundly_private.bridge_space_owner()
returns trigger language plpgsql security definer set search_path = '' as $$
declare writer uuid := nullif(current_setting('fundly.actor', true), '')::uuid;
begin
  if tg_op = 'INSERT' then
    new.space_id := coalesce(new.space_id, new.owner_id);
    new.owner_id := coalesce(new.owner_id, new.space_id);
    new.created_by := coalesce(new.created_by, writer, new.owner_id);
    new.updated_by := coalesce(new.updated_by, new.created_by);
    if new.space_id = new.owner_id then
      perform fundly_private.ensure_personal_space(new.owner_id);
    end if;
  else
    new.updated_by := coalesce(writer, new.updated_by);
  end if;
  return new;
end;
$$;

do $$
declare table_name text;
begin
  foreach table_name in array array[
    'custom_account_types', 'accounts', 'categories', 'transactions', 'monthly_plans'
  ] loop
    execute format('drop trigger fundly_space_bridge on public.%I', table_name);
    execute format('create trigger fundly_space_bridge before insert or update on public.%I
      for each row execute function fundly_private.bridge_space_owner()', table_name);
  end loop;
end;
$$;

-- The target space of a request: its `space_id`, or the caller's Personal
-- space, whose id is the caller's. No side effects: the RPCs take the space's
-- write lock first, then create a missing Personal space under it.
create function fundly_private.request_space(actor uuid, request jsonb)
returns uuid language plpgsql immutable set search_path = '' as $$
begin
  if request ? 'space_id' then
    return fundly_private.json_uuid(request->'space_id');
  end if;
  return actor;
end;
$$;

-- Called under the space's write lock. Creates the caller's Personal space
-- on first use, then refuses unless the actor may write (owner, editor) or,
-- with owner_only, is an owner. Then records the actor for attribution.
create function fundly_private.require_writer(space uuid, actor uuid, owner_only boolean default false)
returns void language plpgsql set search_path = '' as $$
declare member_role text;
begin
  if space = actor then
    perform fundly_private.ensure_personal_space(actor);
  end if;
  member_role := fundly_private.space_role(space, actor);
  if member_role is null then
    raise exception 'not_space_member' using errcode = 'P0001';
  elsif member_role = 'viewer' then
    raise exception 'space_read_only' using errcode = 'P0001';
  elsif owner_only and member_role <> 'owner' then
    raise exception 'space_owner_only' using errcode = 'P0001';
  end if;
  perform set_config('fundly.actor', actor::text, true);
end;
$$;

-- Old (actor) signatures go first: a parameter cannot be renamed in place.
drop function fundly_private.retired_owner(text, jsonb);
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

-- The space a retired UUID belonged to, or null when the value is not one.
CREATE OR REPLACE FUNCTION fundly_private.retired_space(entity text, value jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare owner_space uuid;
begin
  if jsonb_typeof(value) is distinct from 'string'
    or (value #>> '{}') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    return null;
  end if;
  select d.space_id into owner_space from public.fundly_deleted_records d
    where d.entity = retired_space.entity and d.id = (value #>> '{}')::uuid;
  return owner_space;
end;
$function$;

-- A create may not reuse a retired UUID; another space's learns nothing.
CREATE OR REPLACE FUNCTION fundly_private.check_unretired(space uuid, entity text, value jsonb)
 RETURNS void
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare owner_space uuid;
begin
  owner_space := fundly_private.retired_space(entity, value);
  if owner_space = space then
    raise exception 'record_deleted' using errcode = 'P0001',
      detail = jsonb_build_object('entity', entity, 'deleted_id', value #>> '{}')::text;
  elsif owner_space is not null then
    raise exception 'record_id_unavailable' using errcode = 'P0001';
  end if;
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
    'monthly_plans', (select count(*) from public.monthly_plans where space_id = space))
$function$;

CREATE OR REPLACE FUNCTION fundly_private.dataset_is_empty(space uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  select not exists(select 1 from public.custom_account_types where space_id = space)
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

CREATE OR REPLACE FUNCTION fundly_private.check_custom_type(space uuid, type_id uuid, base text)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare row public.custom_account_types%rowtype;
begin
  if type_id is null then return; end if;
  select * into row from public.custom_account_types where id=type_id and space_id=space for share;
  if not found then raise exception 'record_not_accessible' using errcode='P0001'; end if;
  if row.base_type <> base then raise exception 'invalid_account' using errcode='P0001'; end if;
end;
$function$;

CREATE OR REPLACE FUNCTION fundly_private.sync_liability_category(space uuid, account accounts, requested_id uuid DEFAULT NULL::uuid)
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
    where space_id=space and linked_account_id=account.id for update;
  if row.id is null and account.is_archived then return '[]'::jsonb; end if;
  if requested_id is not null and row.id is not null and requested_id <> row.id then
    raise exception 'record_id_unavailable' using errcode='P0001';
  end if;
  while exists(select 1 from public.categories c where c.space_id=space and c.id is distinct from row.id
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
      insert into public.categories(id,space_id,name,kind,plan_group,linked_account_id,is_archived,created_at,updated_at)
      values(coalesce(requested_id,gen_random_uuid()),space,desired_name,'spending','liability',account.id,
        account.is_archived,clock_timestamp(),clock_timestamp()) returning * into row;
    exception when unique_violation then
      raise exception 'record_id_unavailable' using errcode='P0001';
    end;
  elsif row.name is distinct from desired_name or row.is_archived is distinct from account.is_archived then
    -- Preserve independent plan archive/deletion flags, history and assignments.
    update public.categories set name=desired_name,is_archived=account.is_archived,
      updated_at=clock_timestamp() where id=row.id and space_id=space returning * into row;
  else
    return '[]'::jsonb;
  end if;
  return jsonb_build_array(jsonb_build_object('entity','categories','id',row.id,
    'revision',row.revision::text,'record',fundly_private.metadata_wire(to_jsonb(row))));
end;
$function$;

CREATE OR REPLACE FUNCTION fundly_private.remaining_allocations(space uuid, target_category uuid, linked_account uuid, from_month text)
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
        and b.space_id = space and b.is_budget_account
      where t.space_id = space
        and t.date >= to_date(p.month || '-01', 'YYYY-MM-DD')
        and t.date < (to_date(p.month || '-01', 'YYYY-MM-DD') + interval '1 month')
        and case when linked_account is null
          then t.type = 'spending' and t.category_id = target_category
          else t.type in ('transfer', 'creditCardPayment')
            and t.destination_account_id = linked_account end
    ), 0) as amount
    from public.monthly_plans p
    where p.space_id = space and p.category_id = target_category and p.month >= from_month
  )
  select coalesce(jsonb_agg(jsonb_build_object('month', month, 'remaining_minor', amount::text)
    order by month), '[]'::jsonb)
  from remaining where amount > 0
$function$;

CREATE OR REPLACE FUNCTION fundly_private.delete_category_plans(space uuid, target_category uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare changes jsonb;
begin
  with gone as (
    delete from public.monthly_plans
    where space_id = space and category_id = target_category returning *
  )
  select coalesce(jsonb_agg(jsonb_build_object('entity', 'monthly_plans', 'id', id,
    'revision', revision::text, 'deleted', true) order by month), '[]'::jsonb)
  into changes from gone;
  return changes;
end;
$function$;

CREATE OR REPLACE FUNCTION fundly_private.apply_transaction(space uuid, item jsonb)
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
      where id = record_id and space_id = space for update;
    if not found then raise exception 'record_not_accessible' using errcode = 'P0001'; end if;
    if previous.revision <> expected then
      raise exception 'revision_conflict' using errcode = 'P0001';
    end if;
  end if;

  if operation = 'transaction.delete' then
    if item ? 'data' and item->'data' <> '{}'::jsonb then
      raise exception 'invalid_request' using errcode = '22023';
    end if;
    delete from public.transactions where id = record_id and space_id = space;
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
  candidate.space_id := space;
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
      where id = candidate.source_account_id and space_id = space for share;
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
      where id = candidate.destination_account_id and space_id = space for share;
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
      where id = candidate.category_id and space_id = space for share;
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
      insert into public.transactions(id, space_id, type, amount_minor, currency_code,
        date, payee, note, category_id, source_account_id, destination_account_id, created_at, updated_at)
      values(record_id, space, candidate.type, candidate.amount_minor, candidate.currency_code,
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
      where id = record_id and space_id = space returning * into candidate;
  end if;
  return jsonb_build_object('operation', operation, 'id', record_id,
    'revision', candidate.revision::text, 'record', fundly_private.transaction_wire(candidate));
end;
$function$;

CREATE OR REPLACE FUNCTION fundly_private.apply_custom_type(space uuid, item jsonb)
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
    select * into previous from public.custom_account_types where id=record_id and space_id=space for update;
    if not found then raise exception 'record_not_accessible' using errcode='P0001'; end if;
    if previous.revision <> fundly_private.positive_bigint(item->'expected_revision') then
      raise exception 'revision_conflict' using errcode='P0001';
    end if;
  end if;
  if operation='custom_type.delete' then
    if item ? 'data' and item->'data' <> '{}'::jsonb then raise exception 'invalid_request' using errcode='22023'; end if;
    if exists(select 1 from public.accounts where space_id=space and custom_type_id=record_id) then
      raise exception 'custom_type_in_use' using errcode='P0001';
    end if;
    delete from public.custom_account_types where id=record_id and space_id=space;
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
    exists(select 1 from public.accounts where space_id=space and custom_type_id=record_id) then
    raise exception 'custom_type_in_use' using errcode='P0001';
  end if;
  begin
    if operation='custom_type.create' then
      insert into public.custom_account_types(id,space_id,name,base_type,created_at,updated_at)
      values(record_id,space,type_name,base,clock_timestamp(),clock_timestamp()) returning * into row;
    else
      update public.custom_account_types set name=type_name,base_type=base,updated_at=clock_timestamp()
        where id=record_id and space_id=space returning * into row;
    end if;
  exception when unique_violation then
    get stacked diagnostics violation=constraint_name;
    if violation='custom_account_types_space_name' then raise exception 'name_taken' using errcode='P0001'; end if;
    raise exception 'record_id_unavailable' using errcode='P0001';
  end;
  return jsonb_build_object('operation',operation,'entity','custom_account_types','id',row.id,
    'revision',row.revision::text,'record',fundly_private.metadata_wire(to_jsonb(row)));
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
    perform fundly_private.check_custom_type(space,custom_id,base);
    if base<>'savingsCash' and (operation='account.create' or data ? 'entered_opening_amount_minor') then opening:=-opening; end if;
    begin
      if operation='account.create' then
        insert into public.accounts(id,space_id,name,type,opening_balance_minor,custom_type_id,created_at,updated_at)
        values(record_id,space,account_name,base,opening,custom_id,clock_timestamp(),clock_timestamp()) returning * into row;
      else
        update public.accounts set name=account_name,opening_balance_minor=opening,custom_type_id=custom_id,updated_at=clock_timestamp()
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

CREATE OR REPLACE FUNCTION fundly_private.apply_category(space uuid, item jsonb)
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
      where id = record_id and space_id = space for update;
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
    if exists(select 1 from public.transactions where space_id = space and category_id = record_id) then
      raise exception 'category_in_use' using errcode = 'P0001';
    end if;
    changes := fundly_private.delete_category_plans(space, record_id);
    delete from public.categories where id = record_id and space_id = space;
    return jsonb_build_object('operation', operation, 'entity', 'categories', 'id', record_id,
      'revision', previous.revision::text, 'deleted', true, 'changes', changes);
  end if;

  if operation = 'category.set_archived' then
    perform fundly_private.assert_keys(data, array['archived']);
    if jsonb_typeof(data->'archived') is distinct from 'boolean' then
      raise exception 'invalid_request' using errcode = '22023';
    end if;
    update public.categories set is_archived = (data->>'archived')::boolean, updated_at = clock_timestamp()
      where id = record_id and space_id = space returning * into row;
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
        insert into public.categories(id, space_id, name, kind, plan_group, created_at, updated_at)
        values(record_id, space, category_name, category_kind, group_name, clock_timestamp(), clock_timestamp())
        returning * into row;
      else
        update public.categories set name = category_name, plan_group = group_name, updated_at = clock_timestamp()
          where id = record_id and space_id = space returning * into row;
      end if;
    exception when unique_violation then
      get stacked diagnostics violation = constraint_name;
      if violation = 'categories_space_name' then raise exception 'name_taken' using errcode = 'P0001'; end if;
      raise exception 'record_id_unavailable' using errcode = 'P0001';
    end;
  end if;
  return jsonb_build_object('operation', operation, 'entity', 'categories', 'id', row.id,
    'revision', row.revision::text, 'record', fundly_private.category_wire(row), 'changes', changes);
end;
$function$;

CREATE OR REPLACE FUNCTION fundly_private.apply_plan_save(space uuid, item jsonb)
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
    where c.id = plan_category and c.space_id = space for share;
  if not found then raise exception 'record_not_accessible' using errcode = 'P0001'; end if;
  if category.kind <> 'spending' then raise exception 'category_not_spending' using errcode = 'P0001'; end if;
  if category.is_plan_deleted then raise exception 'plan_deleted' using errcode = 'P0001'; end if;
  if category.is_plan_archived then raise exception 'plan_archived' using errcode = 'P0001'; end if;

  select * into existing from public.monthly_plans p
    where p.space_id = space and p.category_id = category.id and p.month = plan_month for update;
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
    delete from public.monthly_plans where id = existing.id and space_id = space;
    return jsonb_build_object('operation', 'plan.save', 'entity', 'monthly_plans', 'id', existing.id,
      'revision', existing.revision::text, 'deleted', true, 'changes', '[]'::jsonb);
  end if;

  if existing.id is not null then
    update public.monthly_plans set target_amount_minor = target, assigned_amount_minor = assigned,
      updated_at = clock_timestamp()
      where id = existing.id and space_id = space returning * into row;
  else
    -- An archived category may keep editing an existing plan, not gain a new one.
    if category.is_archived then raise exception 'category_archived' using errcode = 'P0001'; end if;
    begin
      insert into public.monthly_plans(id, space_id, month, category_id, target_amount_minor,
        assigned_amount_minor, created_at, updated_at)
      values(record_id, space, plan_month, category.id, target, assigned, clock_timestamp(), clock_timestamp())
      returning * into row;
    exception when unique_violation then
      raise exception 'record_id_unavailable' using errcode = 'P0001';
    end;
  end if;
  return jsonb_build_object('operation', 'plan.save', 'entity', 'monthly_plans', 'id', row.id,
    'revision', row.revision::text, 'record', fundly_private.plan_wire(row), 'changes', '[]'::jsonb);
end;
$function$;

CREATE OR REPLACE FUNCTION fundly_private.apply_plan_lifecycle(space uuid, item jsonb)
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
    where id = record_id and space_id = space for update;
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
        blocked := fundly_private.remaining_allocations(space, previous.id, previous.linked_account_id,
          fundly_private.local_month(zone, clock_timestamp()));
        if blocked <> '[]'::jsonb then
          raise exception 'plan_allocation_remaining' using errcode = 'P0001',
            detail = jsonb_build_object('months', blocked)::text;
        end if;
      end if;
      update public.categories set is_plan_archived = archived, updated_at = clock_timestamp()
        where id = record_id and space_id = space returning * into row;
    end if;
  else
    if item ? 'data' and data <> '{}'::jsonb then raise exception 'invalid_request' using errcode = '22023'; end if;
    reason := case
      when previous.kind <> 'spending' then 'category_not_spending'
      when previous.is_plan_deleted then 'already_deleted'
      when not previous.is_archived and not previous.is_plan_archived then 'not_archived'
      when exists(select 1 from public.monthly_plans p where p.space_id = space
        and p.category_id = record_id and p.assigned_amount_minor <> 0) then 'has_assigned_money'
      when exists(select 1 from public.transactions t where t.space_id = space and (
        (previous.linked_account_id is null and t.type = 'spending' and t.category_id = record_id)
        or (previous.linked_account_id is not null and t.type in ('transfer','creditCardPayment')
          and t.destination_account_id = previous.linked_account_id))) then 'has_activity'
    end;
    if reason is not null then
      raise exception 'plan_delete_blocked' using errcode = 'P0001',
        detail = jsonb_build_object('reason', reason)::text;
    end if;
    changes := fundly_private.delete_category_plans(space, record_id);
    update public.categories set is_plan_archived = true, is_plan_deleted = true, updated_at = clock_timestamp()
      where id = record_id and space_id = space returning * into row;
  end if;
  return jsonb_build_object('operation', operation, 'entity', 'categories', 'id', row.id,
    'revision', row.revision::text, 'record', fundly_private.category_wire(row), 'changes', changes);
end;
$function$;

CREATE OR REPLACE FUNCTION fundly_private.apply_dataset_initialize(space uuid, item jsonb)
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
  if not exists(select 1 from public.categories where space_id = space) then
    for n in 1 .. array_length(defaults, 1) loop
      -- One clock reading per row keeps creation order equal to list order.
      insert into public.categories(id, space_id, name, kind, created_at, updated_at)
      values(gen_random_uuid(), space, defaults[n][1], defaults[n][2],
        clock_timestamp(), clock_timestamp())
      returning * into row;
      changes := changes || jsonb_build_array(jsonb_build_object('entity', 'categories',
        'id', row.id, 'revision', row.revision::text, 'record', fundly_private.category_wire(row)));
    end loop;
  end if;
  return jsonb_build_object('operation', 'dataset.initialize', 'initialized', jsonb_array_length(changes) > 0,
    'changes', changes);
end;
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
    if operation in ('transaction.create', 'custom_type.create', 'account.create', 'category.create')
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
        (5, 'custom_account_types', data->'custom_type_id')
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

-- The two RPCs: their current definitions with the space resolved, the role
-- checked after the receipt lookup, the lock and every record filter on the
-- space, and receipts still keyed by the sender (owner_id) with the space.
CREATE OR REPLACE FUNCTION public.fundly_apply_operations(batch_id uuid, operations jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  actor uuid := auth.uid();
  space uuid;
  fingerprint bytea;
  receipt public.fundly_write_receipts%rowtype;
  results jsonb := '[]'::jsonb;
  item jsonb;
  item_index integer;
  response jsonb;
begin
  if actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  if batch_id is null then raise exception 'invalid_request' using errcode = '22023'; end if;
  perform fundly_private.assert_keys(operations, array['version','items','space_id']);
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
  space := fundly_private.request_space(actor, operations);
  fingerprint := sha256(convert_to(operations::text, 'UTF8'));
  -- Writes to a space are serialized; for a Personal space this is the same
  -- key as before C1 (its id is the user's).
  perform pg_advisory_xact_lock(hashtextextended('fundly:' || space::text, 0));
  select * into receipt from public.fundly_write_receipts r
    where r.owner_id = actor and r.batch_id = fundly_apply_operations.batch_id;
  if found then
    if receipt.request_fingerprint <> fingerprint then
      raise exception 'batch_key_reused' using errcode = 'P0001';
    end if;
    return receipt.result;
  end if;
  -- After the receipt: a batch applied before a membership ended still
  -- answers from its receipt.
  perform fundly_private.require_writer(space, actor);
  for item, item_index in
    select e.value, (e.ordinality - 1)::integer
    from jsonb_array_elements(operations->'items') with ordinality e
  loop
    results := results || jsonb_build_array(fundly_private.apply_item(space, item, item_index));
  end loop;
  response := jsonb_build_object('version', 1, 'batch_id', batch_id, 'results', results);
  insert into public.fundly_write_receipts(owner_id, space_id, batch_id, request_fingerprint, protocol_version, result)
    values(actor, space, batch_id, fingerprint, 1, response);
  return response;
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

    entity := 'accounts';
    for item, at_index in select e.value, (e.ordinality - 1)::integer
        from jsonb_array_elements(dataset->entity) with ordinality e loop
      field := null;
      perform fundly_private.import_keys(entity, at_index, item,
        array['id','name','type','opening_balance_minor','currency_code','is_archived',
          'custom_type_id','is_budget_account'], array['created_at','updated_at']);
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
  delete from public.monthly_plans where space_id = space;
  delete from public.transactions where space_id = space;
  delete from public.categories where space_id = space;
  delete from public.accounts where space_id = space;
  delete from public.custom_account_types where space_id = space;

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
  insert into public.fundly_import_receipts(owner_id, space_id, import_id, request_fingerprint, mode, result)
    values(actor, space, import_id, fingerprint, import_mode, response);
  return response;
end;
$function$;

revoke all on all functions in schema fundly_private from public, anon, authenticated, service_role;
