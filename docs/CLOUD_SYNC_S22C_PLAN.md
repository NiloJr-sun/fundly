# S2.2C — Categories and Plans write API proposal

Date: 2026-11-18
Status: approved 2026-11-18 as one slice; implemented and verified locally.
The contract is [supabase/PLANS_API.md](../supabase/PLANS_API.md), which records two
refinements: when `previous` is set the item `id` must equal `previous.id`, and
clearing a month with no record returns `"record": null`.

## Starting point

S2.2A (transactions, receipts) and S2.2B (custom types, accounts, budget
selection, linked liability rows) are implemented and verified locally. Every
`category.*` and `plan.*` operation still returns `unsupported_operation`. The
Flutter app stays on local schema v12 and backup format 6, disconnected from the
cloud. This slice adds no cloud table or column: `categories` and
`monthly_plans` from S2.1 already hold every field needed.

The operations below port `CategoryRepository` and `PlanRepository` exactly.
They do not change any financial rule, Ready to assign formula or §11 decision.

## Operations

Same protocol-1 envelope, `fundly_apply_operations` RPC, per-user advisory lock,
whole-batch rollback and success receipts as [WRITE_API.md](../supabase/WRITE_API.md).
Request fields are strictly allowlisted; bigint values are decimal strings.

### Categories

`id` is the category UUID. Every operation except create requires the
category's `expected_revision`.

| Operation | `data` | Rules (from `CategoryRepository`) |
|---|---|---|
| `category.create` | Required `name`, `kind` (`spending`, `inflow`); optional `plan_group` (`spending`, `savings`, `liability`, default `spending`) | Name trimmed, 1–40 UTF-16 units, owner-scoped ASCII case-insensitive uniqueness (archived included). Inflow must stay in `spending`. A client UUID already used by any owner returns `record_id_unavailable`. |
| `category.update` | Nonempty partial object: `name` and/or `plan_group` | Kind is immutable (rejected as a field). Group change only for spending categories. |
| `category.set_archived` | Required Boolean `archived` | Keeps history; new transactions already reject archived categories (S2.2A). |
| `category.delete` | Omitted or `{}` | Blocked with `category_in_use` while any transaction references it. Its monthly plans cascade and are returned as deleted `changes`. |

Linked liability rows (`linked_account_id` set) are managed through their
account. Every `category.*` mutation on them returns `managed_category`, matching
the repository's "Manage this Plans row through its account". Plan operations
below are allowed on linked rows, as they are locally.

### Monthly plans

The repository saves by category and month, not by plan ID, and removes the
record when Target is null and Assigned is zero. Two offline devices could each
create a different plan UUID for the same category and month. The proposal
therefore addresses plans by `(category_id, month)` and checks an observed
snapshot, like `account.set_budget`'s `previous_budget`:

| Operation | Item `id` | `data` |
|---|---|---|
| `plan.save` | New plan UUID (used only when a record is created) | Required `category_id`, `month` (`YYYY-MM`), `target_amount_minor` (nonnegative decimal string or explicit null), `assigned_amount_minor` (nonnegative decimal string), `previous` (null or `{ "id", "revision" }` of the observed record) |

- `previous: null` means no record was observed. If one exists, or the observed
  ID/revision no longer match, the result is `plan_conflict` and nothing changes.
- Null Target + zero Assigned deletes the record (the local `clear`), returned as
  `deleted: true` with its prior revision; with no record it is a no-op.
- Spending categories only (`category_not_spending`); `plan_deleted` and
  `plan_archived` block saves; an archived category may change an existing
  record but cannot gain a new one (`category_archived`). These checks run in
  the same order as the repository.
- PHP only, bounded by signed bigint. No separate `plan.clear` operation is
  needed.

### Plan lifecycle

These change flags on the category row, so `id` is the category UUID and
`expected_revision` is the category's revision.

| Operation | `data` | Rules (from `PlanRepository`) |
|---|---|---|
| `plan.set_archived` | Required Boolean `archived`; `timezone` required when `archived` is true | Spending only; not when plan-deleted. Unarchive requires an unarchived category (for linked rows that mirrors the account). Archive is blocked while any current/future month has remaining allocation (below). Already archived → no-op. |
| `plan.delete_permanently` | Omitted or `{}` | Allowed only when the category or the plan is archived, every month's Assigned is zero, and there is no eligible activity in any month (Spending in the category, or for linked rows Transfer/CC Payment into the account). Deletes every monthly plan, sets `is_plan_archived` and `is_plan_deleted`, keeps the category/account. |

Blocked deletion returns `plan_delete_blocked` with the repository's reason
(`not_archived`, `has_assigned_money`, `has_activity`, `already_deleted`,
`category_not_spending`) in the error detail.

## Decision 1 — timezone for the archive check (needs approval)

The archive guard uses "the actual local month". The server must not trust a
supplied month or default to UTC, so `plan.set_archived` with `archived: true`
requires `timezone`, an IANA name such as `Asia/Manila`:

- Valid only when it exactly matches a `pg_timezone_names` entry. Abbreviations
  and POSIX strings like `UTC+8` (PostgreSQL inverts their sign) are rejected
  with `invalid_timezone`.
