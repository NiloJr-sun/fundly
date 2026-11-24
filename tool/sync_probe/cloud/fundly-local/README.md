# Fundly local sync

Self-hosted PowerSync (open edition 1.29.1, telemetry off) on Fundly's
**local** Supabase stack, running the repository's real
`powersync/sync-config.yaml`. Added in shared spaces C2.1 to rehearse sync
changes before they reach the hosted services, and usable to develop the app
against local sync. Nothing here touches production.

| Part | Where |
|---|---|
| Supabase (Fundly's local stack, `supabase/`) | API and Auth `http://127.0.0.1:55321`, database `55322` |
| PowerSync | `http://127.0.0.1:55380`; replication role `powersync_local` (local only); publication from `powersync/publication.sql` |
| PowerSync storage | `postgres:17.6-alpine`, recreated on every `up.sh` |

```sh
tool/sync_probe/cloud/fundly-local/up.sh     # start; safe to rerun; writes config.local.json and .env.local
set -a; . tool/sync_probe/cloud/fundly-local/.env.local; set +a
export FUNDLY_CHECK_CONFIG=$PWD/tool/sync_probe/cloud/fundly-local/config.local.json
python3 tool/cloud_checks/api_isolation.py
(cd tool/sync_probe && flutter test test/fundly_stream_test.dart test/c2_space_streams_test.dart)
tool/sync_probe/cloud/fundly-local/down.sh   # stop PowerSync; the Supabase stack keeps running
```

- `up.sh` restarts the Supabase stack when only the database is running
  (`db start`), since Auth and the API are needed.
- Run `up.sh` again after any `db reset` (including the migration and
  rollback checks, which reset): a reset drops the publication and replication
  slot, so PowerSync starts again with fresh storage.
- After changing `powersync/sync-config.yaml`, restart the service:
  `docker compose restart powersync` in this folder.
- `.env.local` holds two local test users (A, B) with random passwords; it and
  `config.local.json` are git-ignored and never printed.
