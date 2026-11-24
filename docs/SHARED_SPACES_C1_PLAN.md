# Shared spaces C1: server moves to spaces (plan)

Date: 2026-11-24

Status: **proposed, awaiting approval.** Slice C1 of
[SHARED_SPACES_PROPOSAL.md](SHARED_SPACES_PROPOSAL.md), after the C0 go
([findings](SHARED_SPACES_C0_FINDINGS.md)). The agent stops after each
sub-slice and never commits or pushes. Production writes (`db push --remote`)
are run by the owner.

## Goal

From the proposal: the server's data model moves from "records belong to a
user" to "records belong to a space, and users are members of spaces", with
every existing user's records in their own **Personal** space. Outcome:
**the app behaves exactly as today**, on the new model. Nobody can create a
second space yet (C2) or share one (C3).

C1 is the riskiest slice: it rewrites every write function and constraint on
live data. So it is built and tested locally first, rehearsed on a copy of
production data with a rehearsed rollback, and only then deployed.

## Starting point

- Five synced tables (`custom_account_types`, `accounts`, `categories`,
  `transactions`, `monthly_plans`), each with `owner_id → auth.users`.
  Per-owner rules: `(owner_id, id)` keys used by composite foreign keys, name
  uniqueness for types, accounts and categories, one linked liability row per
  account, one plan per category and month.
- Backend-only tables keyed by owner: tombstones (`fundly_deleted_records`),
  write receipts (`fundly_write_receipts`), import receipts
  (`fundly_import_receipts`).
- Read rule `read_own` (`owner_id = auth.uid()`); writes only through the
  SECURITY DEFINER RPCs `fundly_apply_operations` and `fundly_import_dataset`,
  which pass `actor = auth.uid()` to private functions that filter by
  `owner_id = actor`, under the lock `hashtextextended('fundly:' || actor, 0)`.
  `dataset.initialize` adds the default categories once per owner. Error
  mapping names three unique indexes (`*_owner_name`).
- The `fundly_set_revision` trigger bumps `revision` on every update and
  refuses changes to `id` or `owner_id`.
- PowerSync streams `fundly_user_data` with `WHERE owner_id = auth.user_id()`;
  `owner_id` itself is not downloaded. Apps 1.2.0 and 1.2.1 are in use; the
  minimum supported version is 1.2.0 and server changes must stay additive
  under write protocol 1 ([OPERATIONS.md](OPERATIONS.md)).
- Hosted: 4 Auth users, about 12 MB.

## What does not change

- The app: no code change and no release in C1 (Decision C1-2). Apps 1.2.0
  and 1.2.1 keep working unchanged.
- The PowerSync sync config and publication (Decision C1-3): same stream, same
  columns, no re-download caused by a config change.
- Write protocol 1: same RPCs, same envelope, same result and error codes.
- Financial rules, backup format 7, the local schema (v13).

## Proposed design

### Spaces and members

| Table | Columns | Rules |
|---|---|---|
| `spaces` | `id`, `name`, `personal_of` (user or null), `created_by`, `created_at`, `updated_at`, `revision` | Name 1–40 characters, trimmed. `personal_of` unique: at most one Personal space per user |
| `space_members` | `id`, `space_id`, `user_id`, `role` (owner, editor, viewer), `created_at`, `updated_at` | One row per (space, user); a space always keeps an owner |

Both get RLS (members read their own spaces and memberships, through a
SECURITY DEFINER membership helper as in C0) but **no client grants for
writing and no publication yet**; C2 syncs and manages them.

### A user's Personal space has the user's ID (Decision C1-1)

The Personal space's `id` is the user's ID, `name` "Personal",
`personal_of` the user, and the user is its owner. Then:

- every existing record's space is its current `owner_id`, so the backfill
  copies a value and changes no data;
- the write lock key `'fundly:' || space` equals today's `'fundly:' || actor`
  for Personal, so old and new code serialize the same way during deploy;
- the device store `fundly_sync_<user id>` is already the Personal space's
  store, so C2 needs no re-download for it.

Personal spaces are created for **every existing Auth user** in the
migration, and for a new user on their first write or import (the RPCs create
it if missing; Decision C1-5).

### Records belong to a space

On all five tables:

- **`space_id`** (not null, references `spaces`), backfilled from
  `owner_id`. It replaces `owner_id` in every key, uniqueness rule and
  composite foreign key: `(space_id, id)`, names unique per space, one linked
  row per account per space, one plan per category, month and space.
