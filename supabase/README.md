# Fundly cloud database — S2.1

The production schema foundation is implemented and verified **locally only**.
Hosted Supabase, the working PowerSync probe, Flutter dependencies, SQLite v12,
and backup format 6 are unchanged. This stage provides owner-only reads and
denies all direct client writes; the write API is the separate S2.2 task.

## Files

- `config.toml`: isolated local project `fundly-schema-dev`, PostgreSQL 17,
  database port **55322**. No hosted project is linked by this task.
- `migrations/20261118010000_fundly_schema.sql`: five tables, constraints,
  indexes, server-controlled revisions, table grants and read policies.
- `tests/database/schema_test.sql`: **173 pgTAP assertions**, run in a transaction
  that rolls back both fixtures and mutations. Test Auth rows are local and do
  not send email or require the probe's `.env` or admin key.

## Run locally

Requires Docker running and Node/npm. Use the pinned **Supabase CLI 3.2.0** via
`npx`, from the repository root. This installs development tooling in npm's
cache; it does not change Fundly's Flutter dependencies.

```sh
npx --yes supabase@3.2.0 db start
npx --yes supabase@3.2.0 test db
npx --yes supabase@3.2.0 db lint --schema public --fail-on warning
```

`db start` starts the local database and initializes migrations. For an existing
development database, rebuild it to apply the current migration set:

```sh
# Deletes/recreates data in this disposable LOCAL database only.
npx --yes supabase@3.2.0 db reset --yes
npx --yes supabase@3.2.0 test db
```

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
| Ownership | Non-null `owner_id` references Supabase Auth; all financial references use owner-qualified foreign keys. |
| Reads | Authenticated users see their own rows through RLS. Missing user claims see no rows. Anonymous reads are denied. |
| Writes | Client INSERT, UPDATE, DELETE and TRUNCATE are denied. Trusted backend `service_role` access remains privileged; never ship that key to Flutter. |
| Revisions | Trigger sets initial revision to 1 and increments on updates, overriding supplied revision values. Expected-revision checking comes in S2.2. |
| Audit metadata | `created_at` / `updated_at` are `timestamptz`, defaulting to now on insert. Future RPCs control update timestamps; explicit insert timestamps support history import. |
| Money | PostgreSQL `bigint` minor units; PHP only. Asset/liability opening signs, positive transactions, and nonnegative plan amounts are enforced. No floating-point columns. |
| Names | 1–40 characters; owner-scoped uniqueness folds ASCII A–Z only, matching SQLite NOCASE rather than a locale-dependent Unicode fold. |
| Budget account | At most one per owner; active asset accounts only. Switching it atomically is an S2.2 operation. |
| Plans | Unique per owner/category/month; nullable Target differs from zero. Archive/deleted flags and linked-plan shape are constrained. |
| Deletion | Transactions restrict account/category deletion; used custom types cannot be deleted. Deleting an unused category cascades plans. Deleting an unused linked account nulls only the category's link, preserving its owner and advancing its revision. |
| Auth-user deletion | Restricted while Fundly records reference the user. Account deletion workflows are not implemented here. |

Transaction row CHECKs enforce valid types and field combinations, different
transfer endpoints, payee/note limits, and required spending/inflow payees.
Cross-table rules (such as allowed account roles, archived references, linked
category eligibility, and valid plan category kinds) still require S2.2's
transactional API. Do not use privileged direct writes as a production workaround.

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
- `test db`: **173 assertions passed**, including all four transaction shapes,
  null/zero Targets, UUID/money/time types, invalid row values, uniqueness,
  cross-owner references, referential delete actions, revision handling, two
  authenticated users, missing claims, anonymous access and denied client writes.
- `db lint --schema public --fail-on warning`: no schema errors found.
- Repository `dart format .`: 186 files, zero changed; `flutter analyze`: no
  issues; `flutter test`: **844 passed**. No app code changed, so no iOS build
  was required for this SQL/configuration task.

No hosted deployment, production RPC, concurrency workflow, rejection recovery,
PowerSync production stream, or real-data migration is claimed. The next
reviewed task is S2.2, followed by S2.3's durable rejection/retry protocol.
