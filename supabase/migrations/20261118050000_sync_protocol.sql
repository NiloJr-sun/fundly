-- S2.3: permanent retirement of deleted UUIDs and structured rejection details.
-- Rejections still raise and roll back the whole batch; no rejection receipt.

-- Backend-only, like receipts: identity only, no names, amounts or notes.
create table public.fundly_deleted_records (
  entity text not null check (entity in
    ('custom_account_types', 'accounts', 'categories', 'transactions', 'monthly_plans')),
  id uuid not null,
  owner_id uuid not null references auth.users(id) on delete restrict,
  revision bigint not null check (revision > 0),
  deleted_at timestamptz not null default clock_timestamp(),
  primary key (entity, id)
);
create index fundly_deleted_records_owner on public.fundly_deleted_records(owner_id);
alter table public.fundly_deleted_records enable row level security;
revoke all on public.fundly_deleted_records from public, anon, authenticated, service_role;

-- SECURITY DEFINER so every deletion path is recorded, including FK cascades and
-- privileged maintenance deletes, even though no role can write the table.
create function fundly_private.record_deletion()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.fundly_deleted_records(entity, id, owner_id, revision)
  values (tg_table_name, old.id, old.owner_id, old.revision)
  on conflict (entity, id) do update set owner_id = excluded.owner_id,
    revision = excluded.revision, deleted_at = excluded.deleted_at;
  return null;
end;
$$;

do $$
declare table_name text;
begin
  foreach table_name in array array[
    'custom_account_types', 'accounts', 'categories', 'transactions', 'monthly_plans'
  ] loop
    execute format('create trigger fundly_record_deletion after delete on public.%I
      for each row execute function fundly_private.record_deletion()', table_name);
  end loop;
end;
$$;

-- Table holding an operation's own record (`id`).
create function fundly_private.item_entity(operation text)
returns text language sql immutable set search_path = '' as $$
  select case
    when operation like 'transaction.%' then 'transactions'
    when operation like 'custom!_type.%' escape '!' then 'custom_account_types'
    when operation like 'account.%' then 'accounts'
    when operation = 'plan.save' then 'monthly_plans'
    when operation like 'category.%' or operation like 'plan.%' then 'categories'
  end
$$;

-- Owner of a retired UUID, or null when the value is not a retired UUID string.
create function fundly_private.retired_owner(entity text, value jsonb)
returns uuid language plpgsql stable set search_path = '' as $$
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
$$;

-- A create may not reuse a retired UUID; another owner's learns nothing.
create function fundly_private.check_unretired(actor uuid, entity text, value jsonb)
returns void language plpgsql stable set search_path = '' as $$
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
$$;

-- Applies one item, enriching a rejection with its position and, for conflicts,
-- what the server holds as seen by that item. The error is raised again with
-- the same SQLSTATE so the whole batch still rolls back.
create function fundly_private.apply_item(actor uuid, item jsonb, item_index integer)
returns jsonb language plpgsql set search_path = '' as $$
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
$$;

-- Preserve protocol-1 receipt/fingerprint semantics; only the item loop changes.
create or replace function public.fundly_apply_operations(batch_id uuid, operations jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
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
$$;

revoke all on all functions in schema fundly_private from public, anon, authenticated, service_role;
revoke all on function public.fundly_apply_operations(uuid,jsonb) from public, anon, authenticated, service_role;
grant execute on function public.fundly_apply_operations(uuid,jsonb) to authenticated;
