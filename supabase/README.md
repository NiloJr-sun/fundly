# Fundly cloud database — S2.1 to S2.3

The schema foundation, the transaction, account/custom-type and category/Plans APIs,
and the rejection/deletion protocol are verified **locally only**.
Hosted Supabase, the working PowerSync probe, Flutter dependencies, SQLite v12,
and backup format 6 are unchanged. Owner-only reads and denied direct client
writes remain in place. Authenticated transaction operations now use the
atomic RPC described in [WRITE_API.md](WRITE_API.md), with account operations
documented in [ACCOUNT_API.md](ACCOUNT_API.md), category/Plans operations in
[PLANS_API.md](PLANS_API.md), and rejection details, deleted-record retirement and
the client recovery contract in [SYNC_PROTOCOL.md](SYNC_PROTOCOL.md).

## Files

- `config.toml`: isolated local project `fundly-schema-dev`, PostgreSQL 17,
  database port **55322**. No hosted project is linked by this task.
- `migrations/20261118010000_fundly_schema.sql`: five tables, constraints,
  indexes, server-controlled revisions, table grants and read policies.
- `migrations/20261118020000_transaction_write_api.sql`: secure RPC, private
  validation helpers, and a backend-only receipt table. No replication changes.
- `migrations/20261118030000_account_write_api.sql`: account/custom-type operations,
  guarded budget selection and managed liability categories, using the same receipts.
- `migrations/20261118040000_category_plan_write_api.sql`: category, monthly-plan,
  plan archive (timezone-aware) and permanent-deletion operations. No table changes.
- `migrations/20261118050000_sync_protocol.sql`: backend-only `fundly_deleted_records`
  with delete triggers, retired-UUID checks and structured rejection details.
- `migrations/20261122010000_dataset_initialize.sql`: the `dataset.initialize`
  operation (default categories once per dataset, S5.3).
- `migrations/20261122020000_dataset_import.sql`: `fundly_import_dataset`, an atomic
  whole-dataset import with backend-only import receipts (S6.1,
  [IMPORT_API.md](IMPORT_API.md)).
- `migrations/20261123010000_cash_advance.sql`: Transfers may come from a Credit
  account, to Savings/Cash only (cash advance). Replaces `apply_transaction` and
  `fundly_import_dataset` with only those account checks changed.
- `migrations/20261123020000_multiple_budget_accounts.sql`: any number of budget
  accounts. Drops the one-per-owner index; replaces `apply_account` (set/clear
  per account, no `budget_conflict`) and `fundly_import_dataset` (no
  `only_one_budget_account` check).
- `migrations/20261124010000_spaces.sql` (shared spaces C1.1): `spaces`,
  `space_members`, a Personal space per user (id = user id), `space_id`,
  `created_by` and `updated_by` on every record, per-space keys and rules, and
  membership reads. `owner_id` stays, equal to `space_id`, for the live stream.
- `migrations/20261124020000_space_write_api.sql` (C1.2): the write and
  import RPCs work per space, with an optional `space_id`, role checks and
  per-space locks ([WRITE_API.md](WRITE_API.md), Spaces).
- `migrations/20261124030000_private_spaces.sql` (C2.1): `owner_id` only on
  Personal records (null elsewhere), and the online `fundly_create_space` and
  `fundly_rename_space` RPCs ([WRITE_API.md](WRITE_API.md), Spaces). Grants the
  PowerSync replication role read access to `spaces` and `space_members`.
- `migrations/20261124040000_sharing.sql` (C3.1): invites bound to an email,
  members' names and emails, role changes, removing, leaving and deleting
  spaces ([SPACES_API.md](SPACES_API.md)).
- `rollback/20261124_c3_rollback.sql`: **not a migration.** Removes invites and
  the sharing functions, keeping every record and membership; rehearsed by
  `tests/migration/c3_rollback_test.py`.
- `rollback/20261124_c2_rollback.sql`: **not a migration.** Restores the C1
  rules while no record lives outside a Personal space (refuses otherwise);
  rehearsed by `tests/migration/c2_rollback_test.py`.
- `rollback/20261124_c1_rollback.sql`: **not a migration.** Restores the pre-C1
  API and rules without touching data; rehearsed by
  `tests/migration/c1_rollback_test.py`.
- `tests/database/`: **1064 pgTAP assertions**, run in
  transactions that roll back fixtures and mutations. Test Auth rows are local and do
  not send email or require the probe's `.env` or admin key.
- `tests/concurrency/write_api_test.py`: four real overlapping-session tests
  and one SQL/Dart text-contract check, using Python's standard library only.
- `tests/concurrency/account_write_api_test.py`: seven overlapping-session budget,
  account, custom-type and managed-row checks, reusing that session harness.
- `tests/concurrency/category_plan_write_api_test.py`: nine overlapping-session
  plan-save, plan-archive, plan-deletion and category-deletion checks.
