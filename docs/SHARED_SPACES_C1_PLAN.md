# Shared spaces C1: server moves to spaces (plan)

Date: 2026-11-24

Status: **approved 2026-11-24** (Decisions C1-1 to C1-6, all as
recommended). **C1.1 and C1.2 done 2026-11-24**; C1.3 next. Slice C1 of
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
  reset need owner. Other cases are refused with `P0001` `not_space_member`,
  `space_read_only` or `space_owner_only`, final rejections that apps 1.2.x
  already log in Refused changes and move past. (Not `42501`: apps treat it as
  blocked, which would stall the queue and keep a removed member's space on
  the device, C0 finding 3. Corrected during C1.2.)
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

### C1.1: Spaces, space_id and per-space rules (agent, local) ✅ Done 2026-11-24

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

**Result** (migration `supabase/migrations/20261124010000_spaces.sql`, local
stack only, nothing deployed):

- New `supabase/tests/database/spaces_test.sql`: 34 checks pass (bridge
  fills, Personal space on first write, immutable space and creator, revisions
  as before, per-space names, keys and foreign keys, owners kept, reads by
  membership for owner, member and non-member, no client writes to spaces or
  members, tombstone space, user deletion as before).
- New `supabase/tests/migration/spaces_backfill_test.py`: resets the local
  database to the migration before C1.1, writes data through the current
  write API for three users (edits up to revision 3, a delete, receipts),
  migrates and checks every existing value in all eight tables is identical,
  revisions included; each user has exactly one Personal space with owner
  membership; every constraint validated. With the revision step removed, the
  migration refuses to run at all (the new immutability rule).
- Unchanged and passing: all other pgTAP (832 in total), `db lint` (now also
  `fundly_access`), all six concurrency suites, the client contract (14),
  import timing, and the app (format, analyze, 1156 tests).

Adjustments made while building (no decision changed):

1. **Personal spaces on first use come from the bridge trigger**
   (`fundly_private.ensure_personal_space`), not from the RPCs, so every
   path (old functions, initialize, import, tests) is covered in one place.
   This is how Decision C1-5 is implemented.
2. **Deleting an Auth user with no records still works**: their Personal
   space and memberships go with them (`on delete cascade`;
   `spaces.created_by` is cleared). A user with records still cannot be
   deleted, as before. Without this, every test cleanup, and deleting a test
   user in the dashboard, would fail.
3. **Import's column lists.** `fundly_import_dataset` unnests arrays of whole
   table rows with explicit column lists, so they had to include the three
   new columns in C1.1 (otherwise imports fail). Only those lists changed.
4. **One existing test changed**: the import test's "downloads exactly as
   imported" check now removes the three server-only columns as well as
   `owner_id`, since the stream downloads none of them.
5. **Write responses include the new columns** (they already include
   `owner_id`). Apps never read the returned record, so nothing changes for
   them; C1.2 decides whether to leave them out.
6. The read rule uses `space_id in (select fundly_access.my_space_ids())`,
   evaluated once per query, with the helper in its own schema so clients get
   no access to `fundly_private`.

For C1.4: the runbook's lint command gains `fundly_access`, and its full
local suite gains `spaces_backfill_test.py`.

### C1.2: Write API per space (agent, local) ✅ Done 2026-11-24

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

**Result** (migration `supabase/migrations/20261124020000_space_write_api.sql`
and `supabase/rollback/20261124_c1_rollback.sql`, local only):

- The 17 private write functions take the space (a mechanical rename of each
  current definition, `actor` → `space`, `owner_id` → `space_id`);
  `retired_owner` became `retired_space`. The two RPCs resolve the space
  (`space_id` or the caller's Personal space), take the space's lock, answer
  retries from receipts, then check the role.
- New `tests/database/space_write_api_test.sql`, 105 checks: all 21 write
  operations by an editor in another user's space; the same 21 refused for a
  viewer (`space_read_only`), an outsider and a removed member
  (`not_space_member`) with nothing changed; a removed member's earlier batch
  still answered from its receipt; placement and attribution (created by the
  editor, last changed by the owner; the editor's receipt names the space);
  retired IDs per space; missing, malformed and `null` `space_id`; imports
  owner-only. With the viewer check disabled, 42 checks fail.
- New `tests/concurrency/space_write_api_test.py`, 3 checks: an editor's write
  waits for the owner's open write to the same space; two members editing one
  revision: the second waits and conflicts; a write to another space does not
  wait.
- Rollback rehearsal `tests/migration/c1_rollback_test.py`: writes data
  through the C1 API, runs the rollback in one transaction, finds every
  existing value unchanged in all 8 tables, then all 7 pre-C1 pgTAP files and
  7 pre-C1 Python suites pass on the rolled-back database.
- Unchanged and passing: every earlier test (940 pgTAP in total, lint with
  `fundly_access`, 7 concurrency suites, the client contract, import timing,
  the backfill check) and the app (format, analyze, 1156 tests).
- Docs: WRITE_API.md (a Spaces section and two error codes), IMPORT_API.md,
  SYNC_PROTOCOL.md, ACCOUNT_API.md, PLANS_API.md, supabase/README.md.

Adjustments made while building:

1. **Refusals are `P0001`, not `42501`** (see Writes above).
2. **Lock first, then create a missing Personal space.** Creating it before
   the lock made a second simultaneous first write wait on the insert instead
   of the advisory lock (two existing concurrency tests caught it).
3. **Attribution by trigger.** The RPCs set a transaction-local
   `fundly.actor`; the bridge trigger stamps `created_by` and `updated_by`, so
   no insert or update statement changed. Clients cannot set it; it affects
   only attribution, never permissions.
4. **The rollback keeps import working**: the pre-C1 import function, with
   its row column lists extended for the columns the rollback leaves in place.
   The first rehearsal caught that the verbatim pre-C1 version fails.
5. **Write results keep their shape** (whole rows, now with the three new
   columns); apps ignore them.
6. The backfill check now resets the local database when it finishes (other
   tests count whole tables).

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
