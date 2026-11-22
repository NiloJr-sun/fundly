-- S5.3: `dataset.initialize` creates the default categories once per dataset,
-- not once per device. Under the per-user batch lock it inserts the defaults
-- only when the owner has no categories at all, so two devices initializing at
-- the same time produce one set. The list matches the app's
-- `defaultCategories` for new databases. No table or column changes.

create function fundly_private.apply_dataset_initialize(actor uuid, item jsonb)
returns jsonb language plpgsql set search_path = '' as $$
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
  elsif operation = 'dataset.initialize' then
    return fundly_private.apply_dataset_initialize(actor, item);
  end if;
  raise exception 'unsupported_operation' using errcode = 'P0001';
end;
$$;

revoke all on all functions in schema fundly_private from public, anon, authenticated, service_role;
revoke all on function public.fundly_apply_operations(uuid,jsonb) from public, anon, authenticated, service_role;
grant execute on function public.fundly_apply_operations(uuid,jsonb) to authenticated;
