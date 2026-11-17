# S2 — Production cloud schema and secure write API

Date: 2026-11-18

Status: concrete proposal for approval under AGENTS.md §1. Connection feasibility
has been accepted by the owner. This proposal does not deploy SQL or migrate
personal data. S1's untested conflict/rejection cases remain explicit work.

## Intended result

A versioned, testable Supabase backend for Fundly's existing financial model.
Authenticated users can read their own records and submit validated atomic
writes. Invalid writes, stale edits, and references to another user's records
cannot alter the dataset. The Flutter app remains on its existing local schema
v12 and backup format 6 during S2.

## Files and task boundaries

Deliver one reviewed task at a time, starting with **S2.1**:

| Task | Files | Deliverable |
|---|---|---|
| S2.1 — Tables and access boundaries | `supabase/config.toml`, `supabase/migrations/*_fundly_schema.sql`, `supabase/tests/database/schema_test.sql`, `supabase/README.md` | Five cloud tables, ownership, constraints, read policies, denied direct client writes, executable SQL tests and local setup instructions. |
| S2.2 — Atomic write API | A separate SQL migration and API/transaction test files | Validated operations covering existing repository workflows, optimistic revisions and durable batch receipts. |
| S2.3 — Rejection and retry protocol | API migration/tests plus a protocol document | Idempotent retries, durable rejection results, conflict details and an agreed client reconciliation contract. |

S2.1 is a backend foundation only. It does not enable Fundly sign-in or cloud
editing, and must not temporarily grant direct write access to bypass the
unfinished API. Dependencies for local tooling must be explained before install.

## S2.1 schema defaults

- Tables: `custom_account_types`, `accounts`, `categories`, `transactions`,
  `monthly_plans`; preserve existing business fields and enum spellings.
- Shared `id` values are UUIDs; every row has `owner_id` tied to the Supabase
  authenticated user and a positive server-controlled revision. Use UUIDs for
  all cloud references. No change to local integer IDs in this task.
- Store money as integer minor units (`bigint`), currency fixed to PHP. Preserve
  signed opening balances and positive transaction amounts. Client conversion
  must reject unsupported numeric ranges before future web integration.
- Transaction dates are SQL `date`; months remain validated `YYYY-MM`; audit
  timestamps use `timestamptz`. Clients will retain local calendar-date semantics.
- Scope case-insensitive name uniqueness to each owner. Match SQLite's ASCII
  NOCASE behavior rather than silently introducing different Unicode matching.
- Enforce one budget account per owner, one plan per owner/category/month,
  and one linked Liability Plans category per account. Preserve zero versus
  null Target and the existing archive/deleted-plan flags.
- Owner-qualified foreign keys prevent cross-user references. Preserve existing
  restrict/cascade/detach semantics; test nullable linked-account detachment
  without nulling the owning user's ID.
- SQL CHECKs validate row-local transaction shape, distinct transfer endpoints,
  positive amounts, name/payee/note limits, valid enum values, opening-balance
  sign, and valid Plans flags. Cross-table financial rules belong in S2.2.
- RLS allows authenticated users to read only their own records; anonymous
  reads and client INSERT/UPDATE/DELETE are denied. No admin credential ships
  with Flutter. Future RPCs must derive ownership from `auth.uid()`.
- Add owner and lookup indexes for later filtered replication and reads. Do not
  alter the working probe's publication, Sync Streams or authentication settings.

## S2.2/S2.3 design requirements

Port repository rules without changing financial behavior: account roles,
archived-reference rules, immutable transaction type, category kinds, custom
type compatibility, budget switching, automatic liability rows, and atomic
plan/account/category archive and deletion checks. Server validation must cover
direct RPC calls, not depend on Flutter validation.

Use a server transaction per logical operation, serialize conflicting writes
within a user's dataset, and validate expected revisions. Idempotency receipts
must be scoped to the user and operation key, retain a payload fingerprint,
and reject key reuse with a different payload. Never acknowledge an operation
before its outcome is durably recorded.

Persist rejection details before retiring a failed client queue item. Define
reconciliation of optimistic local rows, dependent queued changes, deleted IDs,
and unrelated operations. Tombstone/identity-retention and rejection-table
schemas need the S2.3 proposal; do not treat the probe's blocked-queue behavior
as the production policy. S5 must prove the client implementation end to end.

Plans checks that depend on the actual local calendar month require an explicit
client/server timezone contract before implementing those operations.

## Verification and deployment

Run executable PostgreSQL tests for valid fixtures, every row constraint,
owner-scoped uniqueness, nullable and cross-owner references, two authenticated
users, anonymous access, and denied direct client writes. Later API tests must
cover concurrent budget switches, archive versus spending races, stale edits,
deleted-record resurrection, all-or-nothing batches, and retries after commit.

Use a local Supabase instance or an isolated test database first. If Docker or
database tooling is unavailable, report the exact blocker; do not call unrun SQL
tests passing or apply unverified migrations to the hosted project.

Run `dart format .`, `flutter analyze`, and the full `flutter test` suite for
the task. No iOS build is needed for SQL/docs-only work. Keep migration SQL in
Git; use the supported Supabase migration workflow rather than untracked manual
production edits. Review the tested migration and target project before hosted
deployment. Never reset or replace the owner's existing database.

## Approval requested

Approve **S2.1 only**: create the versioned cloud tables, access restrictions,
SQL tests and local tooling configuration. No hosted deployment, Flutter SDK
integration, local schema migration, backup changes or personal-data import is
included. Review S2.2 and S2.3 separately after the foundation is verified.
