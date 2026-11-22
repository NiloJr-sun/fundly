# Cloud sync S6 — existing data and backups (proposal)

Date: 2026-11-22

Status: **approved 2026-11-22** (Decisions 1–7, all as recommended). S6.1
is implemented, verified locally and deployed to the hosted project (2026-11-22).
S6.2 is implemented and verified with automated tests (2026-11-22); the
manual device checks remain. S6.3 is not started. S6 is split into three sub-slices; each is planned in more
detail, implemented, verified and reviewed on its own, and the agent stops
after each.

## Goal

From [CLOUD_SYNC_PLAN.md](CLOUD_SYNC_PLAN.md) S6: a user who signs in can
move the data they already have (the device's signed-out database, or a
backup file) into their account, safely and verifiably, and back up and
restore signed-in data.

Acceptance (unchanged from the plan): an interrupted or retried import
produces no duplicate or missing records; backup formats 1–6 remain
restorable; a second device downloads the complete imported dataset.

## Starting point

- **Signed-out data** lives in the local database (schema v12, integer IDs).
  Signing in opens a separate synced store per user (S4/S5); the two are never
  mixed, and nothing copies local data to the account today.
- **Backups:** format 6, integer IDs, every record with UTC timestamps
  ([backup_exporter.dart](../lib/features/backup/data/backup_exporter.dart)).
  The importer reads formats 1–6, checks the whole file (types, references,
  app rules; archived records may hold history) and replaces all data in one
  local transaction. While signed in, Export and Restore only explain that
  they arrive in S6 (S5 Decision 5).
- **Server writes** go through `fundly_apply_operations`: at most 100 items
  and 256 KB per batch, one atomic transaction per batch, rules checked in the
  `apply_*` functions, `created_at`/`updated_at` set by the server, revision
  1 on insert, tombstones for every delete.
- **New accounts are not empty:** after a device's first download finds no
  categories, `dataset.initialize` adds the 9 default categories (S5.3).
- **Accounts with transactions cannot be deleted**, only archived (G7). Once a
  cloud dataset has real records, a user cannot empty it by hand.

Two consequences:

1. Replaying a dataset through the existing operations would take many
   batches. Other devices would download it half-imported, and replay order
   runs into rules meant for live edits (no new transactions on archived
   accounts, plan-archive blocking, permanent plan deletion requiring no
   history). An import needs its own atomic server operation that checks the
   **final state**, the way a backup restore does locally.
2. An "empty account only" rule would block most real cases, including the
   owner's: the account already holds default categories and test records.
   So S6 also needs an explicit **replace** (Decision 2).

## What does not change

- Financial rules and calculations; derived values (balances, totals, Ready
  to assign, carry-over) are never uploaded.
- The signed-out local database and its schema (v12). An import only reads it.
- Formats 1–6 stay restorable into signed-out mode exactly as today.
- No automatic merging of two datasets, ever.

## Proposed design

### One snapshot shape for every source

Every source becomes the same validated snapshot before upload:

- **This device's signed-out data:** exported in memory with the existing
  exporter (format 6), then parsed by the existing importer.
- **A backup file**, formats 1–7: parsed and validated by the importer, older
  formats upgraded as they are today.

The client then gives every record a **fresh UUID** (v4) and rewrites every
reference. Fresh IDs avoid tombstone clashes (`record_deleted`) when importing
into an account that held records before.

### Server: `fundly_import_dataset` (S6.1)

A new RPC, separate from `fundly_apply_operations`:

`fundly_import_dataset(import_id uuid, mode text, expected jsonb, dataset jsonb)`

- **Modes:**
  - `into_empty`: allowed only when the account has no custom types, accounts,
    transactions or plans, and its categories are exactly the untouched
    defaults (revision 1, unarchived, no plans). Those defaults are removed
    and replaced by the import.
  - `replace`: deletes every record of the owner (tombstoned, as today), then
    inserts the import. `expected` carries the counts the user saw on the
    confirmation screen; if the account changed since (another device wrote),
    the call is refused with `dataset_changed` and the user confirms again.
