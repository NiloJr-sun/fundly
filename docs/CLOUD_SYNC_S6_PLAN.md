# Cloud sync S6 — existing data and backups (proposal)

Date: 2026-11-22

Status: **proposal, not approved.** Nothing here starts until the product
owner approves the decisions below. S6 is split into three sub-slices; each
is planned in more detail, implemented, verified and reviewed on its own, and
the agent stops after each.

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

## Decisions

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
