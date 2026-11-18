-- S2.2C: category, monthly-plan and plan-lifecycle operations. They share the
-- S2.2A owner lock, atomic batch and receipts. No table or column changes.

create function fundly_private.category_wire(value public.categories)
returns jsonb language sql stable strict set search_path = '' as $$
  select fundly_private.metadata_wire(to_jsonb(value))
$$;

create function fundly_private.plan_wire(value public.monthly_plans)
returns jsonb language sql stable strict set search_path = '' as $$
  select fundly_private.metadata_wire(to_jsonb(value)) || jsonb_build_object(
    'target_amount_minor', value.target_amount_minor::text,
    'assigned_amount_minor', value.assigned_amount_minor::text)
$$;

create function fundly_private.calendar_month(value jsonb)
returns text language plpgsql immutable set search_path = '' as $$
declare parsed text;
begin
  parsed := fundly_private.json_text(value);
  if parsed !~ '^[0-9]{4}-(0[1-9]|1[0-2])$' then
    raise exception 'invalid_request' using errcode = '22023';
  end if;
  return parsed;
end;
$$;

-- Exact IANA names only. Abbreviation/POSIX strings such as 'UTC+8' are not
-- catalogue entries (PostgreSQL would invert their sign), nor is 'asia/manila'.
create function fundly_private.valid_timezone(value jsonb)
returns text language plpgsql stable set search_path = '' as $$
declare zone text;
begin
  zone := fundly_private.json_text(value);
  if char_length(zone) > 64
    or not exists(select 1 from pg_catalog.pg_timezone_names n where n.name = zone) then
    raise exception 'invalid_timezone' using errcode = 'P0001';
  end if;
  return zone;
end;
$$;

-- The caller's calendar month at an instant; the archive guard passes
-- clock_timestamp(), tests pass fixed instants.
create function fundly_private.local_month(zone text, instant timestamptz)
returns text language sql stable strict set search_path = '' as $$
  select to_char(pg_catalog.timezone(zone, instant), 'YYYY-MM')
$$;

-- Port of remainingPlanAllocation for every plan month >= from_month: Assigned
-- minus that month's eligible transactions from the budget account, floored at
-- zero. With no budget account nothing is released. Only nonzero months return.
create function fundly_private.remaining_allocations(
  actor uuid, target_category uuid, linked_account uuid, from_month text)
returns jsonb language sql stable set search_path = '' as $$
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
$$;

-- Deleted plans in month order, for a result's `changes`.
create function fundly_private.delete_category_plans(actor uuid, target_category uuid)
returns jsonb language plpgsql set search_path = '' as $$
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
$$;

create function fundly_private.apply_category(actor uuid, item jsonb)
returns jsonb language plpgsql set search_path = '' as $$
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
$$;

-- Port of PlanRepository.save/clear, addressed by category and month. `previous`
-- is the record the client observed (or null), so concurrent creates conflict.
create function fundly_private.apply_plan_save(actor uuid, item jsonb)
returns jsonb language plpgsql set search_path = '' as $$
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
$$;

-- Port of PlanRepository.setArchived/deletePermanently. Both change flags on the
-- category row, so the item is the category and its revision.
create function fundly_private.apply_plan_lifecycle(actor uuid, item jsonb)
returns jsonb language plpgsql set search_path = '' as $$
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
$$;

create or replace function fundly_private.apply_operation(actor uuid, item jsonb)
returns jsonb language plpgsql set search_path = '' as $$
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
  end if;
  raise exception 'unsupported_operation' using errcode = 'P0001';
end;
$$;

revoke all on all functions in schema fundly_private from public, anon, authenticated, service_role;
revoke all on function public.fundly_apply_operations(uuid,jsonb) from public, anon, authenticated, service_role;
grant execute on function public.fundly_apply_operations(uuid,jsonb) to authenticated;
