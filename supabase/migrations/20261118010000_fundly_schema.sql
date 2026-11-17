-- S2.1: cloud foundation only. No client write API or replication changes.
-- Deliberately fail on existing table names rather than silently accept a
-- conflicting schema. Run via Supabase migrations in a transaction.

create table public.custom_account_types (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete restrict,
  name text not null,
  base_type text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revision bigint not null default 1,
  constraint custom_account_types_owner_id_key unique (owner_id, id),
  constraint custom_account_types_name_length check (char_length(name) between 1 and 40),
  constraint custom_account_types_base_type check (base_type in ('savingsCash', 'credit', 'loan')),
  constraint custom_account_types_revision_positive check (revision > 0)
);

-- SQLite NOCASE folds ASCII A-Z only. COLLATE C keeps the remaining characters
-- byte-distinct, independent of the database's default locale.
create unique index custom_account_types_owner_name on public.custom_account_types
  (owner_id, (translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') collate "C"));

create table public.accounts (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete restrict,
  name text not null,
  type text not null,
  opening_balance_minor bigint not null,
  currency_code text not null default 'PHP',
  is_archived boolean not null default false,
  custom_type_id uuid,
  is_budget_account boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revision bigint not null default 1,
  constraint accounts_owner_id_key unique (owner_id, id),
  constraint accounts_name_length check (char_length(name) between 1 and 40),
  constraint accounts_type check (type in ('savingsCash', 'credit', 'loan')),
  constraint accounts_opening_balance_sign check (
    (type = 'savingsCash' and opening_balance_minor >= 0)
    or (type in ('credit', 'loan') and opening_balance_minor <= 0)
  ),
  constraint accounts_currency check (currency_code = 'PHP'),
  constraint accounts_budget_eligible check (
    not is_budget_account or (type = 'savingsCash' and not is_archived)
  ),
  constraint accounts_revision_positive check (revision > 0),
  constraint accounts_custom_type_owner_fk foreign key (owner_id, custom_type_id)
    references public.custom_account_types(owner_id, id) on delete restrict
);
create unique index accounts_owner_name on public.accounts
  (owner_id, (translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') collate "C"));
create unique index accounts_one_budget_account on public.accounts(owner_id)
  where is_budget_account;
create index accounts_custom_type on public.accounts(owner_id, custom_type_id);

create table public.categories (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete restrict,
  name text not null,
  kind text not null,
  is_archived boolean not null default false,
  is_plan_archived boolean not null default false,
  is_plan_deleted boolean not null default false,
  plan_group text not null default 'spending',
  linked_account_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revision bigint not null default 1,
  constraint categories_owner_id_key unique (owner_id, id),
  constraint categories_name_length check (char_length(name) between 1 and 40),
  constraint categories_kind check (kind in ('spending', 'inflow')),
  constraint categories_plan_group check (plan_group in ('spending', 'savings', 'liability')),
  constraint categories_deleted_plan check (
    not is_plan_deleted or (is_plan_archived and kind = 'spending')
  ),
  constraint categories_linked_plan check (
    linked_account_id is null or (kind = 'spending' and plan_group = 'liability')
  ),
  constraint categories_revision_positive check (revision > 0),
  constraint categories_linked_account_key unique (owner_id, linked_account_id),
  -- Only detach the link. owner_id must remain set when an unused account is
  -- deleted. PostgreSQL 15+ supports column-specific SET NULL actions.
  constraint categories_linked_account_owner_fk foreign key (owner_id, linked_account_id)
    references public.accounts(owner_id, id) on delete set null (linked_account_id)
);
create unique index categories_owner_name on public.categories
  (owner_id, (translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') collate "C"));

create table public.transactions (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete restrict,
  type text not null,
  amount_minor bigint not null,
  currency_code text not null default 'PHP',
  date date not null,
  payee text not null default '',
  category_id uuid,
  source_account_id uuid,
  destination_account_id uuid,
  note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revision bigint not null default 1,
  constraint transactions_owner_id_key unique (owner_id, id),
  constraint transactions_type check (type in ('spending', 'inflow', 'transfer', 'creditCardPayment')),
  constraint transactions_amount_positive check (amount_minor > 0),
  constraint transactions_currency check (currency_code = 'PHP'),
  constraint transactions_different_accounts check (source_account_id <> destination_account_id),
  -- Dart accepts ISO year 0000; PostgreSQL represents that year as 0001 BC.
  -- The future client/import adapter must map it explicitly, not reject it.
  constraint transactions_date_range check (date between date '0001-01-01 BC' and date '9999-12-31'),
  constraint transactions_payee_length check (char_length(payee) <= 60),
  constraint transactions_payee_required check (type not in ('spending', 'inflow') or btrim(payee) <> ''),
  constraint transactions_note_length check (char_length(note) <= 500),
  constraint transactions_shape check (
    (type = 'spending' and source_account_id is not null and destination_account_id is null and category_id is not null)
    or (type = 'inflow' and source_account_id is null and destination_account_id is not null)
    or (type in ('transfer', 'creditCardPayment') and source_account_id is not null
      and destination_account_id is not null and category_id is null)
  ),
  constraint transactions_revision_positive check (revision > 0),
  constraint transactions_category_owner_fk foreign key (owner_id, category_id)
    references public.categories(owner_id, id) on delete restrict,
  constraint transactions_source_owner_fk foreign key (owner_id, source_account_id)
    references public.accounts(owner_id, id) on delete restrict,
  constraint transactions_destination_owner_fk foreign key (owner_id, destination_account_id)
    references public.accounts(owner_id, id) on delete restrict
);
create index transactions_owner_date on public.transactions(owner_id, date, id);
create index transactions_source_account on public.transactions(owner_id, source_account_id);
create index transactions_destination_account on public.transactions(owner_id, destination_account_id);
create index transactions_category on public.transactions(owner_id, category_id);

create table public.monthly_plans (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete restrict,
  month text not null,
  category_id uuid not null,
  target_amount_minor bigint,
  assigned_amount_minor bigint not null,
  currency_code text not null default 'PHP',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revision bigint not null default 1,
  constraint monthly_plans_owner_id_key unique (owner_id, id),
  constraint monthly_plans_month check (month ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),
  constraint monthly_plans_target_nonnegative check (target_amount_minor is null or target_amount_minor >= 0),
  constraint monthly_plans_assigned_nonnegative check (assigned_amount_minor >= 0),
  constraint monthly_plans_currency check (currency_code = 'PHP'),
  constraint monthly_plans_revision_positive check (revision > 0),
  constraint monthly_plans_owner_category_month_key unique (owner_id, category_id, month),
  constraint monthly_plans_category_owner_fk foreign key (owner_id, category_id)
    references public.categories(owner_id, id) on delete cascade
);
create index monthly_plans_owner_month on public.monthly_plans(owner_id, month);

-- No client can choose a revision. Even privileged writers get monotonically
-- increasing revisions, including FK-driven link detachment. S2.2 supplies
-- expected-revision validation and transaction-level workflow validation.
create function public.fundly_set_revision()
returns trigger language plpgsql set search_path = '' as $$
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
$$;
revoke all on function public.fundly_set_revision() from public, anon, authenticated;

do $$
declare table_name text;
begin
  foreach table_name in array array[
    'custom_account_types', 'accounts', 'categories', 'transactions', 'monthly_plans'
  ] loop
    execute format('create trigger fundly_set_revision before insert or update on public.%I
      for each row execute function public.fundly_set_revision()', table_name);
    execute format('alter table public.%I enable row level security', table_name);
    execute format('revoke all on table public.%I from public, anon, authenticated', table_name);
    execute format('grant select on table public.%I to authenticated', table_name);
    execute format('grant all on table public.%I to service_role', table_name);
    execute format('create policy read_own on public.%I for select to authenticated
      using (owner_id = (select auth.uid()))', table_name);
  end loop;
end;
$$;