- **Atomic:** one database transaction under the owner's write lock. Other
  devices see either the old dataset or the complete new one.
- **Idempotent:** a receipt keyed by `import_id` (same table and fingerprint
  rules as batches). Retrying after a lost response returns the first result
  and never imports twice. That makes the import resumable: the client just
  resends.
- **Validates the whole final state server-side**, set-based, with the same
  rules the local importer checks: name rules and uniqueness, allowed accounts
  per transaction type, no self-transfers, category kinds, references, one
  budget account (active Savings/Cash), one linked liability row per Credit or
  Loan account, plan rules, archived and deleted flags, positive amounts.
  Table CHECKs and foreign keys stay as a second line of defence.
- **Preserves** IDs as sent, money in minor units, transaction dates,
  archived / plan-archived / plan-deleted flags, budget account, linked
  liability rows and `created_at`/`updated_at`. Revisions start at 1.
- **Size:** a dedicated limit (proposed 8 MB, about 20,000 transactions),
  checked first; a timing check with 10,000 transactions confirms it fits the
  hosted statement timeout.
- Returns the per-table counts it wrote.

### App: import flow (S6.2)

- **When it is offered:** at sign-in, if this device has signed-out data
  beyond the defaults and has not imported it into this account yet; and any
  time from Profile → "Copy this device's data to your account" (Decision 3).
- **Preview:** side-by-side counts (accounts, categories, transactions, plans)
  of this device's data and the account, and the choice:
  - **Copy to my account** when the account is empty (only untouched
    defaults);
  - **Replace my account's data** when it is not: names the counts that will
    be deleted on every device, offers **Export the account's data first**
    (format 7), and needs a typed confirmation (Decision 2);
  - **Keep my account as it is**: nothing happens; this device's data stays
    in signed-out mode.
- **Before uploading:** waits for pending uploads to finish (a replace while
  changes are queued would delete them); refuses with an explanation if any
  are still waiting or refused.
- **After the server accepts:** waits for the download to complete, then
  **verifies** by comparing, with the existing domain functions, the
  source snapshot and the synced store: record counts, every account's
  balance, this month's Spending/Inflow totals and every Plans row. The user
  sees "Copied and checked" or the first mismatch. A mismatch is treated as a
  bug: nothing is deleted, the source stays untouched.
- **The signed-out data is never changed** (Decision 4). The device remembers
  which account it was copied to and when, and signed-out mode shows that, so
  two copies are not confusing.

### Backups while signed in (S6.3)

- **Format 7:** the same records as format 6 with UUID string IDs. Export
  works signed in (from the synced store) and signed out (integer IDs written
  as their decimal strings, so one exporter serves both).
- **Restore while signed in** uses the import flow above with the file as the
  source (`into_empty` or `replace`).
- **Restore while signed out** reads formats 1–7. Format 7 IDs are mapped to
  new local integers, the way references are checked today.
- The S5 placeholder ("Backups of signed-in data are not available yet") is
  removed.

## Sub-slices

| Slice | Content | Done when |
|---|---|---|
| S6.1 | Server: `fundly_import_dataset`, receipts, final-state validation, both modes, size limit; pgTAP tests (every rule, both modes, non-empty refusal, `dataset_changed`, other owners untouched, tombstones), concurrency tests (import vs. batch writes, two imports), 10,000-transaction timing check; `supabase/IMPORT_API.md`. | Migration applied locally, all server tests pass |
| S6.2 | App: snapshot and UUID mapping, preview, the three choices, pending-upload guard, verification after download, "copied to" marker; unit and widget tests; iOS simulator and Chrome checks against a test account. | Owner's phone data copied and verified |
| S6.3 | Format 7 export (both modes), signed-in restore via import, format 7 restore signed out; tests for formats 1–7 in every direction. | Every format restores under the approved rules |

#### S6.1 detailed plan (approved and implemented 2026-11-22)

**Result:**

- All 789 SQL assertions pass, 100 of them new.
- The 4 import races pass, and `db lint` is clean.
- The timing check imported 10,000 transactions (4.2 MB) in 0.60 s and
  19,000 transactions (7.9 MB) in 1.33 s, locally under an 8 s statement
  timeout. The fallback below is not needed locally.