- `tests/concurrency/sync_protocol_test.py`: three delete/edit/re-create races.
- `tests/concurrency/dataset_import_test.py`: four import races (import versus upload in
  both orders, two replaces, the same import sent twice).
- `tests/performance/dataset_import_timing.py`: times a 10,000-transaction import under
  an 8 s statement timeout (pass a different count as the argument).

## Run locally

Requires Docker running and Node/npm. Use the pinned **Supabase CLI 3.2.0** via
`npx`, from the repository root. This installs development tooling in npm's
cache; it does not change Fundly's Flutter dependencies.

```sh
npx --yes supabase@3.2.0 db start
npx --yes supabase@3.2.0 test db
npx --yes supabase@3.2.0 db lint --schema public,fundly_private,fundly_access --fail-on warning
python3 supabase/tests/concurrency/write_api_test.py
python3 supabase/tests/concurrency/account_write_api_test.py
python3 supabase/tests/concurrency/category_plan_write_api_test.py
python3 supabase/tests/concurrency/sync_protocol_test.py
python3 supabase/tests/concurrency/dataset_import_test.py
python3 supabase/tests/concurrency/dataset_initialize_test.py
python3 supabase/tests/concurrency/space_write_api_test.py
python3 supabase/tests/concurrency/sharing_test.py
python3 supabase/tests/client_contract_test.py
python3 supabase/tests/performance/dataset_import_timing.py
# These two RESET the local database (and leave it reset, fully migrated):
python3 supabase/tests/migration/spaces_backfill_test.py
python3 supabase/tests/migration/c1_rollback_test.py
python3 supabase/tests/migration/c2_rollback_test.py
python3 supabase/tests/migration/c3_rollback_test.py
```

`db start` starts the local database and initializes migrations. For an existing
development database, rebuild it to apply the current migration set:

```sh
# Deletes/recreates data in this disposable LOCAL database only.
npx --yes supabase@3.2.0 db reset --yes
npx --yes supabase@3.2.0 test db
```

The Python runner requires Dart in PATH, hardcodes the disposable local
container, creates randomly identified test users/records, and removes them in
cleanup. It never reads `.env` or hosted credentials. Test fixture includes use
the `.inc` extension so the CLI does not discover them as standalone tests.

These commands target the local stack by default in CLI 3.2.0. Do not add
`--remote`, link a hosted project, or run a hosted deployment as part of S2.1.
Keep `.env` files and CLI temporary state ignored. A later reviewed deployment
must verify the hosted PostgreSQL version and migration history first.

To stop this local stack, use `npx --yes supabase@3.2.0 stop`.

## Data and access contract

| Concern | Implemented behavior |
|---|---|
| Tables | `custom_account_types`, `accounts`, `categories`, `transactions`, `monthly_plans`. No probe tables or derived balances. |
| Shared identity | Explicit UUID `id`; no local auto-increment ID is treated as globally unique. Identity and owner cannot change after insertion. |
| Ownership | Every record has a non-null `space_id` (C1); all financial references use space-qualified foreign keys. `owner_id` stays equal to `space_id` while every space is Personal. |
| Reads | Authenticated users see the rows of spaces they are members of through RLS (C1). Missing user claims see no rows. Anonymous reads are denied. |
| Writes | Direct client INSERT, UPDATE, DELETE and TRUNCATE are denied. The RPC permits validated transaction/account/custom-type operations. Trusted backend access remains privileged; never ship that key to Flutter. |
| Revisions | Trigger sets initial revision to 1 and increments on updates. Transaction update/delete RPCs require the exact expected revision. |
| Audit metadata | `created_at` / `updated_at` are `timestamptz`. The transaction RPC supplies server time and preserves creation time on edits; clients cannot set audit fields. |
| Money | PostgreSQL `bigint` minor units; PHP only. Asset/liability opening signs, positive transactions, and nonnegative plan amounts are enforced. No floating-point columns. |
| Names | 1–40 characters; space-scoped uniqueness folds ASCII A–Z only, matching SQLite NOCASE rather than a locale-dependent Unicode fold. |
| Budget account | Any number per space since 2026-11-23; active asset accounts only. |
| Plans | Unique per space/category/month; nullable Target differs from zero. Archive/deleted flags and linked-plan shape are constrained. |
| Deletion | Transactions restrict account/category deletion; used custom types cannot be deleted. Deleting an unused category cascades plans. Deleting an unused linked account nulls only the category's link, preserving its owner and advancing its revision. |
| Auth-user deletion | Restricted while Fundly records reference the user; a user with none takes their Personal space and memberships with them (C1). Account deletion workflows are not implemented here. |

Transaction row CHECKs enforce valid types and field combinations, different
transfer endpoints, payee/note limits, and required spending/inflow payees.
The transaction RPC enforces account roles, archived-reference rules, category
kinds and linked-category eligibility. Account/custom-type and category/Plans
workflows are implemented. Do not use privileged direct writes as a production workaround.

