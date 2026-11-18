-- S3, last step: drop the S1 probe's cloud objects. Irreversible. Run by the
-- owner in the Supabase SQL editor only after Fundly's streams are deployed,
-- publication.sql has run, and every S3 check has passed. Fundly tables, the
-- test users and their data are not touched. Policies are dropped with tables.
begin;

do $$
begin
  if exists (select 1 from pg_catalog.pg_publication_tables
             where schemaname = 'public' and tablename like 'probe!_%' escape '!') then
    raise exception 'Probe tables are still published; run publication.sql first.';
  end if;
end;
$$;

drop function if exists public.probe_apply_batch(uuid, jsonb);
drop table if exists public.probe_entries;
drop table if exists public.probe_receipts;
drop table if exists public.probe_parents;

-- Record this output: it must return no rows.
select table_name from information_schema.tables
where table_schema = 'public' and table_name like 'probe!_%' escape '!';

commit;