- The hosted gateway size limit and hosted speed are still unmeasured.
- Contract: [supabase/IMPORT_API.md](../supabase/IMPORT_API.md).
- Not deployed.

Server only. No app, local schema (v12) or backup format changes. It adds one
migration, so it changes the **server schema**: a new backend-only receipts
table and a new RPC. Existing tables, constraints and `fundly_apply_operations`
are unchanged.

**Migration** `supabase/migrations/20261122020000_dataset_import.sql`:

- `public.fundly_import_receipts(owner_id, import_id, request_fingerprint,
  mode, result, created_at)`, primary key `(owner_id, import_id)`, RLS on, no
  grants (like `fundly_write_receipts`). It is a separate table because batch
  receipts are pinned to protocol 1 and hold per-item results.
- `public.fundly_import_dataset(import_id uuid, request jsonb)`, security
  definer, executable by `authenticated` only. Mode, expected counts and
  dataset travel in one versioned body, so one fingerprint covers all of them:

  ```json
  { "version": 1, "mode": "into_empty" | "replace",
    "expected": { "custom_account_types": 0, "accounts": 0, "categories": 9,
                  "transactions": 0, "monthly_plans": 0 },
    "dataset": { "custom_account_types": [...], "accounts": [...],
                 "categories": [...], "transactions": [...], "monthly_plans": [...] } }
  ```

  Records use the download wire shape (snake_case, money and revisions as
  decimal strings, dates `YYYY-MM-DD` with year 0000 mapped as today, UTC
  timestamps), without `owner_id` or `revision`. Missing timestamps are
  set to the import time; categories have none in backups today.

**Order inside the function** (one transaction; any failure changes nothing):

1. Authentication, then size (8 MB) and shape: known keys only, five arrays,
   `version` 1.
2. Fingerprint; take the **same per-user advisory lock as batches**, so an
   import and any device's uploads never interleave.
3. Receipt lookup: same `import_id` and body returns the stored result; a
   different body is refused with `import_key_reused`.
4. Mode check against the current rows:
   - `into_empty`: refused with `dataset_not_empty` unless the owner has no
     custom types, accounts, transactions or plans, and every category is an
     untouched default (default name and kind, revision 1, no flags, no link).
   - `replace`: current counts must equal `expected`, otherwise
     `dataset_changed`, with the current counts in the detail so the app can
     show them again.
5. Load the five arrays into temporary tables (`on commit drop`) with typed
   parsing that reuses the existing helpers (`json_uuid`, `iso_date`,
   `trim_text`, `utf16_length`).
6. **Validate the final state**, set-based, failing on the first broken rule
   with `invalid_import` and a detail of `{table, index, field, rule}`:
   - IDs: UUIDs, unique within the import, not used by any existing row of
     any owner and not retired (otherwise `record_id_unavailable`, which never
     says whose ID it was).
   - Names: trimmed, 1–40 UTF-16 units, unique per table ignoring ASCII case;
     custom type names are not built-in names.
   - Accounts: the custom type exists and has the account's base type; the
     opening balance has the right sign; PHP only; at most one budget account,
     and it is an active Savings/Cash account.
   - Categories: plan group and plan flags follow the table rules; a linked
     row links a liability account in the import, is a Liability-group
     spending category, matches its account's archive status, and is the only
     row for that account; every **active** Credit or Loan account has one.
   - Transactions: the shape rules per type; the allowed account types per
     type (Spending from Savings/Cash or Credit, Inflow to Savings/Cash or
     Credit, Transfer from Savings/Cash to Savings/Cash or Loan, Card Payment
     from Savings/Cash to Credit); no self-transfers; category kind matches
     (Spending needs a spending category, an Inflow category is optional and
     must be an inflow category); linked debt rows are not used as
     categories; positive amounts; payee and note limits. Archived accounts
     and categories may hold history, as in a local restore.
   - Plans: spending categories only, not on a plan-deleted row, one per
     category per month, non-negative amounts.
