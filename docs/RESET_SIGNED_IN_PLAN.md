# Reset all data while signed in (Task B) — plan

Date: 2026-11-22

Status: **approved 2026-11-22** (Decisions 1–4, all as recommended). **B1
is implemented** (format 7 export and guards); B2 is not started. Follows Task A (signed-out reset with a
required `YYYY-MM-DD_HHmm_reset_checkpoint.json` export). The product owner
approved bringing format 7 export forward from S6.3 and will deploy the S6.1
migration to the hosted project before this is tried on a device.

## Goal

A signed-in user can reset their account's data the same way a signed-out
user resets this device's data: save a checkpoint, type "delete my data", and
the account starts again with only the default categories, on every device.

## Starting point

- **Server:** `fundly_import_dataset` (S6.1, `supabase/IMPORT_API.md`) with
  `mode: "replace"` already does the hard part in one transaction under the
  owner's write lock: checks `expected` counts (`dataset_changed` if another
  device changed them), deletes every record with tombstones, inserts the new
  dataset, and stores a receipt so a resend never applies twice. It is
  verified locally only and **not deployed**. No app code calls it yet.
- **Synced store:** records live in Drift raw tables
  (`core/sync/synced_tables.dart`) with UUID IDs. `pendingUploadCountProvider`
  counts queued batches; `syncStateProvider` gives the connection and whether
  a full download has finished; `unsafeSyncedRowCountProvider` counts rows the
  web app cannot read exactly.
- **Backups:** format 6 has integer IDs, so it cannot hold synced records.
  Signed in, Export and Restore show "not available yet" (S5 Decision 5).
- **Defaults:** a reset that sends the 9 default categories with fresh UUIDs
  leaves them at revision 1 with no flags. The server's `into_empty` check
  then treats the account as empty, so a later S6.2 copy into it still works.

## Design

### B1. Format 7 export (signed in)

- **Shape:** format 6 exactly (same keys, camelCase, minor units, UTC
  timestamps, no derived values), with `formatVersion: 7` and every `id` and
  reference as a **UUID string**. `schemaVersion` is the synced store's schema
  version. One exporter class reads either store through a small source
  interface, so the field list is written once.
- **Signed-out export stays format 6** until S6.3 adds format 7 restore;
  otherwise signed-out backups would become unrestorable in the meantime.
- **Profile → Export backup** works signed in too (same file, normal
  `fundly-backup-<date>.json` name). The file cannot be restored until S6.3; the
  share step says so once.
- **Refused before exporting** (with the reason shown), because the file would
  not match the server:
  - changes are waiting to upload, or sync is stuck;
  - this device has never finished a full download;
  - on the web, rows the browser cannot read exactly
    (`unsafeSyncedRowCount > 0`).

### B2. Cloud reset

- **Dialog:** the Task A dialog, worded for an account: "Everything in your
  account is deleted **on every device signed in as <email>**." Counts come
  from the synced store. Step 1 exports a format 7 checkpoint
  (`YYYY-MM-DD_HHmm_reset_checkpoint.json`); step 2 is the typed phrase.
- **Guards** (checked when the dialog opens and again just before the call):
  connected, a full download finished, no uploads waiting, not stuck. Refused
  changes do not block: they never reached the server.
- **Call:** `fundly_import_dataset(import_id, {version: 1, mode: "replace",
  expected: <counts the user saw>, dataset: <9 defaults with fresh UUIDs>})`
  through a small `CloudDataResetter` (`features/backup/data/`), using the
  signed-in Supabase client. The default list is the app's
  `defaultCategories`, so it matches the server's list.
- **Errors:**
  - network failure or lost response: resend the **same** `import_id` and
    body up to 3 times (safe: receipts), then say "Could not reach the server.
    Your data was not changed, or will finish deleting when this phone syncs."
  - `dataset_changed`: "Your data changed on another device." Close the
    dialog; the user starts again (new counts, new checkpoint, new ID).
  - anything else (`invalid_import`, `record_id_unavailable`,
    `authentication_required`, …): "The reset was refused (<code>). Nothing
    was changed." These are bugs or an expired session, never retried.
- **After success:** wait up to 30 seconds for this device's synced store to
  show the new counts, then "All data deleted". If it takes longer: "Deleted.
  This phone will show it after it syncs."
- **Other devices** remove the records at their next download (tombstones).
  Their unsent changes to deleted records go to Refused changes (S5.4). No
  notification.

## Files likely to change

- `lib/features/backup/data/backup_exporter.dart`: source interface, format 7.
- New `lib/features/backup/data/synced_backup_source.dart` (reads raw tables).
- New `lib/features/backup/data/cloud_data_resetter.dart` (RPC call, retries,
  error mapping) and its provider.
- `lib/features/backup/presentation/reset_data.dart`: signed-in path, guards,
  wording.
- `lib/features/backup/presentation/export_backup.dart`,
  `signed_in_backup.dart`: allow signed-in export; restore stays blocked.
- `lib/main.dart` (or a provider beside the store): expose the Supabase client.
- Docs: `supabase/IMPORT_API.md` (reset as a client), CLAUDE.md §11 row,
  AGENTS.md current state.

No schema change (local or synced) and no server migration. Backup format 7
is new.

## Tests

- **Exporter:** format 7 from a synced store with every record kind, archived
  and plan flags, linked debt rows and the budget account; IDs and references
  are the UUIDs; format 6 signed out is unchanged byte for byte.
- **Guards:** each refusal (waiting uploads, stuck, offline, no full download,
  unsafe rows on web) blocks both the checkpoint and the reset.
- **Cloud resetter** (fake RPC): request body (mode, expected, 9 defaults,
  fresh UUIDs, no other records); same ID and body on retry; each error maps
  to its message; no retry on refusals.
- **Widget:** signed-in dialog wording and email; checkpoint required; typed
  phrase; `dataset_changed` closes the dialog; success waits for the download.
- **Server contract:** add a reset case to
  `supabase/tests/client_contract_test.py` (local Supabase): replace with
  defaults leaves exactly 9 untouched categories, tombstones every old row,
  and a later `into_empty` import is accepted.
- **Manual:** iOS simulator and Chrome against a local Supabase with two
  signed-in devices; after the S6.1 hosted deployment, the owner's test
  account.

## Limitations

- `expected` compares **counts** only. If another device edits a record
  (same counts) after the checkpoint is saved, that edit is deleted and is not
  in the checkpoint. Closing that gap needs a server change (for example a
  dataset fingerprint), which is out of this task.
- Format 7 files cannot be restored until S6.3.
- A checkpoint counts as saved when the share sheet reports an action (Task
  A); the app cannot check the file was written.

## Decisions for the product owner

1. **Export backup works signed in** (format 7, not restorable until S6.3)?
   Recommended: yes. Alternative: only the reset checkpoint uses format 7.
2. **Signed-out export stays format 6** until format 7 restore exists?
   Recommended: yes.
3. **Accept the counts-only `expected` check** for now (limitation above)?
   Recommended: yes; revisit with S6.2.
4. **Refused changes do not block** a reset, and their log is kept?
   Recommended: yes.

## Order

B1 (format 7 export, guards) then B2 (cloud reset), each verified and
reported on its own, stopping after each.
