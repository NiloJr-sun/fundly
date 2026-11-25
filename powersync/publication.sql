-- S3: replicate exactly the Fundly tables to PowerSync (seven since shared spaces C2, eight since banks B.1). Run by the owner in
-- the Supabase SQL editor after the S2 migrations are pushed. Idempotent.
-- `SET TABLE` replaces the whole list, so the S1 probe tables leave the
-- publication in the same statement. Backend-only tables are never published.
-- If PowerSync's dashboard names a different publication, stop and review.
do $$
declare
  existing record;
begin
  select * into existing from pg_catalog.pg_publication where pubname = 'powersync';
  if not found then
    create publication powersync;
  elsif existing.puballtables then
    raise exception 'Publication powersync is FOR ALL TABLES; review before changing it.';
  end if;
end;
$$;

alter publication powersync set table
  public.custom_account_types,
  public.custom_banks,
  public.accounts,
  public.categories,
  public.transactions,
  public.monthly_plans,
  public.spaces,
  public.space_members;

-- Record this output: it must list exactly the eight tables above (the five
-- record tables, spaces and space_members since shared spaces C2, and
-- custom_banks since banks B.1).
select schemaname, tablename
from pg_catalog.pg_publication_tables
where pubname = 'powersync'
order by tablename;