7. Delete the owner's current rows (plans, transactions, categories,
   accounts, custom types). The existing trigger writes a tombstone for each,
   so other devices remove them at their next download.
8. Insert the imported rows in reference order, with timestamps and flags as
   sent; the revision trigger sets revision 1.
9. Store the receipt and return `{version, import_id, mode, counts}`.

The table constraints and foreign keys stay as a second check. A constraint
error that slips past step 6 is reported as `invalid_import` and is a bug to
fix in step 6.

**Documentation:** `supabase/IMPORT_API.md` (request, response, errors and
the client retry rules: resend the same `import_id` and body after a lost
response, or start again with a new one after `dataset_changed`), and the
file list in `supabase/README.md`.

**Tests:**

- pgTAP `supabase/tests/database/dataset_import_test.sql`:
  - authentication, shape and size refusals;
  - every step 6 rule, failing one fixture each;
  - `into_empty` accepted with untouched defaults and refused after a
    renamed default, an account or a plan;
  - `replace` with matching and with stale `expected`;
  - tombstones for every replaced row;
  - retired IDs and another owner's IDs refused without revealing the owner;
  - timestamps, flags, budget account and linked rows preserved, revision 1;
  - a retry returns the stored result, and a changed body is refused;
  - other owners' rows untouched;
  - year 0000 dates.
- Concurrency, `supabase/tests/concurrency/dataset_import_test.py`, using
  the existing session harness:
  - an import racing a batch: whichever runs second sees the first;
  - two imports with different IDs: the second gets `dataset_changed`;
  - the same `import_id` sent twice at once imports once.
- **Timing check:** a script that builds 10,000 transactions (about 4 MB)
  across 20 accounts with plans and times the call locally under
  `statement_timeout = 8s`, which is Supabase's default for `authenticated`.

**Open risk and fallback:** if the timing check takes too long or the 8 MB
body is too large for the hosted API gateway, the fallback keeps the import
atomic. The app would upload the dataset in chunks to a backend staging
table under the `import_id`, then make one short commit call that runs steps
3–9. That changes the client contract, so it would come back for approval
rather than be built silently.

Done when: the migration applies to a fresh local stack (`db reset`), all
pgTAP and concurrency tests pass, `db lint` is clean, and the timing result is
recorded in this document. Hosted deployment is not part of S6.1. It happens
with the owner's go-ahead before S6.2 uses it.

#### S6.2 detailed plan (approved and implemented 2026-11-22)

Approved with Decisions S6.2-1 to S6.2-4, each as recommended.

**Result:**

- Implemented as planned. 1,087 Flutter tests pass, 44 of them new.
  `flutter analyze` and `dart format` are clean, and the iOS simulator build
  succeeds.
- The client contract runner passes 12 checks on local Supabase, including
  the two new copy cases.
- Not yet done: the manual checks below. That means the simulator and Chrome
  against a test account, the owner's phone against the hosted account, and
  the 10,000-transaction hosted size and timing measurement.

**Changes from the plan:**

- The send-and-retry loop is shared as `CloudDatasetImport`, as planned.
- The checkpoint dialog is now `CheckpointConfirmDialog`, shared by Reset
  all data and Replace. Reset's wording is unchanged.
- A lost response after all retries is not kept as a pending check. The
  screen says to open it again, and the account's counts then show whether
  the copy landed. Copying again would be a full replace, so it cannot
  duplicate records.

App only. There is no server change, no local or synced schema change and
no backup format change. It builds on work already delivered:

- `fundly_import_dataset`, deployed;
- `ImportDataset` and its provider;
- the reset's guards (`signedInExportBlocker` plus "connected");
- the reset's retry rule (same `import_id` and body, at most 3 attempts);
- `LocalBackupSource`, which reads every signed-out record;
- format 7 export, used for the checkpoint before a replace;
- `watchSyncedCounts`.

**Reading this device's data while signed in.** `appDatabaseProvider` throws
while signed in, by design. The copy flow therefore opens the signed-out
database (`fundly`) itself through `databaseOpenerProvider`, reads it in one
transaction with `LocalBackupSource`, and closes it. Nothing else has that
database open while signed in, and it is only ever read.

