# Shared spaces C0: local environment

Setup for the C0 sync prototype ([plan](../../../../docs/SHARED_SPACES_C0_PLAN.md),
approved 2026-11-24). Everything runs **locally on the Mac** (Decision C0-1,
local fallback: the PowerSync free plan allows one instance, which is
Fundly's production one):

| Part | Where |
|---|---|
| C0 Supabase stack (`supabase/`, project `fundly-c0`) | API and Auth `http://127.0.0.1:56321`, database port `56322`; separate from Fundly's local stack (`5532x`), both can run |
| PowerSync open edition `journeyapps/powersync-service:1.29.1` | `http://127.0.0.1:56380`, telemetry off |
| PowerSync bucket storage, `postgres:17.6-alpine` | Docker volume only, not exposed |

Nothing here touches Fundly's production Supabase project or PowerSync
instance. Never pass `--remote` with `--workdir` pointing here; never deploy
`powersync/sync-config.yaml` to the hosted dashboard.

## Use

From the repository root:

```sh
tool/sync_probe/cloud/c0/up.sh            # start; writes config.local.json and .env.local
set -a; . tool/sync_probe/cloud/c0/.env.local; set +a
python3 tool/cloud_checks/c0_connection_check.py
tool/sync_probe/cloud/c0/down.sh          # stop, keep data
tool/sync_probe/cloud/c0/down.sh --wipe   # stop and delete all C0 data and test users
```

`up.sh` is safe to rerun. It creates the three test users on first run
(A owner, B member, C outsider; `c0-a@example.test` and so on) with random
local passwords in the git-ignored, chmod 600 `.env.local`. Their values are
never printed. The passwords in `docker-compose.yaml`, `powersync/service.yaml`
and the replication migration are fixed local-stack values, like the stack's
own `postgres:postgres`.

## Files

| File | Purpose |
|---|---|
| `supabase/config.toml` | The C0 local stack: API, database and Auth (email sign-up without confirmation); everything else off |
| `supabase/migrations/…_c0_schema.sql` | `c0_spaces`, `c0_space_members`, `c0_entries`, backend-only `c0_receipts`, membership RLS and the write functions |
| `supabase/migrations/…_c0_replication.sql` | `powersync_role` and the `powersync` publication with exactly the three synced tables |
| `docker-compose.yaml` | PowerSync service and its storage database |
| `powersync/service.yaml` | Replication from the C0 stack, Postgres storage, Supabase JWKS client auth (audience `authenticated`) |
| `powersync/sync-config.yaml` | `c0_my_spaces` (auto) and `c0_space_entries` (per space, `space_id` parameter, membership subquery) |
| `up.sh`, `down.sh`, `local_env.py` | Start and stop; write the git-ignored config and test users |
| `../../../cloud_checks/c0_connection_check.py` | C0.1 done check |

## Verification log

| Date | Check | Result |
|---|---|---|
| 2026-11-24 | Schema rehearsed on Fundly's local database inside a rolled-back transaction, with three stand-in users | 21 of 21 assertions passed: members read only their spaces; outsider sees nothing and cannot write or add itself; editor writes; viewer reads but cannot write; removed member sees nothing and cannot write; stale revision refused; same batch applied once; last owner cannot leave or demote itself; deleting a space removes its entries; receipts unreadable; anon cannot call the write function. Nothing left behind |
| 2026-11-24 | `up.sh` from scratch, then again | Both migrations applied; `wal_level` logical; publication lists exactly the three c0 tables; Auth signs with ES256 and serves JWKS. PowerSync 1.29.1 accepted the sync config (subquery and `subscription.parameter`), created its replication slot and replicates the three tables. Second run reused the users |
| 2026-11-24 | `c0_connection_check.py` | 7 of 7 passed: three users sign in; PowerSync ready, accepts a session, rejects a tampered token with `401 PSYNC_S2101`; anonymous read denied; receipts unreadable; A's new space invisible to B and C; check space deleted. Also refuses configs pointing at production |
| 2026-11-24 | `down.sh` then `up.sh`, check rerun | Data and users kept; check passed; Fundly's local database kept running throughout |
