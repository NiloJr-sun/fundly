# Cloud sync S1 — compatibility findings

Updated: 2026-11-18 (Asia/Manila)

**The owner accepted connection feasibility and requested development to proceed
on 2026-11-18.** Outstanding verification below is retained as development and
release work, rather than reported as passed. The approved defaults are
recorded in [the plan](CLOUD_SYNC_PLAN.md). The isolated runnable package and
live setup instructions are in [tool/sync_probe](../tool/sync_probe/README.md).
No Fundly production code, dependencies, database, or backup format changed.

## What has been established

The real PowerSync SDK can share a SQLite connection with Drift 2.35.4 on the
native test runner, Chrome, and the iOS simulator. Tests exercise actual local
storage and the PowerSync CRUD queue, rather than replacing the database with
a fake. Both PowerSync-managed views and developer-managed raw tables work
with typed Drift reads, writes, transactions, and watch streams.

The important difference is integrity enforcement: the probe demonstrates that
managed views accept a negative amount despite the corresponding Drift table's
CHECK declaration. Raw tables enforce that CHECK and deferred foreign keys.
Fundly's existing guarantees therefore favor **raw tables managed by Drift**.
PowerSync's documentation also requires deferred foreign keys because downloaded
rows may arrive in any order inside a checkpoint transaction; related rows must
share a sync priority. [Raw table reference](https://docs.powersync.com/client-sdks/advanced/raw-tables)

The prototype caught and fixed non-idempotent trigger setup on reopening. Its
raw-table triggers are now recreated transactionally. Synced columns are
explicitly filtered and empty updates ignored, so a local-only column added by
a schema migration does not become an upload.

## Dependency resolution and build evidence

The prototype has its own `pubspec.yaml` and committed-candidate lockfile;
Fundly's root dependency resolution remains unchanged. The following versions
resolved together and compile in the probe:

| Package | Resolved version | Purpose |
|---|---|---|
| drift | 2.35.4 | Match Fundly's current ORM. |
| drift_sqlite_async | 0.3.1 | Share PowerSync's connection and notifications. |
| powersync | 2.6.2 | Local sync queue and download client. |
| sqlite_async | 0.14.8 | Explicit browser SQLite options. |
| sqlite3 | 3.5.2 | Version resolved with Flutter integration tests. |
| supabase_flutter | 2.18.3 | Auth/session handling and upload RPC calls. |
| google_sign_in | 7.2.0 | Native Google SDK build compatibility only. |
| uuid | 4.6.0 | Shared record IDs and stable upload batch IDs. |

`path_provider` supplies an app-private native directory. `drift_dev`,
`build_runner`, `flutter_test`, and `integration_test` supply generation and
verification. Production dependencies still belong in their approved delivery
task; do not copy the prototype dependency list into Fundly automatically.

Google sign-in has **not** been exercised. The live probe uses disposable
email/password users to test database connectivity independently of OAuth
configuration. Android, physical iOS devices, Safari, and mobile web have not
been verified. Documentation labels the Flutter web/Drift integration beta;
the release matrix remains necessary. [Drift adapter reference](https://docs.powersync.com/client-sdks/orms/flutter-orm-support)

## Verification record

Commands below are run from `tool/sync_probe/` unless stated otherwise.

| Check | Evidence / limit |
|---|---|
| `flutter pub get` | Dependencies resolved; root pubspec/lockfile unchanged. |
| `dart run build_runner build` | Typed Drift models generated. |
| `sh setup_web.sh` | Reproducible asset setup script prepared; equivalent setup command and copy were run. |
| `flutter test` | 19 tests passed: 18 database/queue checks plus one local HTTP rejection/retry check. |
| `flutter test --platform chrome --dart-define=PROBE_ASSET_PREFIX=/packages/fundly_sync_probe/web_assets/ test/probe_test.dart` | 18 checks passed in Chrome. |
| `flutter test integration_test/probe_test.dart -d 79F16085-EADB-44A0-9A76-95EBB06B238C` | 18 checks passed on iPhone 16 Plus simulator (iOS 18.6). |
| `flutter build ios --simulator --debug` | Probe built successfully, including Google native SDK dependency resolution. |
| `flutter build web` | Probe built successfully. |
| `flutter analyze` (probe and root) | No issues found in both. |
| `flutter test` (root) | 844 Fundly regression tests passed. |
| `dart format .` (root) | Run; final zero-change verification recorded before handoff. |

Initial Chrome attempts failed because Flutter's test server did not serve
the default worker/WASM paths. Package-served test assets fixed this. Normal
web builds serve the version-matched files from the probe's own `web/` folder;
Fundly's existing WASM/worker assets were not replaced.

The local HTTP test verifies that a rejected RPC response leaves the SDK queue
intact, and that the same payload/idempotency key is retried after reopening.
It does **not** prove hosted SQL validation, successful server-side deduplication,
PowerSync downloads, or rejected-operation recovery. A Docker validation check
found no running daemon, so no local PostgreSQL execution is claimed.

Three additional live, unauthenticated HTTP checks against the owner's
Supabase project returned HTTP 401 / PostgreSQL `42501`: reads of
`probe_parents`, reads of `probe_entries`, and calls to `probe_apply_batch`.
This establishes that the disposable objects exist and anonymous access is
denied. It does not establish authorized access or isolation between two
signed-in users.

## Proposed implementation choices after the live checks

1. **Use UUIDs consistently in the synchronized dataset.** The prototype proves
   UUID parent/child writes. Converting all synchronized references avoids a
   permanent translation layer at every repository, upload, download, and
   backup boundary. A durable integer/UUID map was assessed as an alternative,
   but a full mapping-based implementation was not built or verified. Preserve
   legacy integer IDs in the untouched signed-out database; migration uses one
   stable mapping for the whole imported dataset.
2. **Use a separate per-user raw-table SQLite database.** Drift owns its
   versioned DDL/migrations; PowerSync owns replication and its internal queue.
   Install capture triggers after DDL, refresh them when synced columns change,
   enable foreign keys on writer connections, and configure downloads only
   after raw tables/mappings exist. Production connection re-creation behavior
   and the full Fundly constraint set still need testing.
3. **Upload atomic operations with durable idempotency.** A locally persisted
   installation UUID plus stable queued operation IDs yields a repeatable
   batch UUID. The prepared probe RPC records successful batches in a
   backend-only receipt table and commits the records and receipt together.
   Acknowledge the local queue only after the RPC succeeds. The live retry
   test must confirm this across a lost response.
4. **Reject stale revisions without dropping the user's change.** Capturing
   the previous parent revision works in both table modes. The disposable RPC
   checks parent revisions, but it does not implement the final financial
   conflict protocol. Persisting a rejected operation and reconciling its
   dependent edits without blocking unrelated writes remains an open design
   proof. The probe deliberately retains and blocks on an intentionally
   rejected batch; this is diagnostic behavior, not the release behavior.
5. **Keep backups explicitly versioned.** A UUID-based synchronized export will
   need an approved new format, and formats 1–6 need validated conversion.
   Preserve local mode's existing backup behavior; implement the approved
   signed-in restore restriction before enabling synchronized use.

These choices are recommendations supported by partial S1 evidence. They do
not authorize a production schema migration or changes to financial rules.

## Hosted setup and remaining S1 gates

The owner supplied Supabase Tokyo and PowerSync endpoints and a public
publishable key. They are stored only in ignored `config.local.json`. The owner
has created the disposable tables and confirmed that the connection works. Select
`probe_parents` and `probe_entries` for replication; `probe_receipts` stays
backend-only. Client downloads are independently scoped by authenticated user
in the prepared Sync Streams configuration. [Supabase integration guide](https://docs.powersync.com/integrations/supabase/guide)

Subsequent live setup resolved an audience rejection by saving the Supabase
client authentication configuration, and resolved `No sync config available`
by deploying the probe's user-filtered Sync Streams. The owner supplied a
screenshot showing `connected: true`, `hasSynced: true`, and `error: null`.
The owner then confirmed matching record IDs across clients, offline creation
followed by reconnect, synchronized deletion, and isolation in a second user
session. These are user-observed results; no automated two-client run or direct
API isolation test is claimed. Test-user creation was performed through the
admin API using the ignored local environment file; no confirmation email was
sent and credentials were not printed.

Outstanding verification carried forward (not waived for production release):

- Confirm PowerSync's source connection, client JWT authentication, and stream
  deployment; confirm that SQL compiled and its security rules behave correctly.
- Automate iOS ↔ web uploads/downloads, offline reconnect and deletion; explicitly
  verify restart and multi-tab behavior beyond the owner's manual checks.
- Verify user isolation through direct upload API attempts and download streams,
  beyond the owner's second-user UI check.
- Prove backend transaction rollback and idempotent retry after a lost response.
- Exercise a real server rejection and demonstrate the final recovery design,
  including unrelated operations and dependent queued edits.
- Complete the chosen ID strategy comparison and document remaining production
  schema/backup changes as the concrete S2 proposal.

The owner's latest instruction authorizes proceeding with development planning.
Review [the S2 proposal](CLOUD_SYNC_S2_PLAN.md) before implementing its schema
and API changes. No production data should be imported into the probe.
