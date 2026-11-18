# S2.3 — Rejection, retry and deletion protocol proposal

Date: 2026-11-18
Status: approved 2026-11-18; implemented and verified locally. The contract is
[supabase/SYNC_PROTOCOL.md](../supabase/SYNC_PROTOCOL.md).

## Starting point

S2.2 is complete locally: every repository workflow has a validated operation
in `fundly_apply_operations`, with a per-user lock, whole-batch rollback and
success receipts that make retries after a lost response safe. Three gaps remain
before a client can use it offline:

1. **Deleted identities.** A deleted UUID can be created again (a stale offline
   client could revive a deleted transaction), and an edit of a deleted record
   returns the same `record_not_accessible` as a record that never existed, so a
   client cannot tell "deleted on another device" from a bug.
2. **Rejection details.** An error does not say which item in the batch failed,
   and a conflict does not say what the server now holds.
3. **Client recovery.** Nothing defines which failures are final, which are
   retried, how a rejected write is kept for the user, or what happens to later
   queued writes that depend on it.

This slice adds a backend-only table and error enrichment, plus a protocol
document for S5. It does not change financial rules, the request format, the
success result format, local schema v12 or backup format 6.

## Decision 1 — rejections are raised, not recorded on the server (needs approval)

**Proposal:** keep raising errors. The rejected batch rolls back and leaves no
receipt. The client stores the rejection locally before it removes the item from
its queue (S5).

This is safe. Idempotency only matters for success: an accepted batch must never
apply twice, and the success receipt already guarantees that. A rejected batch
changed nothing. If its response is lost, the retry is checked again against the
current state, and either outcome is correct for the request the client sent.

The alternative was server-side rejection receipts, so a retry always returns
the first rejection. That would need a new protocol version that returns
rejections instead of raising them, and it would change about 600 existing
assertions. It gives no extra financial safety, so it is not recommended.

## Decision 2 — deleted UUIDs are retired permanently (needs approval)

Add `public.fundly_deleted_records`, backend-only like the receipts table:
`(id uuid primary key, owner_id, entity, revision, deleted_at)`. No client grants
and no replication. Rows hold no names, amounts or notes, only identity.

- An `AFTER DELETE` trigger on all five tables records every deletion,
  including cascades (category → plans, permanent plan deletion, plan clear).
  No deletion path can be missed.
- **Create with a retired UUID:** `record_deleted` for the same owner,
  `record_id_unavailable` for another owner (no disclosure). This covers
  `*.create`, the `plan.save` create path and `account.create`'s
  `linked_category_id`. Clients must use a fresh UUID to re-create.
- **Edit, delete or lifecycle change of a retired record, or a reference to one**
  (a transaction's account or category, a plan's category): `record_deleted`
  for the same owner. Other owners still get `record_not_accessible`.
- Kept indefinitely, like receipts. An expiry would let a very old offline
  client revive a record. Deleting a whole user's cloud data is out of scope.

PowerSync already removes deleted rows from devices through replication, so
this table is not downloaded.

## Rejection details

The dispatcher catches a rejected item and raises it again with the same message
and SQLSTATE (so existing error contracts hold), adding a JSON detail:

```json
{"index": 1, "operation": "plan.save", "id": "54000000-…", "current": {"id": "54000000-…", "revision": "4"}}
```

- `index` (0-based), `operation` and `id` identify the failing item.
  `invalid_request` gives them only when the item itself is readable.
- Existing details are kept and merged: `months` for
  `plan_allocation_remaining`, `reason` for `plan_delete_blocked`.
- Conflicts carry what the server now holds, owner-scoped:
  `revision_conflict` → `current_revision` of the target;
  `plan_conflict` → `current` record `{id, revision}` for that category/month,
  or null; `budget_conflict` → `current` budget account `{id, revision}` or null.
  The client can wait until its download reaches that revision before showing
  the conflict.
- `record_deleted` → `entity` and `deleted_id`.

The receipt check, the lock and the success results are unchanged.

## Client recovery contract (implemented in S5)

Documented in `supabase/SYNC_PROTOCOL.md` as the contract S5 must prove.

**Queue model (assumed, to be proven in S5):** each repository write stores its
optimistic rows plus one operation record in a single local transaction. The
upload connector sends one batch per local transaction, using a stable batch
UUID that is stored with the queued operation. The server remains the source of
truth: downloaded rows replace optimistic ones.