- **`created_by`, `updated_by`** (Decision 6; Decision C1-4), backfilled from
  `owner_id` and set from the writer from now on. Not synced until C4.
- **`owner_id` stays** as a legacy copy, equal to `space_id` (true for every
  row while all spaces are Personal), because the live stream filters on it.
  A trigger keeps them equal; C2 switches the stream and drops `owner_id`
  (Decision C1-3).
- `fundly_set_revision` also refuses changes to `space_id` and `created_by`.
- **The backfill must not bump revisions.** Updating every row would raise
  each `revision`, and any device with a pending edit would get a revision
  conflict. The migration turns off the revision trigger for the backfill
  only, in the same transaction.

Backend tables: tombstones, write receipts and import receipts gain
`space_id`; tombstones and "record deleted / ID unavailable" checks become per
space; receipts stay per sender, plus the space.

### Reads

`read_own` becomes "member of the record's space" through the membership
helper. For Personal-only data this returns exactly the same rows. The
stream still uses `owner_id`, so PowerSync output is unchanged.

### Writes (protocol 1, additive)

- Every private function takes **(space, actor)** instead of `actor`: space
  for every record filter and lock, actor for permissions and
  `created_by`/`updated_by`.
- `fundly_apply_operations` and `fundly_import_dataset` accept an optional
  **`space_id`** in their request. Without it (every app today), the server
  uses the caller's Personal space, creating it if needed. With it, the
  caller must be a member; writes need owner or editor; import, replace and
  reset need owner. Other cases are refused with the existing `42501`
  refusal, which the app already logs to Refused changes (C0 finding 3).
- Locks, revision conflicts, tombstones, `dataset.initialize` (default
  categories once per space), linked liability rows and import into an empty
  or replaced dataset all work per space.
- The three error mappings move to the renamed indexes (`*_space_name`);
  codes sent to apps are unchanged.

### Docs

`supabase/SYNC_PROTOCOL.md`, `WRITE_API.md`, `IMPORT_API.md`,
`ACCOUNT_API.md`, `PLANS_API.md` describe spaces and the optional
`space_id`; [OPERATIONS.md](OPERATIONS.md) gets the C1 rollback; the proposal
records the C1 decisions.

## Sub-slices

### C1.1: Spaces, space_id and per-space rules (agent, local)

One migration: `spaces`, `space_members`, Personal spaces for every Auth
user, `space_id`/`created_by`/`updated_by` on the five tables and the three
backend tables, the backfill without revision bumps, per-space keys,
uniqueness and foreign keys, the legacy-owner trigger, membership reads, and
the three error mappings. Existing functions keep working because the trigger
fills `space_id` from `owner_id` until C1.2 changes them.

Tests: pgTAP schema tests (every constraint per space; backfill keeps every
value and revision; Personal space and owner membership per user; reads by a
non-member return nothing). All existing pgTAP, concurrency and contract
tests still pass. `make-migrations` is not involved (server only).

### C1.2: Write API per space (agent, local)

A second migration rewriting the private functions to (space, actor), the
optional `space_id`, role checks, per-space locks, tombstones and receipts,
`dataset.initialize` and import per space. Docs above.

