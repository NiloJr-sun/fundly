-- Disposable S1 probe only. Review and run in Supabase SQL Editor.
-- This does not create or migrate Fundly's production tables.
begin;

create table if not exists public.probe_parents (
  id uuid primary key,
  owner_id uuid not null references auth.users(id),
  name text not null check (name <> 'REJECT_PROBE'),
  revision bigint not null check (revision > 0),
  unique (owner_id, id)
);
create table if not exists public.probe_entries (
  id uuid primary key,
  owner_id uuid not null references auth.users(id),
  parent_id uuid not null,
  amount_minor bigint not null check (amount_minor > 0),
  foreign key (owner_id, parent_id)
    references public.probe_parents(owner_id, id) deferrable initially deferred
);
create table if not exists public.probe_receipts (
  owner_id uuid not null references auth.users(id),
  batch_id uuid not null,
  primary key (owner_id, batch_id)
);

alter table public.probe_parents enable row level security;
alter table public.probe_entries enable row level security;
alter table public.probe_receipts enable row level security;
drop policy if exists probe_read_own on public.probe_parents;
create policy probe_read_own on public.probe_parents for select to authenticated
  using (owner_id = (select auth.uid()));
drop policy if exists probe_read_own on public.probe_entries;
create policy probe_read_own on public.probe_entries for select to authenticated
  using (owner_id = (select auth.uid()));
revoke all on public.probe_parents, public.probe_entries, public.probe_receipts
  from anon, authenticated;
grant select on public.probe_parents, public.probe_entries to authenticated;

-- One atomic upload per local CRUD transaction. Successful retries are no-ops.
-- Intentionally minimal: parent revision checks are prototyped, not a complete
-- financial conflict protocol. Child edit revisions remain an S1 follow-up.
create or replace function public.probe_apply_batch(p_batch_id uuid, p_ops jsonb)
returns void language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := auth.uid();
  operation jsonb;
  data jsonb;
  previous jsonb;
  entity_id uuid;
  affected integer;
begin
  if actor is null then raise exception 'Authentication required'; end if;
  if p_ops is null or jsonb_typeof(p_ops) <> 'array' or jsonb_array_length(p_ops) = 0
    or jsonb_array_length(p_ops) > 100 then
    raise exception 'Expected 1–100 operations';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(actor::text || p_batch_id::text, 0));
  if exists (select 1 from public.probe_receipts
    where owner_id = actor and batch_id = p_batch_id) then return; end if;

  for operation in select value from jsonb_array_elements(p_ops) loop
    entity_id := (operation->>'id')::uuid;
    data := operation->'data';
    previous := operation->'old';
    if operation->>'type' = 'probe_parents' then
      case operation->>'op'
        when 'PUT' then
          insert into public.probe_parents(id, owner_id, name, revision)
          values (entity_id, actor, data->>'name', (data->>'revision')::bigint);
        when 'PATCH' then
          update public.probe_parents set
            name = case when data ? 'name' then data->>'name' else name end,
            revision = revision + 1
          where id = entity_id and owner_id = actor
            and revision = (previous->>'revision')::bigint;
          get diagnostics affected = row_count;
          if affected <> 1 then raise exception 'Missing parent or revision conflict'; end if;
        when 'DELETE' then
          delete from public.probe_parents where id = entity_id and owner_id = actor
            and revision = (previous->>'revision')::bigint;
          get diagnostics affected = row_count;
          if affected <> 1 then raise exception 'Missing parent or revision conflict'; end if;
        else raise exception 'Unsupported operation';
      end case;
    elsif operation->>'type' = 'probe_entries' then
      case operation->>'op'
        when 'PUT' then
          insert into public.probe_entries(id, owner_id, parent_id, amount_minor)
          values (entity_id, actor, (data->>'parent_id')::uuid, (data->>'amount_minor')::bigint);
        when 'DELETE' then
          delete from public.probe_entries where id = entity_id and owner_id = actor;
          get diagnostics affected = row_count;
          if affected <> 1 then raise exception 'Missing entry'; end if;
        else raise exception 'Child edits are outside this disposable probe';
      end case;
    else
      raise exception 'Unsupported table';
    end if;
  end loop;
  insert into public.probe_receipts(owner_id, batch_id) values (actor, p_batch_id);
end;
$$;
revoke all on function public.probe_apply_batch(uuid, jsonb) from public, anon;
grant execute on function public.probe_apply_batch(uuid, jsonb) to authenticated;

commit;

-- Next: PowerSync's guided Supabase connection sets up replication. If using
-- manual setup, follow the official guide for its role, grants and publication.
-- Include ONLY probe_parents and probe_entries in the probe's sync config;
-- probe_receipts is backend-only. Never publish auth.users to clients.