**Outcome classes:**

| Class | Signals | Client action |
|---|---|---|
| Accepted | Result returned | Complete the queue item; downloads confirm the rows. |
| Transient | Network failure or timeout, HTTP 5xx, SQLSTATE `40001`, `40P01`, `55P03`, `57014`, `57P01`, `53xxx`, `08xxx`; expired session | Keep the item, retry the **same batch UUID and payload** with backoff; refresh the session first when it expired. |
| Rejected (final) | `22023 invalid_request`, and the `P0001` domain codes listed in WRITE_API, ACCOUNT_API and PLANS_API, plus `record_deleted` | Store a local rejection (payload, code, detail, time), **then** complete the queue item so later writes continue, then restore server state for the affected rows. |
| Blocked | `unsupported_operation` (server older than client), `batch_key_reused` (client bug), any unclassified error, e.g. `42501` | Keep the item and retry slowly. Show "sync is stuck". Never discard automatically; the user can export or discard explicitly. |

**Conflicts are never merged automatically** (the approved default):
`revision_conflict`, `plan_conflict`, `budget_conflict` and `record_deleted`
are final rejections. The user sees "changed (or deleted) on another device"
with their local change kept in the rejection log, to reapply by hand.

**Dependent queued writes:** when a rejected batch would have created records,
the client remembers those UUIDs. A later queued batch that references one is
not uploaded. It is stored as `dependency_rejected` and linked to the original
rejection, so the user sees one cause rather than a cascade of
`record_not_accessible` errors. Unrelated batches upload normally.

**Open proof for S5, not claimed:** after a rejection, the next complete
download must return local rows to server state, including removing an
optimistic insert the server never accepted. S1 proved retention and retry of a
rejected batch, but not this rollback for raw tables. S5 must prove it or add an
explicit local revert.

## Files

| File | Change |
|---|---|
| `supabase/migrations/20261118050000_sync_protocol.sql` | New. Tombstone table, delete triggers, retired-ID checks, dispatcher enrichment (`create or replace` of the dispatcher only). |
| `supabase/tests/database/sync_protocol_test.sql` | New pgTAP suite. |
| `supabase/tests/concurrency/sync_protocol_test.py` | New real-session races. |
| `supabase/SYNC_PROTOCOL.md` | New: error classes, details, tombstones, client contract. |
| `supabase/README.md`, `WRITE_API.md`, `ACCOUNT_API.md`, `PLANS_API.md` | Point to the protocol; add `record_deleted` and the detail fields. |
| `docs/CLOUD_SYNC_PLAN.md` | "Next task" pointer only. |

## Tests

SQL:
- Every entity's delete records a tombstone, including category → plans,
  permanent plan deletion, plan clear and account deletion's detach (no
  tombstone for the category, which survives).
- Creating with a retired UUID: same owner `record_deleted`, other owner
  `record_id_unavailable`, for transactions, accounts, custom types, categories,
  plans and linked category IDs.
- Editing, deleting, archiving and referencing a retired record →
  `record_deleted` with `entity`/`deleted_id`. Other-owner and never-existing
  IDs stay `record_not_accessible`.
- Details: `index` of the second item in a batch, merged `months`/`reason`,
  `current_revision`, plan and budget `current` values. No other owner's data
  appears.
- Tombstones and receipts cannot be read or written by clients. Replay of a
  committed delete still returns its original result.
- All 610 existing assertions still pass unchanged.

Concurrency: delete versus edit of the same record in both orders (the waiting
edit gets `record_deleted`, or the waiting delete gets `revision_conflict` with
`current_revision`), and delete versus re-create with the same UUID.

Commands as in S2.2C, plus the new runner; `dart format .`, `flutter analyze`,
`flutter test`. No iOS build is needed (SQL and docs only).

## Not included

Client queue, local rejection table and UI (S5), PowerSync configuration (S3),
hosted deployment, data import (S6) and cloud data deletion.

## Approval requested

1. **Decision 1:** raise rejections without server-side rejection receipts.
2. **Decision 2:** permanent, backend-only tombstones and `record_deleted`.
3. The rejection detail fields, and the client contract as the target S5 must
   prove: outcome classes, no automatic merge, `dependency_rejected`.