- The server computes the current month from `clock_timestamp()` in that zone
  at the moment the batch is applied, so a delayed offline request is checked
  against the conditions on upload.
- The timezone is part of the request, so it is already in the receipt
  fingerprint. A retry after midnight returns the original result unchanged.
- Server tzdata is authoritative if it differs from the device's.
- Unarchive and permanent deletion do not depend on the month and reject the
  field.

Client impact (S5, not this slice): Dart's `DateTime` exposes only an
abbreviation, so supplying the IANA name will need a small dependency such as
`flutter_timezone`. That dependency will be proposed separately when S5 starts.

## Archive allocation check

The same calculation as `remainingPlanAllocation`, run atomically under the
user lock:

1. Current month `M` from the timezone; the current budget account, if any.
2. For each plan record of the category with month ≥ `M`: remaining = Assigned
   minus eligible transactions in that month whose source is the budget account
   (Spending in the category; for linked rows Transfer/CC Payment into the
   account), floored at zero. With no budget account, remaining = Assigned.
3. Any nonzero month → `plan_allocation_remaining`, with an error detail listing
   each month and amount as decimal strings. Past months never block.

## Results and errors

Category and plan results follow S2.2B: `entity`, `id`, decimal-string
`revision`, canonical `record` (or `deleted: true` with the prior revision) and
`changes`. Deleted plans appear in `changes`. Removed rows have no tombstone yet,
the same as transaction deletes (S2.3).

New `P0001` messages: `managed_category`, `category_in_use`,
`category_not_spending`, `category_archived`, `plan_archived`, `plan_deleted`,
`plan_conflict`, `plan_allocation_remaining`, `plan_delete_blocked`,
`invalid_timezone`. Existing `invalid_name`, `name_taken`, `revision_conflict`,
`record_not_accessible`, `record_id_unavailable` and request errors keep their
contract. The detail of `plan_allocation_remaining` and `plan_delete_blocked`
is JSON, so the future client can show which months block archiving or why
deletion is blocked.

## Files

| File | Change |
|---|---|
| `supabase/migrations/20261118040000_category_plan_write_api.sql` | New. `apply_category`, `apply_plan` helpers, wire mappers, timezone and allocation helpers; replaces `apply_operation` to dispatch them. No table changes. |
| `supabase/tests/database/category_plan_write_api_test.sql` | New pgTAP suite (below). |
| `supabase/tests/concurrency/category_plan_write_api_test.py` | New real-session race runner. |
| `supabase/PLANS_API.md` | New contract document, like ACCOUNT_API.md. |
| `supabase/README.md`, `supabase/WRITE_API.md`, `supabase/ACCOUNT_API.md` | Remove "Category/Plans unsupported" wording; next step becomes S2.3. |

## Tests

SQL (both owners, no session, forged and cross-owner references, malformed and
extra fields, stale revisions):

- Category create/update/archive/delete, name trim/UTF-16 length/case
  collisions with normal and linked categories, inflow group rule, immutable
  kind, deletion blocked by any transaction, plan cascade in `changes`, every
  mutation refused on linked rows.
- Plan save: create/update/clear, null versus zero Target, `previous`
  mismatches, spending-only, archived category with and without an existing
  record, archived/deleted plan, bigint bounds, `"0"`, native numbers rejected.
- Archive: blocked by current and future remaining allocation, not by past
  months, budget versus non-budget sources, linked payments, no budget account,
  error detail contents. Month boundaries by timezone: the same instant is
  November in `Asia/Manila` and October in `America/Los_Angeles`, using a
  controlled clock. Invalid and POSIX timezones rejected.
- Unarchive requires an active category or account; account unarchive never
  revives a permanently deleted plan.
- Permanent delete: each blocking reason, success removes every month and
  keeps the category, later saves/unarchives refused.
- Whole-batch rollback when a later operation fails; same-key retry after
  commit, including after the local month changes.

Concurrency (independent sessions, observed lock waits):

- Two `plan.save` with `previous: null` for the same category and month: one
  commits, the other gets `plan_conflict`.
- Archive versus new budget Spending, and archive versus assigning money, in
  both orders.
- Permanent delete versus transaction create, and category delete versus
  transaction create, in both orders.

Commands, sequential, local stack only:

```sh
npx --yes supabase@3.2.0 db reset --yes
npx --yes supabase@3.2.0 test db
npx --yes supabase@3.2.0 db lint --schema public,fundly_private --fail-on warning
python3 supabase/tests/concurrency/write_api_test.py
python3 supabase/tests/concurrency/account_write_api_test.py
python3 supabase/tests/concurrency/category_plan_write_api_test.py
dart format . && flutter analyze && flutter test
```

No iOS build is needed (SQL and docs only).

## Not included

Default categories for a new cloud user, importing existing data, tombstones,
durable rejections, client reconciliation (S2.3), SDK integration, hosted
deployment and any Flutter change.

## Approval requested

1. Approve **Decision 1**: a required IANA `timezone` on plan archive.
2. Approve plan addressing by `(category_id, month)` with the `previous`
   snapshot and the new error codes.
3. Approve implementing S2.2C as one slice. Alternatively it can be split into
   C1 (categories) and C2 (plans and lifecycle).
