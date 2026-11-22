# Cloud sync S5 — synchronize repositories (proposal)

Date: 2026-11-22

Status: **approved 2026-11-22** (Decisions 1–4; Decision 5 is confirmed when
S5.5 starts). S5.1 and S5.2 are implemented; S5.3–S5.5 are not started. S5 is split into five sub-slices; each is planned in more detail,
implemented, verified and reviewed on its own, and the agent stops after each.

## Starting point

- **Server (done in S2/S3):** the five tables, the `fundly_apply_operations`
  RPC with 19 operations, idempotent batch receipts, rejection details and
  tombstones are deployed to the hosted Tokyo project. PowerSync (JP) streams
  each user's own rows ([powersync/sync-config.yaml](../powersync/sync-config.yaml)).
  The client contract S5 must implement is
  [supabase/SYNC_PROTOCOL.md](../supabase/SYNC_PROTOCOL.md).
- **App (done in S4):** Google sign-in, and one local database per signed-in
  user. That database uses the v12 integer-ID schema and syncs nothing; it is
  a disposable preview that S5 replaces (S4 Decision 1, approved).
- **Evidence (S1):** PowerSync 2.6.x shares a connection with Drift; raw
  tables keep Fundly's CHECK constraints and deferred foreign keys, managed
  views do not. Chrome and the iOS simulator were proven in the probe.
- **Integer IDs** are confined to 5 domain models and about 36 usages in 16
  files under `lib/`.

What does not change in any S5 slice: financial rules and calculations, the
signed-out local database (schema v12, integer IDs), backup formats 1–6 for
local mode, and the server schema unless Decision 4 is approved.

## Sub-slices

### S5.1 — Domain record IDs as strings (refactor only) ✅ 2026-11-22

Done: `lib/core/database/record_id.dart` holds the only conversion
(`recordIdOf`, `rowIdOf` and nullable forms; a non-integer ID is rejected).
Only data-layer code (repositories, row mappings, backup importer) converts.
Backup export still writes integer IDs (format 6 unchanged; the exporter
test asserts integers). Verified: `dart format`, `flutter analyze` (no
issues), `flutter test` (895 passed), iOS simulator and web builds.

Domain models, providers and screens use `String` record IDs. The local
database keeps its integer columns; repositories convert at the boundary
(`'42'` ⇄ `42`). No schema, backup, UI or behavior change; the existing test
suite is the proof, plus tests for the conversion.

Why first: the synced store uses UUID text IDs. Making the rest of the app
ID-agnostic before any sync code keeps later slices focused on sync.

### S5.2 — Synced store with downloads (signed-in is read-only)

- Add PowerSync and its Drift bridge (versions rechecked; S1 resolved
  `powersync` 2.6.2, `drift_sqlite_async` 0.3.1, `sqlite_async` 0.14.8,
  `uuid` 4.6.0). Web gets PowerSync's worker and WASM assets; the signed-out
  database's existing web assets must keep working.
- A new per-user database with Drift-owned **raw tables** mirroring the five
  server tables (UUID `id`, `revision`, timestamps), deferred foreign keys and
  the same CHECKs. S4 preview databases are discarded, not migrated.
- Connect with the Supabase session; download the user's rows. Repositories
  read from it through the same interfaces as local mode.
- Signed in, the app is **read-only** in this slice (Decision 3): add/edit
  buttons explain that editing arrives with sync uploads.
- Download safety from S3: refuse or flag money/revisions outside ±(2^53−1) on
  web; map year 0000 dates explicitly.

Proof: rows created through the API with a test user appear on iOS and in
Chrome, and disappear when deleted; signed-out mode is untouched.

#### S5.2 detailed plan (approved and implemented 2026-11-22)

Owner choices: delete the S4 preview database; keep add/edit buttons and
explain on tap. Implemented as planned. Additions: export is also unavailable
while signed in (it read the local database; S6 designs signed-in backups),
and `path_provider` became a direct dependency (same locked version).
Verified: format, analyzer, 920 tests (including the real PowerSync SDK on
the host inferring the raw-table mapping and notifying Drift), iOS simulator
and web builds with the cloud config, signed-out web smoke test. The live
download check on iOS and web is the owner's step below.

**Dependencies** (all resolved together in S1; latest checked today):
`powersync` 2.6.2, `drift_sqlite_async` 0.3.1, `sqlite_async` 0.14.8.
`uuid` waits for S5.3. Web gets PowerSync's `powersync_db.worker.js` and its
`sqlite3.wasm` under `web/powersync/`, so the signed-out database keeps
drift's own `web/sqlite3.wasm` and `drift_worker.js` unchanged.

**Configuration:** a fifth build key, `FUNDLY_POWERSYNC_URL` (the public JP
instance URL already used by the probe), in `config/cloud.json`, the example
file, `CloudConfig`, the Vercel build script and Vercel's variables. Without
it the build stays exactly as today.