Tests, focused on privacy (the proposal's main risk): for **every operation**
(create, edit, delete, archive, plan save, initialize, import, replace),
pgTAP cases for owner, editor, viewer, non-member and removed member, with
memberships inserted directly in SQL (no member API until C2/C3); concurrency
tests for two members writing one space; idempotent retries per sender. The
client contract test (`client_contract_test.py`) and all existing tests pass
**unchanged**, which shows apps 1.2.x are unaffected.

### C1.3: Rehearsal on a copy of production (owner and agent)

1. Owner: app export from the iPhone, then `db dump --remote` (schema and
   data) into a private folder outside the repository (Decision C1-6).
2. Agent: restore the copy into a separate local stack (like C0's), apply
   the C1 migrations and check:
   - row counts, and every existing column of every row identical before and
     after (hash per row), including `revision`;
   - every record's `space_id` equals its `owner_id`; one Personal space and
     owner membership per Auth user;
   - all constraints valid; `db lint` clean; advisors show no new warning
     beyond the intended SECURITY DEFINER RPCs.
3. Run the production stream (`powersync/sync-config.yaml`) on that copy with
   the self-hosted PowerSync from C0, plus `api_isolation.py`,
   `fundly_stream_test.dart` and the contract test, with local test users.
4. **Rollback rehearsal:** apply the prepared rollback migration (below) and
   repeat the checks: data intact, old functions and rules back, tests pass.
5. Delete the production copy and wipe the rehearsal stack.

### C1.4: Deploy and verify (owner runs the push; agent checks)

Following [OPERATIONS.md](OPERATIONS.md): backups (app export and
`db dump`), `db push --remote --dry-run` listing exactly the C1 migrations,
owner-run `db push --remote`, then lint, advisors, the hosted isolation
checks and a short checklist with the **unchanged 1.2.1** on the iPhone and
in Chrome: "Up to date", the real data and balances as before, create, edit
and delete of each record type, one refused change, Plans, and a new test
user's first sign-in getting a Personal space and default categories.
Results go into powersync/README.md's log; docs updated; C1 marked done.

## Rollback plan

Because `owner_id` stays correct on every row, rolling back needs no data
repair:

- **Rollback migration** (written in C1.2, rehearsed in C1.3, kept ready, not
  deployed unless needed): restores the previous function definitions (from
  the current migrations, byte for byte), `read_own`, and the per-owner keys
  and indexes; leaves `spaces`, `space_members` and the new columns in place
  (harmless, unused), with `space_id` nullable again.
- Records written after the deploy are valid under the old model, since
  their `owner_id` is maintained.
- If the push itself fails part-way, nothing from the failed file applies
  (each migration is one transaction); read the error, fix forward.
- Apps need no rollback: they never changed.

## Verification

- Server: `supabase test db` (pgTAP), `db lint`, every concurrency test, the
  contract test, import timing, per the runbook's full local suite.
- App: `dart format`, `flutter analyze`, `flutter test` unchanged and passing.
- Rehearsal and hosted results recorded as observed, with commands.

## Decisions for the product owner

- **C1-1. Personal space ID.** *(Recommended)* The user's own ID: no data
  values change, locks and device store names stay the same.
  Alternative: new random IDs, which rewrites every row's key, changes lock
  keys and forces a re-download of every device's store.
- **C1-2. App changes in C1.** *(Recommended)* None. The server accepts an
  optional `space_id` and defaults to Personal, so apps 1.2.x keep working
  and there is no release or forced update; apps start sending `space_id` in
  C2. This replaces the proposal's "the app moves to the new protocol in the
  same release". Alternative: release an app that always sends the Personal
  `space_id` (more risk, no user-visible gain).
- **C1-3. Sync config in C1.** *(Recommended)* Unchanged; `owner_id` stays as
  an equal copy of `space_id` until C2 switches the stream and drops it.
  Alternative: rename now and redeploy the stream in the same release; a
  wrong order would empty devices until the new config is live.
- **C1-4. Who recorded it.** *(Recommended)* Add `created_by`/`updated_by`
  now (server only; shown in C4), so the write functions are rewritten once.
  Alternative: add them in C4 with a second rewrite.
- **C1-5. Personal spaces for new users.** *(Recommended)* Created by the
  migration for every existing Auth user, and on first write or import for
  new ones. Alternative: a trigger on `auth.users` (Supabase discourages
  triggers on its auth schema).
- **C1-6. Rehearsal data.** *(Recommended)* A real copy of production
  (owner-run dump, private folder outside the repository, deleted after
  C1.3). Alternative: synthetic data only (misses surprises in real rows).

## Risks

- **Privacy.** A wrong membership check would expose finances. Mitigation:
  per-role pgTAP cases for every operation and table, the hosted isolation
  checks, and no way to add members until C2/C3.
- **Revision bumps during backfill** would cause conflicts on devices with
  pending edits. Mitigation: trigger disabled for the backfill only, checked
  in the rehearsal (every `revision` unchanged).
- **Backfill traffic.** Updating every row sends each through replication;
  PowerSync may send unchanged rows to devices again. Small at today's size;
  observed in the rehearsal.
- **Large function rewrite.** Mitigated by unchanged contract tests, the
  production-copy rehearsal and a rehearsed rollback.
- **Hosted PowerSync per-space streams** are still unproven (C0 limit); not
  touched in C1, first deployed in C2 behind its own checks.
