# Dataset import — S6.1

Implemented by `20261122020000_dataset_import.sql`, verified locally and deployed
to the hosted project on 2026-11-22.
The function replaces one owner's whole dataset in a single transaction: other
devices download either the old dataset or the complete new one. It is the
server half of moving signed-out data or a backup into an account
([CLOUD_SYNC_S6_PLAN.md](../docs/CLOUD_SYNC_S6_PLAN.md)). The app calls it
for two things:

- **Reset all data while signed in:** `replace` with only the default
  categories (`lib/features/backup/data/cloud_data_resetter.dart`).
- **Copying this device's signed-out data into the account (S6.2):**
  `into_empty` or `replace` with fresh UUIDs
  (`lib/features/backup/data/device_data_copier.dart`). The request mapping
  is checked against the local server by `supabase/tests/client_contract_test.py`.
- **Restoring a backup file while signed in (S6.3):** the same flow, with the
  parsed file (formats 1–7) as the source. The contract test also sends
  requests built from a format 7 file and a format 3 file.

The batch API ([WRITE_API.md](WRITE_API.md)) and its receipts, the tables and
their constraints are unchanged.

## Call

```sql
select public.fundly_import_dataset(import_id uuid, request jsonb);
```

It is open to `authenticated` users only, and imports into the caller's own
dataset.

```json
{
  "version": 1,
  "mode": "into_empty",
  "expected": { "custom_account_types": 0, "accounts": 0, "categories": 9,
                "transactions": 0, "monthly_plans": 0 },
  "dataset": {
    "custom_account_types": [], "accounts": [], "categories": [],
    "transactions": [], "monthly_plans": []
  }
}
```

- `mode` is one of:
  - `into_empty`: allowed only when the account holds nothing except
    untouched default categories. Untouched means a default name and kind,
    revision 1, no flags and no link.
  - `replace`: deletes the account's current dataset first.
- `expected` holds the counts the user saw before confirming. It is required
  for `replace` and optional for `into_empty`, where it is ignored. Each count
  is a non-negative integer.
- `dataset` holds all five arrays; any of them may be empty.
- The whole request may be at most 8 MiB (8,388,608 bytes of JSON).

### Records

Records use the download wire shape, without `owner_id` or `revision`. Every
field is required except `created_at` and `updated_at`, and unknown fields are
refused.

| Table | Fields |
|---|---|
| `custom_account_types` | `id`, `name`, `base_type` |
| `accounts` | `id`, `name`, `type`, `opening_balance_minor`, `currency_code`, `is_archived`, `custom_type_id`, `is_budget_account` |
| `categories` | `id`, `name`, `kind`, `is_archived`, `is_plan_archived`, `is_plan_deleted`, `plan_group`, `linked_account_id` |
| `transactions` | `id`, `type`, `amount_minor`, `currency_code`, `date`, `payee`, `category_id`, `source_account_id`, `destination_account_id`, `note` |
| `monthly_plans` | `id`, `month`, `category_id`, `target_amount_minor`, `assigned_amount_minor`, `currency_code` |

Value formats:

- **IDs:** UUID strings. References use the IDs of other records in the same
  import.
- **Money:** decimal strings in minor units. `opening_balance_minor` may be
  negative (`"-2000"`). The other amounts may not. `target_amount_minor` may
  be `null`.
- **Dates:** `YYYY-MM-DD`, with year 0000 accepted (stored as 1 BC, as in the
  batch API). Months are `YYYY-MM`.
- **Timestamps:** UTC, `YYYY-MM-DDTHH:MM:SS[.ffffff]Z`. A missing `created_at`
  becomes the import time. A missing `updated_at` becomes `created_at`.
- **Revisions:** every imported record starts at revision 1.
- **Text:** names are checked as sent; they are not trimmed for the user.
  Payees and notes are stored as sent.

## Rules

These are the final-state rules that a local backup restore applies.
Archived accounts and categories may hold history.

- **Names:** trimmed, 1–40 UTF-16 code units, and unique per table, ignoring
  ASCII case. A custom type may not use a built-in type name.
- **Accounts:**
  - a custom type exists in the import and has the account's base type;
  - Savings/Cash opening balances are ≥ 0, and Credit and Loan opening
    balances are ≤ 0;
  - the currency is PHP;
  - there is at most one budget account, and it is an active Savings/Cash
    account.
- **Categories:**
  - inflow categories are in the Spending group and are never Plans rows;
  - a plan-deleted row is plan-archived.
- **Linked rows:** a linked row links a Credit or Loan account in the import,
  is a Liability-group spending category, matches its account's archive
  status, and is that account's only row. Every active Credit or Loan account
  has one.
