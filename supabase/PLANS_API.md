# Category and Plans operations — S2.2C

Implemented by `20261118040000_category_plan_write_api.sql`, locally verified only.
Use the same protocol-1 envelope and `fundly_apply_operations` RPC described in
[WRITE_API.md](WRITE_API.md). Every operation inherits its authenticated owner,
per-user transaction lock, atomic batch rollback and durable success receipt.
No table or column changed. The operations port `CategoryRepository` and
`PlanRepository` without changing any financial rule.

## Categories

`id` is the category UUID. Every operation except create requires the exact
decimal-string `expected_revision`. Request data is strictly allowlisted.

| Operation | `data` fields |
|---|---|
| `category.create` | Required `name`, `kind` (`spending`, `inflow`); optional `plan_group` (`spending`, `savings`, `liability`; default `spending`). |
| `category.update` | Nonempty partial object containing `name` and/or `plan_group`. Kind is immutable. |
| `category.set_archived` | Required Boolean `archived`. |
| `category.delete` | Omitted or `{}`. |

Names follow the account rules: trimmed, 1–40 UTF-16 units, owner-scoped ASCII
case-insensitive uniqueness that includes archived and linked categories.
Inflow categories always stay in the `spending` group; an unknown kind or group,
or another group for an inflow, is `invalid_request`. Archived categories keep
their history; new transactions already reject them (S2.2A), and edits may keep
them. Deletion is refused with `category_in_use` while any transaction
references the category. Its monthly plans are deleted with it and listed in
`changes`, in month order.

Linked liability rows are managed through their account (S2.2B): every
`category.*` operation on them returns `managed_category`. Plan operations are
allowed on them.

## Monthly plans

```json
{
  "operation": "plan.save",
  "id": "54000000-0000-4000-8000-000000000010",
  "data": {
    "category_id": "31000000-0000-4000-8000-000000000001",
    "month": "2026-11",
    "target_amount_minor": null,
    "assigned_amount_minor": "50000",
    "previous": null
  }
}
```

All five fields are required. Target is a nonnegative decimal string or explicit
null (no Target); null and `"0"` differ. Assigned is a nonnegative decimal
string. Both are bounded by signed bigint, PHP only. Month is `YYYY-MM`. The item
takes no `expected_revision`.

Plans are addressed by category and month. `previous` is the record the client
last observed: `null` for none, otherwise `{ "id", "revision" }`, and then the
item `id` must equal `previous.id`. When the stored record differs (one exists
when none was observed, or the ID/revision changed, or it was removed), the
result is `plan_conflict` and nothing changes. A new record uses the item `id`.

Checks run in the repository's order: the category must be the caller's
(`record_not_accessible`), a spending category (`category_not_spending`), not
plan-deleted (`plan_deleted`) and not plan-archived (`plan_archived`). Null
Target plus zero Assigned removes the record and returns `deleted: true` with
its prior revision; with no record it is a no-op returning `"record": null`.
An archived category may keep editing an existing record but cannot gain a new
one (`category_archived`).

## Plan lifecycle

Both operations change flags on the category row, so `id` is the category UUID
and `expected_revision` the category's revision.

| Operation | `data` fields |
|---|---|
| `plan.set_archived` | Required Boolean `archived`; `timezone` required when archiving and refused when unarchiving. |
| `plan.delete_permanently` | Omitted or `{}`. |

**Archive.** Spending categories only; refused when plan-deleted. Archiving is
blocked while any month from the caller's current month onwards has remaining
allocation: Assigned minus that month's eligible transactions whose source is
the budget account, floored at zero. Eligible means Spending in the category,
or for linked rows a Transfer/CC Payment into the linked account. With no budget
account nothing is released. Past months never block. Archiving or unarchiving a
row already in that state is a no-op that keeps its revision. Spending in the
category stays allowed after archiving; later transaction edits never undo it.

**Timezone.** `timezone` must exactly match a PostgreSQL `pg_timezone_names`
entry (IANA names such as `Asia/Manila`), at most 64 characters, otherwise
`invalid_timezone`. POSIX strings like `UTC+8` (which PostgreSQL reads with the
opposite sign) and wrong-case names are refused. The server computes the current
month in that zone when the batch is applied, so a delayed offline request is
judged against conditions on upload; no client-supplied month is accepted. The
timezone is part of the request fingerprint, and a retry returns the original
result even after midnight. The server's tzdata is authoritative.

**Unarchive** requires an unarchived category (`category_archived`); for linked
rows the category mirrors the account.

**Permanent deletion** removes every monthly plan, sets `is_plan_archived` and
`is_plan_deleted`, and keeps the category/account. It is allowed only when the
category or the plan is archived, no month has nonzero Assigned and there is no
eligible activity in any month. Afterwards saves and unarchive return
`plan_deleted`, account sync never revives the row, and spending in the category
remains allowed.

## Results and errors

Results contain `operation`, `entity` (`categories` or `monthly_plans`), `id`,
decimal-string `revision`, canonical `record` (or `deleted: true` with the prior
revision) and `changes`. Plan records carry `target_amount_minor` (string or
null) and `assigned_amount_minor` as strings; audit times use UTC `Z`. Removed
rows have no tombstone yet (S2.3).

New `P0001` messages: `managed_category`, `category_in_use`,
`category_not_spending`, `category_archived`, `plan_archived`, `plan_deleted`,
`plan_conflict`, `plan_allocation_remaining`, `plan_delete_blocked` and
`invalid_timezone`. Two carry a JSON error detail:

```json
{"months": [{"month": "2026-11", "remaining_minor": "30000"}]}
{"reason": "has_assigned_money"}
```

Deletion reasons are `category_not_spending`, `already_deleted`, `not_archived`,
`has_assigned_money` and `has_activity`, checked in that order. Shared request,
authentication, inaccessible-record, revision, name and idempotency errors keep
their S2.2A/B contract.

Tests use only the disposable local database:

```sh
npx --yes supabase@3.2.0 db reset --yes
npx --yes supabase@3.2.0 test db
npx --yes supabase@3.2.0 db lint --schema public,fundly_private --fail-on warning
python3 supabase/tests/concurrency/category_plan_write_api_test.py
```

The runner observes real advisory-lock waits between separate sessions:
concurrent first saves for one month, archive versus budget spending, spending
deletion and assignment in both orders, permanent deletion versus spending, and
category deletion versus spending in both orders.