PostgreSQL `bigint` can exceed browser/Dart transport limits. The future client
boundary must validate supported numeric ranges without rounding. No range was
silently narrowed in this foundation migration.

## Calendar-date edge case

Transaction `date` is SQL `date`, without a time or timezone; month remains
validated `YYYY-MM`. Both support the existing application's four-digit year
range, including ISO year **0000**. PostgreSQL has no textual year zero and
represents that year as **0001 BC**; its range constraint and leap-day test
preserve this mapping. Future upload/download, backup and import adapters must
map ISO year 0000 ↔ SQL 1 BC explicitly. Ordinary positive years map directly.
Do not feed BC date strings into the existing `CalendarDate.parse` unchanged.

## Verification recorded on 2026-11-18

- Clean `db start` and `db reset --yes` applied the migration on PostgreSQL
  **17.12** without touching other local projects.
- S2.1 `test db`: **173 assertions passed**, including all four transaction shapes,
  null/zero Targets, UUID/money/time types, invalid row values, uniqueness,
  cross-owner references, referential delete actions, revision handling, two
  authenticated users, missing claims, anonymous access and denied client writes.
- `db lint --schema public --fail-on warning`: no schema errors found.
- Repository `dart format .`: 186 files, zero changed; `flutter analyze`: no
  issues; `flutter test`: **844 passed**. No app code changed, so no iOS build
  was required for this SQL/configuration task.

S2.2A added **147 API assertions**, for **320 total passing SQL assertions**.
These verify strict input fields/types, transaction rules, partial edits,
archived references, Unicode/UTF-16 limits, exact bigint/year-zero serialization,
atomic create/update/delete rollback, revision conflicts, retry receipts and
access restrictions. Lint of both `public` and `fundly_private` is clean.

The Python runner passed all five checks: identical concurrent retries commit
once; changed-payload key reuse fails; competing same-revision edits have one
winner; different users commit independently; SQL text normalization and UTF-16
length agree with the installed Dart VM on 31 samples. Each same-user race
observes a real advisory-lock wait in `pg_stat_activity` before releasing the
first session's open transaction. This is not a sequential simulation.

S2.2B brings the total to **435 passing SQL assertions**, including account/custom-type
rules, signed openings, archived usage, linked-row flags/history, name collisions,
budget snapshots, canonical side effects and whole-batch rollback. Seven additional
real-session races verify budget selection, archival/spending order, type changes
versus usage, and stable linked-row creation on retries.

S2.2C brings the total to **610 passing SQL assertions**, adding category rules,
managed-row refusals, plan save/clear with observed snapshots, null versus zero
Targets, the archive allocation guard by timezone month and budget source, unarchive
and permanent-deletion rules, rollback, replay and denied direct writes. Nine more
real-session races cover concurrent plan creation, archive versus spending and
assignment, and deletion versus spending.

S2.3 brings the total to **666 passing SQL assertions**, adding tombstones for every
entity and cascade, retired-UUID refusal for the same and other owners, deleted
references, rejection positions and current conflict values, merged details,
rollback without tombstones, replay and backend-only access. Three more races cover
delete versus edit in both orders and delete versus re-create. All runners remove
their fixtures' tombstones before deleting test users.

No hosted deployment, client integration, PowerSync production stream, or
real-data migration is claimed. The client recovery contract is defined for S5,
not implemented. S2 is complete; S3 needs its own approval.

S6.1 (2026-11-22) brings the total to **789 passing SQL assertions** across seven
files, including 100 for the dataset import. They cover:

- envelope and record-shape refusals;
- every final-state rule;
- both modes, including untouched versus renamed default categories;
- stale counts, retries and import-ID reuse;
- tombstones for replaced records;
- retired IDs and other owners' IDs;
- preserved values, flags, timestamps and year 0000.

Lint of `public` and `fundly_private` is clean. Four more real-session races
cover:

- an import and an upload, in both orders;
- two replaces confirmed against the same counts;
- the same import sent twice at once.

The timing check imported 10,000 transactions (4.2 MB) in 0.60 s and
19,000 (7.9 MB) in 1.33 s under an 8 s statement timeout. Deployed to the hosted
project on 2026-11-22 (see `powersync/README.md`, verification record).

Cash advances (2026-11-23) bring the total to **794 passing SQL assertions**: a
Transfer from a Credit account to Savings/Cash is accepted by both the write API
and the import, Credit to Loan is refused by both, and a Loan still cannot be a
Transfer source. Lint is clean; the write-API and import races and the 14
client-contract checks pass. Deployed to the hosted project (confirmed 2026-11-23, see powersync/README.md).

Several budget accounts (2026-11-23) keep the total at **794**: the one-budget
refusals became checks that a second budget account is accepted (schema,
write API, sync protocol and import), plus per-account set/clear no-ops. The
account races now check that two concurrent selections both apply and that an
archive committed first blocks a selection. All races and the 14
client-contract checks pass. Deployed to the hosted project (confirmed 2026-11-23, see powersync/README.md).
