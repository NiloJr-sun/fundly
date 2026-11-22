# Cloud sync S5 — synchronize repositories (proposal)

Date: 2026-11-22

Status: **approved 2026-11-22** (Decisions 1–4; Decision 5 is confirmed when
S5.5 starts). S5.1–S5.4 are implemented; S5.5 is not started. S5 is split into five sub-slices; each is planned in more detail,
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

#### S5.3 detailed plan (approved and implemented 2026-11-22)

Owner choices: a refused batch stays queued ("Sync stuck") until S5.4;
`uuid` and `flutter_timezone` added; the owner deploys the migration with
`supabase db push`; defaults are requested after a device's first complete
download. Implemented as planned. The queue was first proved on the real SDK
(a hand-inserted `powersync_crud` row comes back from
`getNextCrudTransaction` with its JSON intact). Verified: server lint, pgTAP
(679), every concurrency runner plus `dataset_initialize_test.py`, and the new
`supabase/tests/client_contract_test.py`: an offline session of every write
kind (40 batches) is accepted in order by the local server, a retry is
idempotent, and the server's rows equal the device's, revisions included.
App: format, analyzer, 955 tests, iOS simulator and web builds. The live
two-device check is the owner's step below.

**Queue mechanism.** No capture triggers. Each signed-in write is one local
SQLite transaction that (1) changes the raw tables optimistically and
(2) inserts **one** row into PowerSync's `powersync_crud` queue:
`op = 'PUT'`, `type = 'fundly_batch'`, `id` = a new batch UUID, `data` = the
protocol-1 `{"version": 1, "items": [...]}` envelope. The batch UUID and
payload are fixed at that moment, so every retry sends identical bytes.
PowerSync holds downloads back while the queue is non-empty and until the
server's write checkpoint arrives, so optimistic rows are not overwritten
half-way. First step of the slice: prove this with the real SDK on the host
(a manual `powersync_crud` insert appears in `getNextCrudTransaction`, and a
download does not overwrite a pending row).

**Uploader.** `uploadData` takes the oldest queued transaction, calls
`fundly_apply_operations(batch_id, operations)` and classifies the outcome
using SYNC_PROTOCOL.md:
- accepted → complete the queue item; the download confirms the rows;
- transient (network, 5xx, `40001`/`40P01`/`55P03`/`57014`/`57P01`/`53xxx`/
  `08xxx`, expired session) → throw, PowerSync retries the same item later;
- rejected or blocked → **kept in the queue** (never discarded), status line
  shows "Sync stuck: <code>". S5.4 adds the rejection log that lets the
  queue move past a final rejection.

**Revisions.** Every server update adds 1 to the row's revision (trigger
`fundly_set_revision`). Optimistic updates do the same locally, and skip the
row when the server would skip it (no-op archive, unchanged linked
category). A queued edit therefore carries the revision the server will
have after the earlier queued edits, so two offline edits of one record in a
row are accepted. A mismatch is a `revision_conflict`, which is S5.4's case.

**Writes per repository** (the synced repositories stop throwing):

| Repository method | Operation(s) | Optimistic local effect |
|---|---|---|
| Transaction create/update/delete | `transaction.*` | the row |
| Account create | `account.create` (+ `linked_category_id` for Credit/Loan) | account + its liability row |
| Account update / archive / delete | `account.update` / `set_archived` / `delete` | account; liability row name/archive; budget flag cleared on archive; linked row detached on delete |
| Budget set / clear | `account.set_budget` (`previous_budget` = the observed one) / `clear_budget` | flags on both accounts |
| Custom type create/update/delete | `custom_type.*` | the row |
| Category create/rename/group/archive/delete | `category.*` | the row; its plans on delete |
| Plan save / clear | `plan.save` with `previous` = the observed plan | the plan row (removed when no Target and zero Assigned) |
| Plan archive / unarchive / delete permanently | `plan.set_archived` (with `timezone`) / `plan.delete_permanently` | category flags; plans removed on delete |

Each method first runs the same validation as local mode (names, account and
category rules, plan rules), so the user sees the same messages offline; the
server stays the final judge. The financial rules are not re-implemented:
transaction validation reuses the existing domain checks. New IDs are UUID v4.
Money and revisions are sent as decimal strings, dates as `YYYY-MM-DD`.

