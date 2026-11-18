-- S2.2A only: transaction operations and atomic, backend-only success receipts.
create schema fundly_private;
revoke all on schema fundly_private from public, anon, authenticated, service_role;

create table public.fundly_write_receipts (
  owner_id uuid not null references auth.users(id) on delete restrict,
  batch_id uuid not null,
  request_fingerprint bytea not null check (octet_length(request_fingerprint) = 32),
  protocol_version integer not null check (protocol_version = 1),
  result jsonb not null check (jsonb_typeof(result) = 'object'),
  created_at timestamptz not null default now(),
  primary key (owner_id, batch_id)
);
alter table public.fundly_write_receipts enable row level security;
revoke all on public.fundly_write_receipts from public, anon, authenticated, service_role;

create function fundly_private.assert_keys(value jsonb, allowed text[])
returns void language plpgsql immutable set search_path = '' as $$
begin
  if jsonb_typeof(value) is distinct from 'object' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  if exists (select 1 from jsonb_object_keys(value) k where not (k = any(allowed))) then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
end;
$$;

create function fundly_private.json_text(value jsonb)
returns text language plpgsql immutable set search_path = '' as $$
begin
  if jsonb_typeof(value) is distinct from 'string' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  return value #>> '{}';
end;
$$;

create function fundly_private.json_uuid(value jsonb, nullable boolean default false)
returns uuid language plpgsql immutable set search_path = '' as $$
declare parsed text;
begin
  if nullable and (value is null or value = 'null'::jsonb) then return null; end if;
  parsed := fundly_private.json_text(value);
  if parsed !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  return parsed::uuid;
end;
$$;

create function fundly_private.positive_bigint(value jsonb)
returns bigint language plpgsql immutable set search_path = '' as $$
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
$$;

-- Unicode White_Space plus BOM, matching the current Dart trim contract.
-- Do not use locale-dependent SQL whitespace classes or ASCII-only btrim.
create function fundly_private.trim_text(value text)
returns text language sql immutable strict set search_path = '' as $$
  select btrim(value, chr(9)||chr(10)||chr(11)||chr(12)||chr(13)||chr(32)||
    chr(133)||chr(160)||chr(5760)||chr(8192)||chr(8193)||chr(8194)||chr(8195)||
    chr(8196)||chr(8197)||chr(8198)||chr(8199)||chr(8200)||chr(8201)||chr(8202)||
    chr(8232)||chr(8233)||chr(8239)||chr(8287)||chr(12288)||chr(65279))
$$;

create function fundly_private.utf16_length(value text)
returns integer language sql immutable strict set search_path = '' as $$
  select coalesce(sum(case when ascii(substr(value, i, 1)) > 65535 then 2 else 1 end), 0)::integer
  from generate_series(1, char_length(value)) i
$$;

create function fundly_private.iso_date(value jsonb)
returns date language plpgsql immutable set search_path = '' as $$
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
$$;

create function fundly_private.transaction_wire(value public.transactions)
returns jsonb language sql stable strict set search_path = '' as $$
  select to_jsonb(value) || jsonb_build_object(
    'amount_minor', value.amount_minor::text,
    'revision', value.revision::text,
    'date', case when extract(year from value.date) = -1
      then '0000-' || to_char(value.date, 'MM-DD') else to_char(value.date, 'YYYY-MM-DD') end,
    'created_at', to_char(value.created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'updated_at', to_char(value.updated_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'))
$$;

create function fundly_private.apply_transaction(actor uuid, item jsonb)
returns jsonb language plpgsql set search_path = '' as $$
declare
  operation text;
  record_id uuid;
  expected bigint;
  previous public.transactions%rowtype;
  candidate public.transactions%rowtype;
  account_row public.accounts%rowtype;
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
      or (candidate.type in ('transfer','creditCardPayment') and account_row.type <> 'savingsCash') then
      raise exception 'invalid_transaction' using errcode = 'P0001';
    end if;
  end if;
  if candidate.destination_account_id is not null then
    select * into account_row from public.accounts
      where id = candidate.destination_account_id and owner_id = actor for share;
    if not found then raise exception 'record_not_accessible' using errcode = 'P0001'; end if;
    if (account_row.is_archived and (operation = 'transaction.create'
        or candidate.destination_account_id is distinct from previous.destination_account_id))
      or (candidate.type = 'inflow' and account_row.type not in ('savingsCash','credit'))
      or (candidate.type = 'transfer' and account_row.type not in ('savingsCash','loan'))
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
$$;

-- VOLATILE (the default) is important: in READ COMMITTED, reads after waiting
-- for the advisory lock must see the preceding writer's committed receipt/row.
create function public.fundly_apply_operations(batch_id uuid, operations jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := auth.uid();
  fingerprint bytea;
  receipt public.fundly_write_receipts%rowtype;
  results jsonb := '[]'::jsonb;
  item jsonb;
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
  for item in select value from jsonb_array_elements(operations->'items') loop
    results := results || jsonb_build_array(fundly_private.apply_transaction(actor, item));
  end loop;
  response := jsonb_build_object('version', 1, 'batch_id', batch_id, 'results', results);
  insert into public.fundly_write_receipts(owner_id, batch_id, request_fingerprint, protocol_version, result)
    values(actor, batch_id, fingerprint, 1, response);
  return response;
end;
$$;

-- Lock down internal functions as well as the namespace. Default grants from
-- Supabase's public schema must not expose receipts or privileged helpers.
revoke all on all functions in schema fundly_private from public, anon, authenticated, service_role;
revoke all on function public.fundly_apply_operations(uuid,jsonb) from public, anon, authenticated, service_role;
grant execute on function public.fundly_apply_operations(uuid,jsonb) to authenticated;