- **Transactions:**
  - the shape follows the type, and amounts are positive;
  - Spending and Inflow need a payee; payees are at most 60 characters and
    notes at most 500;
  - the source and destination accounts are different;
  - each type uses only its allowed accounts:

    | Type | From | To |
    |---|---|---|
    | Spending | Savings/Cash or Credit | — |
    | Inflow | — | Savings/Cash or Credit |
    | Transfer | Savings/Cash or Credit | Savings/Cash or Loan; only Savings/Cash from Credit (cash advance) |
    | Credit Card Payment | Savings/Cash | Credit |

  - Spending uses a spending category, and Inflow uses an inflow category or
    none;
  - linked debt rows are never transaction categories.
- **Plans:** a spending category that is not plan-deleted, one plan per
  category per month, and amounts that are not negative.
- **IDs:** unique within each table of the import, not used by any existing
  record of any owner, and never retired.

## What happens

All of these steps run in one transaction:

1. Check the request size and shape.
2. Take the owner's write lock, the same one `fundly_apply_operations` takes,
   so an import and any device's uploads never overlap.
3. Check for a receipt for `import_id`. The same body returns the stored
   result; a different body is refused.
4. Check the mode against the account's current records.
5. Parse and check every record, then apply the rules above.
6. Delete the owner's current records. The existing triggers write a
   tombstone for each one, so other devices remove them at their next
   download.
7. Insert the import.
8. Store a receipt and return the result.

## Result

```json
{ "version": 1, "import_id": "…", "mode": "into_empty",
  "counts": { "custom_account_types": 1, "accounts": 4, "categories": 6,
              "transactions": 5, "monthly_plans": 2 } }
```

## Errors

A refused import changes nothing and stores no receipt.

| Error (SQLSTATE) | Meaning | Detail |
|---|---|---|
| `authentication_required` (28000) | Not signed in. | — |
| `invalid_request` (22023) | Missing import ID, over 8 MiB, or a bad envelope: version, mode, `expected` or the five arrays. | — |
| `import_key_reused` (P0001) | This `import_id` was already used with a different body. | — |
| `dataset_not_empty` (P0001) | `into_empty`, but the account holds real records. | `{current: counts}` |
| `dataset_changed` (P0001) | `replace`, but the counts differ from `expected`. | `{current: counts}` |
| `invalid_import` (P0001) | A record breaks a rule. | `{table, index, field, rule}`; `field` may be null |
| `record_id_unavailable` (P0001) | An ID is in use or retired. It never says whose. | `{table, index, field: "id"}` |

`index` is the record's 0-based position in its array. `invalid_import` rules:

| Rule | Meaning |
|---|---|
| `not_an_object`, `unknown_field`, `missing` | Record shape problems. |
| `invalid_value` | Wrong type or format, or a value outside the allowed set. |
| `invalid_name` | Name breaks the name rules. |
| `name_taken` | Duplicate name, or a built-in type name. |
| `duplicate_id` | The same ID appears twice in one table. |
| `wrong_sign` | Opening balance has the wrong sign for the account type. |
| `not_eligible` | Account cannot be the budget account. |
| `only_one_budget_account` | A second budget account. |
| `invalid_reference` | A referenced record is missing, or a custom type has the wrong base type. |
| `invalid_link` | A linked liability row breaks the linked-row rules. |
| `missing_linked_category` | An active Credit or Loan account has no linked row. |
| `invalid_shape` | Fields do not fit the transaction type. |
| `same_account` | Source and destination are the same account. |
| `account_not_allowed` | The account type is not allowed for this transaction type. |
| `category_not_allowed` | The category kind does not fit, or it is a linked or plan-deleted row. |
| `duplicate_plan` | A second plan for one category in one month. |
| `constraint` | A table constraint caught something these rules missed. This is a server bug to fix. |

## Client rules (implemented in S6.2)

- **Before calling:** wait until no uploads are queued, so a `replace` cannot
  delete changes that have not reached the server.
- **Lost response:** resend the same `import_id` with the identical body. The
  import never applies twice.
- **`dataset_changed` or `dataset_not_empty`:** show the user the current
  counts again. If they confirm, start over with a new `import_id`.
- **Rule errors** (`invalid_import`, `record_id_unavailable`): the import is
  refused and must not be retried unchanged.
- **Other devices:** a device that still has changes queued against the
  replaced records gets `record_deleted` or `record_not_accessible`, and those
  changes go to Refused changes (S5.4).

## Limits measured locally (2026-11-22)

Measured with PostgreSQL 17, as an `authenticated` user with
`statement_timeout = 8s`:

| Transactions | Request size | Server time |
|---|---|---|
| 10,000 | 4.2 MB | 0.60 s |
| 19,000 | 7.9 MB | 1.33 s |

These numbers come from the local stack. The hosted API gateway's request size
limit and the hosted database's speed are checked against a test account
before S6.2 depends on them.