**Default categories (Decision 4).** A new migration adds
`dataset.initialize` to `fundly_apply_operations`: under the per-user lock,
if the owner has no categories it inserts the nine defaults (Rent,
Utilities, Internet, Subscriptions, Food & Groceries, Fuel, Miscellaneous,
Salary, Other income) and lists them in `changes`; otherwise it is a no-op.
pgTAP tests plus a concurrency case (two devices initialize at once → one
set). The app queues it once per device, after that device's first complete
download finds no categories; the categories arrive by download (no
optimistic copy). Deploying the migration to the hosted project is an owner
step (`supabase db push`), done before the app build that uses it.

**Plan archive timezone.** `flutter_timezone` 5.1.1 provides the IANA zone
(for example `Asia/Manila`) that `plan.set_archived` requires.

**Other app changes.**
- `canEditProvider` and the "view only" messages are removed; export and
  restore stay unavailable while signed in (Decision 5, S6).
- Status line: "N changes waiting to upload" while the queue is non-empty;
  "View only" is dropped.
- Signing out keeps the store file, so queued changes upload at the next
  sign-in of the same user (the warning on sign-out is S5.5).

**Dependencies.** `uuid` 4.6.0 (already in the lock file as a transitive
dependency; becomes direct) and `flutter_timezone` 5.1.1. No schema change in
local mode; the synced database schema stays v1 (the queue lives in
PowerSync's own tables).

**Tests.** Per method: the queued envelope (exact JSON) and the optimistic
rows, against the in-memory synced database; the revision chain (two queued
edits); uploader classification with a fake RPC (accepted, each transient
class, rejected, blocked; retry sends the same batch UUID and payload);
default-category trigger runs once; real-SDK host test for the queue and the
held download. Server: pgTAP and the concurrency runner for
`dataset.initialize`. Full suite, analyzer, iOS and web builds.

**Live check (owner).** On iOS and Chrome signed in as the same user: create
an account, a transaction and a plan offline (airplane mode / DevTools
offline), restart, reconnect; both devices show the same balances, Spending
totals and Plans; check in the SQL editor that each record exists once.

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

#### S5.4 detailed plan (approved and implemented 2026-11-22)

Approved as proposed (revert by marking every row, schema v2, list on
Profile only, dismiss deletes). Implemented as planned. The open risk is
settled in the SDK: once the queue is empty, PowerSync always requests a write
checkpoint and applies the next checkpoint that includes it, refused uploads
included. The real-SDK test emulates that step. Verified: the real-SDK
revert and uploader tests, the v1 → v2 migration test, the description and
screen tests, the local contract runner (now also a real `revision_conflict`
and `record_deleted`), full suite, analyzer, iOS simulator and web builds.
The live two-device check is the owner's step below.

**What the host experiment showed (2026-11-22).** I tested the real
PowerSync SDK 2.6.2, feeding checkpoints through its core extension
(`powersync_control`), with no service involved:
- An optimistic insert, edit or delete that PowerSync was not told about
  **survives** every later download. Without extra work, a refused change
  would therefore stay on the device for good. The open proof from S2.3 fails
  as things stand.
- Rows listed in PowerSync's `ps_updated_rows` table are put back to the
  server's version by the next applied checkpoint: a refused insert is removed,
  a refused edit is undone and a refused delete comes back. This is the same
  mechanism PowerSync uses for its own managed tables. It runs only while the
  upload queue is empty, so changes still queued are never overwritten.

**Revert (Decision S5.4-1).** When a batch is refused, the device marks
**every** synced row in `ps_updated_rows`: each row of the five tables, plus
every row the download log holds, so locally deleted rows are covered too.
This happens in the same local transaction as the log entry. Once the queue
is empty, the next checkpoint puts every row back to the server's state. A
refusal is rare, and the dataset is one person's records, so redoing them all
costs little and needs no knowledge of what each write touched (side effects
such as liability rows and plans removed with a category included).
- Alternative: mark only the rows each write touched. That means more code in
  every repository and a missed side effect stays wrong.
- Alternative: rebuild rows from the download log ourselves. That
  reimplements PowerSync.

**Rejection log (local schema change: synced database v1 → v2).** A new
local-only table `sync_rejections` that PowerSync does not sync:

| Column | Meaning |
|---|---|
| `batch_id` (key) | The refused batch's UUID. Writing the same one again is ignored, so a crash and retry cannot add it twice. |
| `kind` | `rejected` or `dependency_rejected` |
| `code`, `detail` | The server's message code and JSON detail (none for dependency) |
| `caused_by` | For `dependency_rejected`: the batch it depended on |
| `operations` | The batch envelope exactly as queued: what the user tried to do |
| `created_ids` | IDs the batch would have created (`*.create`, `plan.save` without `previous`, `account.create`'s `linked_category_id`) |
| `labels` | Names of the records it refers to, taken from the device at the moment of refusal (account, category and type names, the transaction payee), so the screen can describe them after the revert removes them |
| `rejected_at` | UTC |

Not in backups, which are unavailable while signed in. It stays in the user's
store file across sign-out. Migration v1 → v2 creates the table, with
`make-migrations` and a migration test.

**Uploader.** For the oldest batch:
1. If it refers to an ID in any logged entry's `created_ids`, it is not sent.
   It is logged as `dependency_rejected` (with `caused_by`), its own creates
   are added, and it is completed.
2. Otherwise it is sent.
   - Accepted: completed, and any stale log entry for that batch is removed.
     This covers a batch that was refused, the app was killed before the queue
     moved on, and the batch was accepted on retry.
   - Rejected: logged, all rows marked, then completed, and the loop continues.
   - Transient or blocked: unchanged from S5.3. A blocked batch still shows
     "Sync stuck" and is never discarded.

**Screen: "Refused changes".**
- **Opening it:** while the log has entries, the Profile status line adds
  " · 2 changes refused · Review", shown in the error colour. Tapping the line
  opens the screen.
- **Each entry** shows:
  - what was tried, built from the operation, its data and the stored
    labels, for example "Edit transaction · Jollibee · ₱250.00 · 20 Nov 2026"
    or "Create account · BPI Savings";
  - why, in plain words: changed on another device first
    (`revision_conflict`, `plan_conflict`, `budget_conflict`); deleted on
    another device (`record_deleted`); depended on a change that was refused
    (`dependency_rejected`); otherwise "the server's rules refused it" plus
    the code;
  - when it was refused;
  - expandable details of the entered values, to reapply by hand.
- **Actions:** Dismiss on each entry, and Dismiss all. There is no automatic
  reapply or merge.

**Files likely to change.**
- `lib/core/sync/`:
  - `synced_tables.dart` and `synced_database.dart` (+ generated code, schema
    v2 snapshot, migration test);
  - `batch_uploader.dart`;
  - new `sync_rejections.dart` (record, write and mark helpers, watch and
    dismiss);
  - `synced_store.dart` (provider; `stuck` now means blocked only).
- `lib/features/sync/presentation/`:
  - `sync_status_line.dart`;
  - new `refused_changes_screen.dart`;
  - new `refused_change_description.dart`.
- Tests and fakes.
- Docs: `SYNC_PROTOCOL.md` (proof result, revert), this plan, `AGENTS.md`.

No server change, no new dependency, no change to local (signed-out) mode.

**Tests.**
- **Real SDK revert:** refused insert, edit and delete are restored after
  marking and a checkpoint; nothing reverts while the queue still holds a
  batch.
- **Uploader** (real SDK queue, fake RPC):
  - a refusal is logged and later batches still upload;
  - dependency chains: an account whose create was refused, then a
    transaction in it, then an edit of that transaction;
  - a re-refusal after a crash does not duplicate the entry;
  - acceptance after an earlier refusal removes the stale entry;
  - transient and blocked behave as before.
- **Migration** v1 → v2.
- **Descriptions** for every operation kind and code.
- **Widgets:** the status line text and tap, the screen's list, Dismiss and
  Dismiss all, and its empty state.
- **Local server:** extend `client_contract_test.py` with a real
  `revision_conflict` and a `record_deleted`. They check that the codes and
  JSON detail the app parses are what the server sends.

**Live check (owner)**, iOS and Chrome, same account:
1. Device A goes offline and edits transaction T. Device B edits T online.
   A reconnects: the entry "changed on another device" appears, and A shows
   B's version of T.
2. A, offline, creates an account and a transaction in it, while B creates
   an account with the same name. A reconnects: two entries (the account
   refused, the transaction dependent), both records are gone from A, and the
   balances match B.

**Risks.**
- `ps_updated_rows` is PowerSync's internal table. The version is pinned, and
  the real-SDK test fails if an upgrade changes its behaviour.
- The revert needs a checkpoint after the queue empties. PowerSync asks for
  one after uploads, but a refusal changes nothing on the server, so the live
  check must confirm one arrives. If it doesn't, the revert waits for the next
  server change or reconnect. I'll report which happens.

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

Approved 2026-11-22: 1 (five slices), 2 (plain `String`), 3 (read-only,
ended by S5.3), 4 (server `dataset.initialize`, implemented in S5.3). Open: 5.

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
- The raw-table rollback after a rejection relies on PowerSync's internal
  `ps_updated_rows` (proved on SDK 2.6.2, S5.4); recheck on SDK upgrades.
