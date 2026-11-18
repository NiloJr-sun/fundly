-- S2.2B: all operations share S2.2A's owner lock, atomic batch and receipts.
create function fundly_private.nonnegative_bigint(value jsonb)
returns bigint language plpgsql immutable set search_path = '' as $$
begin
  if value = '"0"'::jsonb then return 0; end if;
  return fundly_private.positive_bigint(value);
end;
$$;

create function fundly_private.valid_name(value jsonb)
returns text language plpgsql immutable set search_path = '' as $$
declare name text := fundly_private.trim_text(fundly_private.json_text(value));
begin
  if name = '' or fundly_private.utf16_length(name) > 40 then
    raise exception 'invalid_name' using errcode = 'P0001';
  end if;
  return name;
end;
$$;

create function fundly_private.metadata_wire(value jsonb)
returns jsonb language sql stable strict set search_path = '' as $$
  select value || jsonb_build_object('revision',value->>'revision',
    'created_at',to_char((value->>'created_at')::timestamptz at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'updated_at',to_char((value->>'updated_at')::timestamptz at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'))
$$;
create function fundly_private.account_wire(value public.accounts)
returns jsonb language sql stable strict set search_path = '' as $$
  select fundly_private.metadata_wire(to_jsonb(value)) ||
    jsonb_build_object('opening_balance_minor',value.opening_balance_minor::text)
$$;

create function fundly_private.utf16_prefix(value text, maximum integer)
returns text language plpgsql immutable strict set search_path = '' as $$
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
$$;

create function fundly_private.check_custom_type(actor uuid, type_id uuid, base text)
returns void language plpgsql set search_path = '' as $$
declare row public.custom_account_types%rowtype;
begin
  if type_id is null then return; end if;
  select * into row from public.custom_account_types where id=type_id and owner_id=actor for share;
  if not found then raise exception 'record_not_accessible' using errcode='P0001'; end if;
  if row.base_type <> base then raise exception 'invalid_account' using errcode='P0001'; end if;
end;
$$;

create function fundly_private.sync_liability_category(actor uuid, account public.accounts, requested_id uuid default null)
returns jsonb language plpgsql set search_path = '' as $$
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
$$;

create function fundly_private.apply_custom_type(actor uuid, item jsonb)
returns jsonb language plpgsql set search_path = '' as $$
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
$$;

create function fundly_private.apply_account(actor uuid, item jsonb)
returns jsonb language plpgsql set search_path = '' as $$
declare
  operation text;
  record_id uuid;
  previous public.accounts%rowtype;
  row public.accounts%rowtype;
  budget public.accounts%rowtype;
  category public.categories%rowtype;
  data jsonb;
  prior jsonb;
  prior_id uuid;
  prior_revision bigint;
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
      if not previous.is_budget_account then raise exception 'budget_conflict' using errcode='P0001'; end if;
      update public.accounts set is_budget_account=false,updated_at=clock_timestamp()
        where id=record_id and owner_id=actor returning * into row;
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
    perform fundly_private.assert_keys(data,array['previous_budget']);
    if not data ? 'previous_budget' then raise exception 'invalid_request' using errcode='22023'; end if;
    if previous.type<>'savingsCash' or previous.is_archived then raise exception 'invalid_account' using errcode='P0001'; end if;
    prior:=data->'previous_budget';
    if prior<>'null'::jsonb then
      perform fundly_private.assert_keys(prior,array['id','revision']);
      prior_id:=fundly_private.json_uuid(prior->'id');
      prior_revision:=fundly_private.positive_bigint(prior->'revision');
    end if;
    select * into budget from public.accounts where owner_id=actor and is_budget_account for update;
    if (prior='null'::jsonb and budget.id is not null)
      or (prior<>'null'::jsonb and (budget.id is null or budget.id<>prior_id
        or budget.revision<>prior_revision)) then
      raise exception 'budget_conflict' using errcode='P0001';
    end if;
    if budget.id=record_id then row:=previous;
    else
      if budget.id is not null then
        update public.accounts set is_budget_account=false,updated_at=clock_timestamp()
          where id=budget.id and owner_id=actor returning * into budget;
        changes:=jsonb_build_array(jsonb_build_object('entity','accounts','id',budget.id,
          'revision',budget.revision::text,'record',fundly_private.account_wire(budget)));
      end if;
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
$$;

create function fundly_private.apply_operation(actor uuid,item jsonb)
returns jsonb language plpgsql set search_path = '' as $$
declare operation text;
begin
  perform fundly_private.assert_keys(item,array['operation','id','expected_revision','data']);
  operation:=fundly_private.json_text(item->'operation');
  if operation in ('transaction.create','transaction.update','transaction.delete') then
    return fundly_private.apply_transaction(actor,item);
  elsif operation in ('custom_type.create','custom_type.update','custom_type.delete') then
    return fundly_private.apply_custom_type(actor,item);
  elsif operation in ('account.create','account.update','account.set_archived','account.delete','account.set_budget','account.clear_budget') then
    return fundly_private.apply_account(actor,item);
  end if;
  raise exception 'unsupported_operation' using errcode='P0001';
end;
$$;

-- Preserve protocol-1 receipt/fingerprint semantics; only the dispatcher changes.
create or replace function public.fundly_apply_operations(batch_id uuid, operations jsonb)
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
    results := results || jsonb_build_array(fundly_private.apply_operation(actor, item));
  end loop;
  response := jsonb_build_object('version', 1, 'batch_id', batch_id, 'results', results);
  insert into public.fundly_write_receipts(owner_id, batch_id, request_fingerprint, protocol_version, result)
    values(actor, batch_id, fingerprint, 1, response);
  return response;
end;
$$;
revoke all on all functions in schema fundly_private from public,anon,authenticated,service_role;
revoke all on function public.fundly_apply_operations(uuid,jsonb) from public,anon,authenticated,service_role;
grant execute on function public.fundly_apply_operations(uuid,jsonb) to authenticated;