**What counts as "data on this device".** Anything beyond the untouched
default categories: any custom type, account, transaction or plan, or a
category that is not one of the defaults as created. With nothing to copy,
there is no prompt and no Profile row.

**Request.** `BackupRecords` from the device becomes one `replace` or
`into_empty` request:

- every record gets a fresh UUID (Decision 5), and every reference is
  rewritten through one ID map;
- money is sent as decimal strings and timestamps as UTC (missing ones are
  left to the server);
- the client refuses a request over 8 MiB before sending it, with an
  explanation.

**Flow** (new `CopyDeviceDataScreen`, a full screen rather than a dialog,
since it has several steps):

1. **Guards,** checked on open and again just before sending: connected, a
   full download finished, no uploads waiting, not stuck. On the web, no
   rows the browser cannot read. Refused changes do not block, as for reset.
2. **Preview:** counts for this device and the account, side by side
   (accounts, categories, transactions, plans).
3. **The choice:**
   - **Copy to my account,** when the account holds only untouched
     defaults. Sends `into_empty`.
   - **Replace my account's data,** otherwise. The screen says the account's
     records are deleted on every device signed in as the user's email.
     Step 1 saves a format 7 checkpoint of the account (required, as for
     reset; Decision S6.2-3). Step 2 is typing **replace my data**. Then it
     sends `replace` with the counts the user saw.
   - **Not now,** which changes nothing.
4. **Send:** a network failure or lost response is resent up to 3 times
   with the same ID and body. `dataset_changed` and `dataset_not_empty` say
   the account changed and go back to the preview with fresh counts and a new
   ID. Any other refusal shows its code and says nothing was changed.
5. **Wait** up to 60 s for this device's synced store to show the counts the
   server returned. If the wait runs out: "Copied. This phone will check it
   after it syncs", and the check runs the next time the screen opens.
6. **Check** (Decision S6.2-1): read the synced store with the format 7
   source, map its UUIDs back through the ID map, and compare **every field
   of every record** with the device snapshot. The screen then shows "Copied
   and checked", with the account count, the transaction count and each
   account's balance from `balancesFor()` on both sides. On a mismatch, it
   names the first difference (table, record, field). Nothing is deleted
   either way, and the device data stays as it was.

**Remembering the copy** (Decision 4): the device stores, in its
preferences, which account the data was copied to (user ID, email) and
when, but only after a successful check.

- In signed-out mode, Profile shows "Copied to `<email>` on `<date>`".
- At sign-in, that account is not prompted again.
- The ID map is kept with it until the check passes (the step 5 timeout
  case), then dropped.

**Where it is offered** (Decision 3, Decision S6.2-2):

- **At sign-in.** When the first download finishes, if this device has data
  and it was not copied to this account, a one-time prompt appears: "This
  phone has data from before you signed in", with **Review** (opens the
  screen) or **Not now**. Not now is remembered for that account.
- **On Profile, while signed in.** "Copy this device's data to your
  account", shown while the device has data.

**Shared code.** `CloudDataResetter`'s send-and-retry loop moves into a
small `CloudDatasetImport` that both reset and copy use. Reset behaviour and
its tests stay the same.

**Files likely to change:**

- New:
  - `features/backup/data/dataset_request.dart`: records to request, and
    the ID map.
  - `features/backup/data/device_data_copier.dart`: guards, send, wait,
    check.
  - `features/backup/data/copy_marker.dart`: preferences store.
  - `features/backup/presentation/copy_device_data_screen.dart`.
- Changed:
  - `cloud_data_resetter.dart`: uses the shared send.
  - `profile_screen.dart`: the row, and the signed-out note.
  - `app/home_shell.dart` or the sign-in path: the one-time prompt.
  - `main.dart`: the marker store's provider.
  - Docs: this plan, `IMPORT_API.md` (copy as a client), CLAUDE.md §11 row
    and AGENTS.md on completion.

**Tests:**

- **Request mapping:** every record kind and flag, linked rows, the budget
  account, year 0000, archived history, references rewritten, no integer
  IDs left, and the size refusal.
- **Data on this device:** defaults alone are not data; a renamed default
  is.
