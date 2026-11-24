-- Shared spaces C1.1 (docs/SHARED_SPACES_C1_PLAN.md): records belong to a
-- space; users are members of spaces. Every Auth user gets a Personal space
-- whose id is their own user id (Decision C1-1), so every record's space is
-- its current owner_id and no data value changes.
--
-- owner_id stays as a legacy copy equal to space_id (the live sync stream
-- filters on it; Decision C1-3). Until C1.2 rewrites the write functions, a
-- trigger fills space_id, created_by and updated_by from owner_id, so the
-- current functions keep working unchanged. Protocol 1 is unchanged.

-- Spaces and members -------------------------------------------------------

create table public.spaces (
  id uuid primary key,
  name text not null,
  -- Deleting an Auth user with no records removes their Personal space and
  -- memberships, as before C1; records still block deleting their user.
  personal_of uuid references auth.users(id) on delete cascade,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revision bigint not null default 1,
  constraint spaces_name_length check (char_length(name) between 1 and 40 and name = btrim(name)),
  -- A Personal space has its user's id and is created by them.
  constraint spaces_personal_of_key unique (personal_of),
  constraint spaces_personal_id check (personal_of is null or (id = personal_of
    and (created_by is null or created_by = personal_of))),
  constraint spaces_revision_positive check (revision > 0)
);

create table public.space_members (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.spaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint space_members_role check (role in ('owner', 'editor', 'viewer')),
  constraint space_members_space_user_key unique (space_id, user_id)
);
create index space_members_user on public.space_members(user_id, space_id);

-- A space always keeps an owner, and a Personal space's user stays its owner.
-- Checked at commit, so a role change and its replacement can share a
-- transaction; a deleted space's members may all go.
create function fundly_private.check_space_owners()
returns trigger language plpgsql set search_path = '' as $$
declare target uuid := coalesce(new.space_id, old.space_id);
begin
  if exists (select 1 from public.spaces s where s.id = target) and (
    not exists (select 1 from public.space_members m
      where m.space_id = target and m.role = 'owner')
    or exists (select 1 from public.spaces s where s.id = target
      and s.personal_of is not null and not exists (select 1 from public.space_members m
        where m.space_id = target and m.user_id = s.personal_of and m.role = 'owner'))
  ) then
    raise exception 'space_needs_owner' using errcode = '23514';
  end if;
  return null;
end;
$$;
create constraint trigger space_members_keep_owner
  after insert or update or delete on public.space_members
  deferrable initially deferred
  for each row execute function fundly_private.check_space_owners();

-- Membership for read rules. Its own schema, so policies can call it without
-- giving clients access to fundly_private; not exposed by the API.
create schema fundly_access;
revoke all on schema fundly_access from public, anon, authenticated, service_role;
grant usage on schema fundly_access to authenticated;

create function fundly_access.my_space_ids()
returns setof uuid language sql stable security definer set search_path = '' as $$
  select m.space_id from public.space_members m where m.user_id = (select auth.uid())
$$;
revoke all on function fundly_access.my_space_ids() from public, anon, service_role;
grant execute on function fundly_access.my_space_ids() to authenticated;

alter table public.spaces enable row level security;
alter table public.space_members enable row level security;
revoke all on table public.spaces, public.space_members from public, anon, authenticated;
grant select on table public.spaces, public.space_members to authenticated;
grant all on table public.spaces, public.space_members to service_role;
create policy read_member on public.spaces for select to authenticated
  using (id in (select fundly_access.my_space_ids()));
create policy read_member on public.space_members for select to authenticated
  using (space_id in (select fundly_access.my_space_ids()));

-- Personal spaces for every existing user (new users get theirs on first
-- write, through fundly_private.ensure_personal_space).
insert into public.spaces(id, name, personal_of, created_by)
  select u.id, 'Personal', u.id, u.id from auth.users u;
insert into public.space_members(space_id, user_id, role)
  select u.id, u.id, 'owner' from auth.users u;

-- Records belong to a space ------------------------------------------------

-- Keeps the legacy owner_id equal to space_id and fills what the current
-- write functions do not send yet. created_by and updated_by are the owner
-- while every space is Personal; C1.2 sets them from the writer.
-- A user's Personal space and owner membership, created on first use (new
-- users after this migration; Decision C1-5).
create function fundly_private.ensure_personal_space(member uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.spaces where id = member) then
    insert into public.spaces(id, name, personal_of, created_by)
      values (member, 'Personal', member, member) on conflict (id) do nothing;
    insert into public.space_members(space_id, user_id, role)
      values (member, member, 'owner') on conflict (space_id, user_id) do nothing;
  end if;
end;
$$;

