-- Card purchases without a category ROLLBACK (R.18). NOT a migration: kept
-- outside supabase/migrations so it is never applied by accident. Run only on
-- the owner's decision, after the usual backups, as one transaction (psql -1 /
-- SQL editor).
--
-- Restores the server of 20261126010000 (banks): every Spending needs a
-- category again. REFUSES while any card purchase without a category exists,
-- since restoring the check would fail on it; the owner first gives those a
-- category in the app (or deletes them). No other data changes.

do $$
begin
  if exists (select 1 from public.transactions
      where type = 'spending' and category_id is null) then
    raise exception 'card purchases without a category exist; give them a category first';
  end if;
end;
$$;

alter table public.transactions drop constraint transactions_shape,
  add constraint transactions_shape check (
    (type = 'spending' and source_account_id is not null and destination_account_id is null and category_id is not null)
    or (type = 'inflow' and source_account_id is null and destination_account_id is not null)
    or (type in ('transfer', 'creditCardPayment') and source_account_id is not null
      and destination_account_id is not null and category_id is null)
  );

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

revoke all on all functions in schema fundly_private from public, anon, authenticated, service_role;