- **Copier,** with a fake RPC and stores:
  - both modes and the choice between them;
  - guards before sending;
  - the same ID on retry, and a new ID after `dataset_changed`;
  - the wait timing out, then the deferred check;
  - the check passing, and naming a planted difference;
  - the marker saved only after a passing check.
- **Widgets:**
  - the preview counts;
  - Copy versus Replace shown correctly;
  - checkpoint and typed phrase required for Replace;
  - the error messages;
  - the prompt shown once per account, and Not now remembered;
  - the Profile row hidden without data;
  - the signed-out "Copied to" note.
- **Server contract** (`client_contract_test.py`, local Supabase): a request
  built by the Dart mapping for a full sample dataset is accepted in both
  modes. This shared fixture keeps the client and server rules aligned.
- **Manual:**
  - iOS simulator against local Supabase: copy into a fresh account, then
    replace a non-empty one;
  - Chrome as a second device: it downloads the complete dataset, and the
    balances match;
  - then the owner's phone into the hosted account. After Reset all data
    that account holds only the defaults, so Copy applies; otherwise
    Replace.
  - A large sample (about 10,000 transactions) against the hosted project,
    to measure the gateway size limit and timing that S6.1 left open.

**Limitations:**

- `expected` compares counts only, as for reset. An edit made on another
  device between the preview and the replace, without changing the counts,
  is lost. It is in that device's history only if it exported.
- A copy is a one-time move. Later signed-out changes on this device are not
  copied unless the user copies again, which is a full replace.
- On the web, the signed-out data is the browser's own, so the copy moves
  that browser's data, not the phone's.

**Decisions for the product owner:**

1. **How to check the copy:** compare every field of every record after
   mapping IDs back, and show the balances as the visible summary
   (recommended). Equal records mean every derived value (balances,
   Spending, Plans) is equal too, so this is stricter and simpler than
   recomputing each figure. Alternative: the originally planned comparison
   of counts, balances, this month's totals and Plans rows.
2. **The sign-in prompt:** once per account, with Not now remembered and the
   Profile row always available (recommended). Alternative: prompt at every
   sign-in until copied.
3. **Checkpoint before Replace:** required, as for Reset all data
   (recommended). Alternative: offered but optional.
4. **Typed phrase for Replace:** "replace my data" (recommended).

## Decisions

Approved 2026-11-22: 1–7, each as recommended.

1. **Import mechanism:** a dedicated atomic server import that checks the
   final state (recommended). Alternative: replay through the existing
   operations in many batches, which other devices see half-done and which
   live-edit rules can block.
2. **Non-empty accounts:** allow an explicit **replace** with export-first
   and typed confirmation (recommended; otherwise an account with any real
   records can never receive an import). Alternative: empty accounts only.
3. **When to offer import:** at sign-in when this device has local data,
   plus a Profile entry (recommended). Alternative: Profile entry only.
4. **Local data after import:** keep it untouched, show where it was copied
   (recommended; it is the rollback path). Alternative: offer to delete it
   after a successful check.
5. **IDs:** fresh UUIDs for every import, including format 7 files
   (recommended; avoids tombstone clashes). Alternative: keep format 7 UUIDs
   when possible.
6. **Backup format 7** with UUID string IDs, used by both modes (recommended).
   Alternative: keep integer format 6 for signed-out exports and use format 7
   only signed in.
7. **Restore while signed in** goes through the import flow (recommended).
   Alternative: keep it blocked and allow only signed-out restore.

## Risks

- `replace` deletes data on every device. Mitigated by export-first, typed
  confirmation, the `expected` counts check and the pending-upload guard.
  Another device's unsent changes to deleted records are refused and listed in
  Refused changes (S5.4), not lost.
- The server repeats the local importer's rules in SQL; the two can drift.
  Shared test fixtures (the same invalid snapshots run against both) keep them
  aligned.
- Hosted request size and statement timeout limits are unverified for large
  imports; S6.1 measures them before the app depends on them.
- Verification compares derived values on two stores; it depends on the
  download having fully completed, which the flow waits for explicitly.