create function fundly_private.bridge_space_owner()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  new.space_id := coalesce(new.space_id, new.owner_id);
  new.owner_id := coalesce(new.owner_id, new.space_id);
  new.created_by := coalesce(new.created_by, new.owner_id);
  new.updated_by := coalesce(new.updated_by, new.created_by);
  if new.space_id = new.owner_id then
    perform fundly_private.ensure_personal_space(new.owner_id);
  end if;
  return new;
end;
$$;

-- Receipts and tombstones: the space of the write, from owner_id until C1.2.
create function fundly_private.bridge_receipt_space()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.space_id := coalesce(new.space_id, new.owner_id);
  return new;
end;
$$;

-- No client can change a record's identity, space or creator.
create or replace function public.fundly_set_revision()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    new.revision := 1;
  else
    if new.id is distinct from old.id or new.owner_id is distinct from old.owner_id
      or new.space_id is distinct from old.space_id
      or new.created_by is distinct from old.created_by then
      raise exception 'Fundly record identity and owner are immutable' using errcode = '23514';
    end if;
    new.revision := old.revision + 1;
  end if;
  return new;
end;
$$;

-- The backfill copies owner_id without bumping any revision: a bumped
-- revision would turn every pending device edit into a revision conflict.
do $$
declare table_name text;
begin
  foreach table_name in array array[
    'custom_account_types', 'accounts', 'categories', 'transactions', 'monthly_plans'
  ] loop
    execute format('alter table public.%I add column space_id uuid,
      add column created_by uuid, add column updated_by uuid', table_name);
    execute format('alter table public.%I disable trigger fundly_set_revision', table_name);
    execute format('update public.%I set space_id = owner_id, created_by = owner_id,
      updated_by = owner_id', table_name);
    execute format('alter table public.%I enable trigger fundly_set_revision', table_name);
    execute format('alter table public.%I
      alter column space_id set not null,
      alter column created_by set not null,
      alter column updated_by set not null,
      add constraint %I foreign key (space_id) references public.spaces(id) on delete restrict,
      add constraint %I foreign key (created_by) references auth.users(id) on delete restrict,
      add constraint %I foreign key (updated_by) references auth.users(id) on delete restrict,
      add constraint %I check (owner_id = space_id)',
      table_name, table_name || '_space_fk', table_name || '_created_by_fk',
      table_name || '_updated_by_fk', table_name || '_owner_is_space');
    execute format('create trigger fundly_space_bridge before insert on public.%I
      for each row execute function fundly_private.bridge_space_owner()', table_name);
    execute format('drop policy read_own on public.%I', table_name);
    execute format('create policy read_member on public.%I for select to authenticated
      using (space_id in (select fundly_access.my_space_ids()))', table_name);
  end loop;
end;
$$;

-- Per-space keys, uniqueness and composite foreign keys, replacing the
-- per-owner ones (same rules, same actions).
alter table public.accounts drop constraint accounts_custom_type_owner_fk;
alter table public.categories drop constraint categories_linked_account_owner_fk,
  drop constraint categories_linked_account_key;
alter table public.transactions drop constraint transactions_category_owner_fk,
  drop constraint transactions_source_owner_fk,
  drop constraint transactions_destination_owner_fk;
alter table public.monthly_plans drop constraint monthly_plans_category_owner_fk,
  drop constraint monthly_plans_owner_category_month_key;
alter table public.custom_account_types drop constraint custom_account_types_owner_id_key,
  add constraint custom_account_types_space_id_key unique (space_id, id);
alter table public.accounts drop constraint accounts_owner_id_key,
  add constraint accounts_space_id_key unique (space_id, id);
alter table public.categories drop constraint categories_owner_id_key,
  add constraint categories_space_id_key unique (space_id, id);
alter table public.transactions drop constraint transactions_owner_id_key,
  add constraint transactions_space_id_key unique (space_id, id);
alter table public.monthly_plans drop constraint monthly_plans_owner_id_key,
  add constraint monthly_plans_space_id_key unique (space_id, id);

alter table public.accounts
  add constraint accounts_custom_type_space_fk foreign key (space_id, custom_type_id)
    references public.custom_account_types(space_id, id) on delete restrict;
alter table public.categories
  add constraint categories_linked_account_key unique (space_id, linked_account_id),
  -- Only detach the link; space_id stays set when an unused account is deleted.
  add constraint categories_linked_account_space_fk foreign key (space_id, linked_account_id)
    references public.accounts(space_id, id) on delete set null (linked_account_id);
alter table public.transactions
  add constraint transactions_category_space_fk foreign key (space_id, category_id)
    references public.categories(space_id, id) on delete restrict,
  add constraint transactions_source_space_fk foreign key (space_id, source_account_id)
    references public.accounts(space_id, id) on delete restrict,
  add constraint transactions_destination_space_fk foreign key (space_id, destination_account_id)
    references public.accounts(space_id, id) on delete restrict;
alter table public.monthly_plans
  add constraint monthly_plans_space_category_month_key unique (space_id, category_id, month),
  add constraint monthly_plans_category_space_fk foreign key (space_id, category_id)
    references public.categories(space_id, id) on delete cascade;

-- Names are unique per space (same folding as before).
drop index public.custom_account_types_owner_name;
drop index public.accounts_owner_name;
drop index public.categories_owner_name;
create unique index custom_account_types_space_name on public.custom_account_types
  (space_id, (translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') collate "C"));
create unique index accounts_space_name on public.accounts
  (space_id, (translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') collate "C"));
create unique index categories_space_name on public.categories
  (space_id, (translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') collate "C"));

-- Lookup indexes follow the space. owner_id keeps its own index for the
-- current functions and the live stream until C1.2 and C2.
drop index public.accounts_custom_type;
drop index public.monthly_plans_owner_month;
drop index public.transactions_owner_date;
drop index public.transactions_source_account;
drop index public.transactions_destination_account;
drop index public.transactions_category;
create index accounts_custom_type on public.accounts(space_id, custom_type_id);
create index monthly_plans_space_month on public.monthly_plans(space_id, month);
create index transactions_space_date on public.transactions(space_id, date, id);
create index transactions_source_account on public.transactions(space_id, source_account_id);
create index transactions_destination_account on public.transactions(space_id, destination_account_id);
create index transactions_category on public.transactions(space_id, category_id);
create index custom_account_types_owner on public.custom_account_types(owner_id);
create index accounts_owner on public.accounts(owner_id);
create index categories_owner on public.categories(owner_id);
create index transactions_owner on public.transactions(owner_id);
create index monthly_plans_owner on public.monthly_plans(owner_id);

-- Backend tables -----------------------------------------------------------

-- Tombstones keep a deleted id retired for good, even after its space is
-- deleted, so space_id has no foreign key.
alter table public.fundly_deleted_records add column space_id uuid;
update public.fundly_deleted_records set space_id = owner_id;
alter table public.fundly_deleted_records alter column space_id set not null;
create index fundly_deleted_records_space on public.fundly_deleted_records(space_id);

create or replace function fundly_private.record_deletion()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.fundly_deleted_records(entity, id, owner_id, space_id, revision)
  values (tg_table_name, old.id, old.owner_id, old.space_id, old.revision)
  on conflict (entity, id) do update set owner_id = excluded.owner_id,
    space_id = excluded.space_id, revision = excluded.revision,
    deleted_at = excluded.deleted_at;
  return null;
end;
$$;

-- Receipts stay keyed by the sender (owner_id) and record the target space.
alter table public.fundly_write_receipts add column space_id uuid;
update public.fundly_write_receipts set space_id = owner_id;
alter table public.fundly_write_receipts alter column space_id set not null;
create trigger fundly_receipt_space before insert on public.fundly_write_receipts
  for each row execute function fundly_private.bridge_receipt_space();

alter table public.fundly_import_receipts add column space_id uuid;
update public.fundly_import_receipts set space_id = owner_id;
alter table public.fundly_import_receipts alter column space_id set not null;
create trigger fundly_receipt_space before insert on public.fundly_import_receipts
  for each row execute function fundly_private.bridge_receipt_space();

-- Error mapping: duplicate names now violate the *_space_name indexes. The
-- three functions below are their current definitions with only that name
-- changed; C1.2 rewrites them for (space, actor).

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
    if violation='custom_account_types_space_name' then raise exception 'name_taken' using errcode='P0001'; end if;
    raise exception 'record_id_unavailable' using errcode='P0001';
  end;
  return jsonb_build_object('operation',operation,'entity','custom_account_types','id',row.id,
    'revision',row.revision::text,'record',fundly_private.metadata_wire(to_jsonb(row)));
end;
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
      if violation='accounts_space_name' then raise exception 'name_taken' using errcode='P0001'; end if;
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
      if violation = 'categories_space_name' then raise exception 'name_taken' using errcode = 'P0001'; end if;
      raise exception 'record_id_unavailable' using errcode = 'P0001';
    end;
  end if;
  return jsonb_build_object('operation', operation, 'entity', 'categories', 'id', row.id,
    'revision', row.revision::text, 'record', fundly_private.category_wire(row), 'changes', changes);
end;
$function$

;


-- Import unnests arrays of whole table rows with explicit column lists, so
-- the three new columns are added to each list. Otherwise its current
-- definition; C1.2 rewrites it for (space, actor).
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
$function$;

revoke all on all functions in schema fundly_private from public, anon, authenticated, service_role;
