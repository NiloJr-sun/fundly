# Sync protocol — S2.3

Implemented by `20261118050000_sync_protocol.sql`, locally verified only. It
completes S2 on top of the protocol-1 RPC in [WRITE_API.md](WRITE_API.md),
[ACCOUNT_API.md](ACCOUNT_API.md) and [PLANS_API.md](PLANS_API.md). Requests,
success results, receipts, financial rules, local schema v12 and backup format 6
are unchanged. The client part below is the contract S5 must implement and prove.

## Rejections

A rejected batch still raises an error and rolls back completely. No rejection
receipt is stored: a rejected batch changed nothing, so a retry after a lost
response is checked again against the current state, and either outcome is
correct for that request. Success receipts still guarantee that an accepted
batch never applies twice.

Every `P0001` and `22023` rejection keeps its message and SQLSTATE and carries a
JSON detail:

| Field | When |
|---|---|
| `index` | Always: 0-based position of the failing item in `items`. |
| `operation`, `id` | When the item has them as strings. |
| `current_revision` | `revision_conflict`: the target's revision (owner-scoped). |
| `current` | `plan_conflict`: `{id, revision}` of the plan for that category/month, or null. `budget_conflict`: `{id, revision}` of the budget account, or null. |
| `entity`, `deleted_id` | `record_deleted`: which retired record caused it. |
| `months` / `reason` | `plan_allocation_remaining` / `plan_delete_blocked`, as before. |

`current` values are what the failing item saw, including earlier items of the
same batch, which then roll back. Treat them as a hint and compare with the
downloaded row after the next complete checkpoint. Another owner's records
never appear: they stay `record_not_accessible` with no current values.
Errors raised before items are read (`authentication_required`, envelope
`invalid_request`, `batch_key_reused`) have no detail.

## Deleted records

`public.fundly_deleted_records` keeps `(entity, id, owner_id, revision,
deleted_at)` for every deleted row of the five tables. An `AFTER DELETE`
trigger records RPC deletes, cascades (category → plans, permanent plan
deletion, plan clear) and privileged maintenance deletes. Account deletion
detaches its linked category, so that category has no tombstone. The table holds
no names, amounts or notes, has no client grants and is not replicated (PowerSync
already removes deleted rows from devices). Entries never expire, because an old
offline client could otherwise revive a record.

- Creating with a retired UUID (`*.create`, the `plan.save` create path,
  `account.create`'s `linked_category_id`): `record_deleted` for the same owner,
  `record_id_unavailable` for another owner. Re-create with a fresh UUID.
- Editing, deleting or changing the lifecycle of a retired record, or
  referencing one (transaction accounts/category, a plan's category, an
  account's custom type): `record_deleted` for the same owner. Other owners,
  and IDs that never existed, still get `record_not_accessible`.
- A delete that rolls back (a later item failed) leaves no tombstone.

## Outcome classes for the client

| Class | Signals | Client action |
|---|---|---|
| Accepted | Result returned | Complete the queue item; downloads confirm the rows. |
| Transient | Network failure or timeout, HTTP 5xx, SQLSTATE `40001`, `40P01`, `55P03`, `57014`, `57P01`, `53xxx`, `08xxx`; expired session | Keep the item; retry the **same batch UUID and payload** with backoff; refresh an expired session first. |
| Rejected (final) | `22023 invalid_request`; the `P0001` domain codes in the API documents; `record_deleted` | Store a local rejection (payload, code, detail, time), **then** complete the queue item so later writes continue, then restore server state for the affected rows. |
| Blocked | `unsupported_operation` (server older than client), `batch_key_reused` (client bug), any unclassified error such as `42501` | Keep the item, retry slowly and show "sync is stuck". Never discard automatically; the user can export or discard explicitly. |

**No automatic merge.** `revision_conflict`, `plan_conflict`, `budget_conflict`
and `record_deleted` are final rejections. The user sees "changed (or deleted)
on another device" with their change kept in the rejection log, to reapply by hand.

**Dependent writes.** When a rejected batch would have created records, the
client remembers their UUIDs. A later queued batch that references one is not
uploaded. It is stored as `dependency_rejected`, linked to the original
rejection. Unrelated batches upload normally.

**Queue model (implemented in S5.3).** Each repository write stores its
optimistic rows and one queued batch (PowerSync `powersync_crud`, type
`fundly_batch`, id = batch UUID, data = the protocol-1 envelope) in a single
local transaction. The connector uploads the oldest batch first and resends
the same UUID and payload after a transient failure. Until S5.4, a rejected
or blocked batch stays queued and the app shows "Sync stuck".

**Open proof for S5.** After a rejection, the next complete download must return
local rows to server state, including removing an optimistic insert the server
never accepted. S1 proved retention and retry, not this rollback for raw tables.
S5 must prove it or add an explicit local revert.

## Verification

```sh
npx --yes supabase@3.2.0 db reset --yes
npx --yes supabase@3.2.0 test db
npx --yes supabase@3.2.0 db lint --schema public,fundly_private --fail-on warning
python3 supabase/tests/concurrency/sync_protocol_test.py
```

The runner covers a delete committed before a waiting edit (`record_deleted`),
an edit committed before a waiting stale delete (`revision_conflict` with
`current_revision`), and a delete committed before a waiting re-create with the
same UUID. Concurrency runners now also remove their fixtures' tombstones,
because tombstones reference the test user.
