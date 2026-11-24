#!/bin/sh
# Starts local sync for Fundly's LOCAL Supabase stack: the full stack (API and
# Auth too), a replication role, the publication from powersync/publication.sql,
# and PowerSync with a fresh storage (so a `db reset` never leaves it stale).
# Writes the git-ignored config.local.json and .env.local (two test users).
set -eu
cd "$(dirname "$0")"
ROOT=../../../..
# `db start` runs only the database, and `start` then thinks the stack is up:
# restart it when Auth or the API is missing (local data is kept).
if ! (cd $ROOT && npx --yes supabase@3.2.0 status -o json 2>/dev/null) | grep -q '"API_URL"'; then
  (cd $ROOT && npx --yes supabase@3.2.0 stop >/dev/null 2>&1 || true)
fi
(cd $ROOT && npx --yes supabase@3.2.0 start >/dev/null)
docker exec -i supabase_db_fundly-schema-dev psql -U postgres -q -v ON_ERROR_STOP=1 <<'SQL'
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'powersync_local') then
    create role powersync_local with replication bypassrls login password 'fundly-local-powersync';
  end if;
end $$;
grant usage on schema public to powersync_local;
grant select on all tables in schema public to powersync_local;
SQL
docker exec -i supabase_db_fundly-schema-dev psql -U postgres -q -v ON_ERROR_STOP=1 < $ROOT/powersync/publication.sql >/dev/null
docker compose down --volumes >/dev/null 2>&1 || true
docker compose up -d --wait >/dev/null
(cd $ROOT && npx --yes supabase@3.2.0 status -o json 2>/dev/null) | python3 -I local_env.py
