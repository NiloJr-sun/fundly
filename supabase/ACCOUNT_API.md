# Account and custom-type operations — S2.2B

Implemented by `20261118030000_account_write_api.sql`, locally verified only.
Use the same protocol-1 envelope and `fundly_apply_operations` RPC described in
[WRITE_API.md](WRITE_API.md). Every operation inherits its authenticated owner,
per-user transaction lock, atomic batch rollback, and durable success receipt.
Direct table writes and private-helper access remain denied.

## Operations

Every item has `operation` and a client-generated UUID `id`. Creates omit
`expected_revision`; all other operations require the exact decimal-string
revision of the target account/custom type. Request data fields are strictly
allowlisted; owner, audit timestamps and stored revisions cannot be supplied.

| Operation | `data` fields |
|---|---|
| `custom_type.create` | Required `name`, `base_type` (`savingsCash`, `credit`, `loan`). |
| `custom_type.update` | Nonempty partial object containing `name` and/or `base_type`. |
| `custom_type.delete` | Omitted or `{}`. |
| `account.create` | Required `name`, `type`, `entered_opening_amount_minor`; optional `currency_code` (PHP only), nullable `custom_type_id`, and liability-only `linked_category_id`. |
| `account.update` | Nonempty partial object containing `name`, `entered_opening_amount_minor`, and/or nullable `custom_type_id`. Account base type and currency cannot change. |
| `account.set_archived` | Required Boolean `archived`. |
| `account.delete` | Omitted or `{}`; account must be archived and unused by any transaction. |
| `account.set_budget` | Omitted or `{}`; a `previous_budget` key from app 1.1.0 is accepted and ignored. |
| `account.clear_budget` | Omitted or `{}`; item `id` is the budget account to clear. |

Opening amounts are canonical nonnegative decimal strings, including `"0"`,
bounded by signed bigint maximum. The server stores assets positively and
liabilities negatively. Negative input and native JSON numbers are rejected.
Omitting the opening amount on update preserves the stored signed value exactly,
including a pre-existing bigint minimum; this does not require taking its absolute
value. Currency defaults to PHP on create. Explicit null clears a custom type;
omission retains it. Null names, opening amounts or Boolean flags are invalid.

Names are trimmed, nonempty, and at most 40 UTF-16 code units; uniqueness remains
owner-scoped and ASCII case-insensitive, including archived accounts. Custom-type
names cannot reuse built-in labels. Changing a custom type's base or deleting it
is blocked by any account reference, including archived accounts. Renaming an
in-use custom type remains allowed. Account/custom-type references must belong
to the caller and have matching base types.

Archiving a budget account clears its budget flag atomically. Unarchiving does
not reinstate it. Account archive confirmations remain a future UI responsibility;
the backend permits archiving accounts with balances/history as the existing
repository does. Permanent account deletion requires no source/destination
transaction usage; it preserves and detaches the linked category and its monthly
history rather than deleting those records.

## Budget selection

Any number of active Savings/Cash accounts can be budget accounts
(2026-11-23, migration `20261123020000`). Each account is set or cleared on its
own, guarded only by its `expected_revision`:

```json
{
  "operation": "account.set_budget",
  "id": "21000000-0000-4000-8000-000000000005",
  "expected_revision": "1"
}
```

`account.set_budget` never clears another account. App 1.1.0 still sends
`data: {"previous_budget": …}`; it is accepted and ignored. Setting an account
that is already a budget account, or clearing one that is not, is a no-op that
keeps its revision. `budget_conflict` is no longer raised. An archived or
non-Savings/Cash account still yields `invalid_account`.

## Linked liability rows

Credit/loan creation produces one linked spending category in the Liability
group, with no monthly-plan record (implicitly no Target and zero Assigned).
The server generates its UUID unless `linked_category_id` is supplied on create.
A future offline client can supply that UUID before queuing dependent plan edits.
An existing category UUID, including another user's, cannot be adopted.

The category follows account name/archive changes. Independent `is_plan_archived`
and `is_plan_deleted` flags, targets, assignments and history remain intact.
Account unarchive never revives a permanently deleted plan. A missing category
is created for an active liability, but not for an archived liability. Unchanged
derived fields do not generate an unnecessary category revision.

On a name collision, use ` (debt <first-8-UUID-characters>)`, then append a counter
inside the suffix when needed. Trim the account-name prefix to fit 40 UTF-16
units without splitting a Unicode character. The search is owner-scoped and
bounded at 1000 collision candidates; exhaustion returns `name_taken`. The
separate dataset-import task must preserve historical names explicitly.

## Results, errors and verification

Account/custom-type results include `entity`, `id`, decimal-string `revision`,
and a canonical `record` (or `deleted: true`). Account results additionally
include `changes`, an array of canonical side effects: created/updated linked
categories, or a detached category after account
deletion. Revisions and opening balances are strings; audit times use UTC `Z`.
Receipt replay returns the original side effects and generated UUIDs unchanged.

Additional `P0001` messages: `invalid_name`, `name_taken`, `invalid_custom_type`,
`custom_type_in_use`, `invalid_account`, `account_not_archived`,
`account_has_transactions`, `record_id_unavailable`, and `budget_conflict`.
Shared request, authentication, inaccessible-record, revision and idempotency
errors retain the S2.2A contract. Category/Plans operations are in
[PLANS_API.md](PLANS_API.md).
Deleted account and custom-type UUIDs are retired; see [SYNC_PROTOCOL.md](SYNC_PROTOCOL.md).

Tests use only the disposable local database:

```sh
npx --yes supabase@3.2.0 db reset --yes
npx --yes supabase@3.2.0 test db
npx --yes supabase@3.2.0 db lint --schema public,fundly_private --fail-on warning
python3 supabase/tests/concurrency/write_api_test.py
python3 supabase/tests/concurrency/account_write_api_test.py
```

Run database suites sequentially: concurrency fixtures are committed briefly
before cleanup, while some schema assertions expect a fresh local database.
The account runner observes real advisory-lock waits in separate sessions. It
tests concurrent budget selections and archive-versus-selection, archive-versus-spending in both
orders, custom-base changes versus account creation in both orders, and
idempotent linked-category creation. No hosted credentials or `.env` are read.
