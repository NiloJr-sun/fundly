# Shared spaces C0: local environment

**Removed 2026-11-24** after the owner's go (Decision C0-3). These files are
the record; `up.sh` recreates the environment from scratch if it is needed
again.

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
| `../../../cloud_checks/c0_space_isolation.py` | C0.2 API checks 3, 9, 10 |
| `defines.sh` | Prints the test users as JSON for `--dart-define-from-file` (simulator and Chrome cannot read the environment); redirect to a chmod 600 file outside the repository |
| `../../test/c0_switching_test.dart`, `../../integration_test/c0_switching_test.dart` | C0.3 switching checks (VM, Chrome, iOS simulator) |
| `../../lib/c0/c0_spaces.dart`, `../../lib/c0_main.dart` | Shared C0 store code; the probe screen for the manual round (`flutter run -t lib/c0_main.dart`) |
| `../../test/c0_space_stream_test.dart` | C0.2 stream checks 1-2, 4-8 and 8b (`set -a; . cloud/c0/.env.local; set +a; flutter test test/c0_space_stream_test.dart` from `tool/sync_probe`) |

## Verification log

| Date | Check | Result |
|---|---|---|
| 2026-11-24 | Schema rehearsed on Fundly's local database inside a rolled-back transaction, with three stand-in users | 21 of 21 assertions passed: members read only their spaces; outsider sees nothing and cannot write or add itself; editor writes; viewer reads but cannot write; removed member sees nothing and cannot write; stale revision refused; same batch applied once; last owner cannot leave or demote itself; deleting a space removes its entries; receipts unreadable; anon cannot call the write function. Nothing left behind |
| 2026-11-24 | `up.sh` from scratch, then again | Both migrations applied; `wal_level` logical; publication lists exactly the three c0 tables; Auth signs with ES256 and serves JWKS. PowerSync 1.29.1 accepted the sync config (subquery and `subscription.parameter`), created its replication slot and replicates the three tables. Second run reused the users |
| 2026-11-24 | `c0_connection_check.py` | 7 of 7 passed: three users sign in; PowerSync ready, accepts a session, rejects a tampered token with `401 PSYNC_S2101`; anonymous read denied; receipts unreadable; A's new space invisible to B and C; check space deleted. Also refuses configs pointing at production |
| 2026-11-24 | `down.sh` then `up.sh`, check rerun | Data and users kept; check passed; Fundly's local database kept running throughout |
| 2026-11-24 | C0.2 `c0_space_stream_test.dart`, three runs | 6 of 6 tests passed each run (checks 1-2, 4-8, 8b). One earlier run failed test 6 because a new member's first sync finished before the membership reached PowerSync; the store now waits for its space to appear (finding 2 in the plan) |
| 2026-11-24 | C0.2 `c0_space_isolation.py`, two runs | 7 of 7 passed: outsider reads and writes nothing; same batch applied once; 20 concurrent batches from two members all applied; concurrent edits of one revision: one applied, one `40001` |
| 2026-11-24 | After C0.2 | No c0 spaces, members or entries left; probe `flutter test` 19 passed, 7 skipped (live checks without credentials); probe analyze clean; Fundly root format, analyze and 1156 tests pass |
| 2026-11-24 | C0.3 `c0_switching_test.dart` on the VM, the iPhone 16 Plus simulator and Chrome (`--platform chrome`, probe asset prefix) | 2 of 2 passed on each. Chrome first failed because two users in one page share one Supabase session; B now signs in under `localhost`. C0.2 checks rerun after the shared-code refactor: 6 of 6 |
| 2026-11-24 | C0.3 manual round with `lib/c0_main.dart` on the simulator and in Chrome (owner) | All steps passed: stored copy reused on switching back; B sees only the shared space; edits cross devices; data kept after a reload; two tabs on different spaces stay separate |
| 2026-11-24 | `down.sh --wipe` after the go decision; probe app uninstalled from the simulator | No C0 containers, volumes, config or test-user files left; Fundly's local database still running. Docker images kept (PowerSync 1.29.1, postgres 17.6-alpine) |