**Synced store** (`lib/core/sync/`):
- `SyncedDatabase`, a second Drift database with five raw tables matching the
  downloaded columns in `powersync/sync-config.yaml`: UUID text `id`,
  `revision`, text timestamps, the same CHECKs, deferred foreign keys. Its
  own schema version 1 and migration snapshots, separate from v12.
- Opened through PowerSync with raw-table download mappings only. No capture
  triggers (nothing is written locally until S5.3).
- One file per user, `fundly_sync_<user id>`. The S4 preview database
  `fundly_user_<user id>` is deleted when the synced store first opens
  (S4 Decision 1). The signed-out `fundly` database is never touched.
- Connects with the Supabase session; disconnects and closes before another
  identity's store opens.

**Repositories:** `Synced…Repository` for each of the five, implementing the
existing repository interfaces. Reads map rows to the same domain models, so
every screen and calculation is reused. Writes throw `ReadOnlyStoreException`.
Providers pick local or synced by identity.

**Read-only while signed in:** each add/edit/delete/archive entry point checks
one `canEditProvider`; when false it shows "Editing arrives with sync uploads"
instead of opening the form. Profile's line becomes "Signed in as … · Receiving
data only" with the PowerSync connection state (connected, offline, error).

**Download safety:** money and revisions outside ±(2^53−1) are flagged and the
row is skipped with a visible error on web; year 0000 dates map explicitly.

**Tests:** synced repositories against an in-memory `SyncedDatabase` (mapping,
filters, balances identical to local mode for the same data); store
selection and cleanup per identity; read-only entry points; config parsing.
Full suite, analyzer, iOS and web builds.

**Live check (owner):** run a provided SQL snippet in the Supabase SQL editor
that inserts a sample account, category and transaction for your own user
ID; sign in on iOS and web and see them appear; delete them and see them go.

### S5.3 — Uploads

- Every signed-in repository write becomes one local transaction: the
  optimistic rows plus one queued operation batch with a stable batch UUID.
- The connector uploads one batch per local transaction to
  `fundly_apply_operations`, retrying transient failures with the **same**
  batch UUID and payload (the server's receipts make that exactly-once).
- Dataset initialization: default categories created once per dataset, not
  per device (Decision 4). Liability rows stay server-generated as today.
- Add `flutter_timezone` (or equivalent) for the IANA zone the plan-archive
  operation requires (S2.2C).

Proof: offline create/edit/delete on iOS and web, restart, reconnect, and
both clients converge with identical balances, Spending totals and Plans.
A retry after a lost response produces exactly one record.

### S5.4 — Rejections and recovery

- Final rejections (`revision_conflict`, `record_deleted`, rule violations)
  are stored in a local rejection log, then the queue item completes so later
  writes continue. Dependent queued writes are held as `dependency_rejected`.
- Prove that the next download returns local rows to server state, including
  removing an optimistic insert the server never accepted; otherwise add an
  explicit local revert (open proof from S2.3).
- A simple screen lists rejected changes ("changed or deleted on another
  device") with what the user tried to do, to reapply by hand or dismiss.
  No automatic merging.

### S5.5 — Sync status and safety

- A status line on Profile: synced, syncing, offline (changes saved on this
  device), sync stuck (with detail), replacing "Not syncing yet".
- Sign-out with pending uploads: wait, or sign out anyway after an explicit
  warning; never silently discard. Switching user closes the old connection
  first.
- Restore from backup is blocked while signed in, with an explanation
  (approved default). Export while signed in is deferred to S6 (new UUID
  backup format).
- Multi-tab and cleared-storage behavior on web checked and described.

Acceptance for S5 as a whole: the master plan's S5 criteria and the relevant
rows of its verification matrix, on iOS and Chrome.

## Decisions

Approved 2026-11-22: 1 (five slices), 2 (plain `String`), 3 (read-only),
4 (server `dataset.initialize`). Open: 5.

1. **Slicing:** the five sub-slices above, in this order, one at a time.
2. **ID type:** plain `String` IDs in the domain (recommended; simplest, and a
   legacy integer converts losslessly). Alternative: a `RecordId` extension
   type for compile-time safety at slightly more churn.
3. **Signed-in editing before uploads exist (S5.2):** read-only with an
   explanation (recommended). Alternative: allow local edits that the next
   download may overwrite — confusing and not recommended.
4. **Default categories per dataset:** a new server operation
   `dataset.initialize` that inserts the defaults only if the owner has no
   categories, atomically (recommended; race-free between two devices; one
   small migration plus SQL tests). Alternative: the client creates them with
   deterministic UUIDs after the first download finds no categories, treating
   a duplicate-ID rejection as "already done" (no server change, but relies on
   reading rejection codes correctly).
5. **Backups while signed in:** restore blocked (already approved); export
   hidden until S6 defines the UUID format (recommended), rather than a
   temporary format.

## Risks

- PowerSync's Flutter web/Drift support is labeled beta; Safari and physical
  devices are unverified (S1). Each slice runs on iOS and Chrome.
- Two SQLite WASM builds on web (drift's for local mode, PowerSync's for the
  synced store) must coexist; checked first in S5.2.
- The raw-table rollback after a rejection is unproven (S5.4).
