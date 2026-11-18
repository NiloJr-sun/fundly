# S2.2 — Secure write API implementation proposal

Date: 2026-11-18
Status: proposed for approval; no SQL deployment or implementation in this task.

## Starting point

S2.1 provides the five cloud tables, owner-scoped SELECT policies, immutable
identities and monotonically increasing revisions. Direct client writes are
denied. Its migration and 173 SQL assertions are committed. The Flutter app
still uses local schema v12 and backup format 6. This task does not change
financial rules, integrate SDKs, or migrate existing data.

The API must reproduce the existing repositories, including their differences
between creating new records and editing records that already use archived
accounts/categories. Raw row upserts alone cannot enforce these workflows.

## Proposed API contract

Expose a single authenticated PostgreSQL RPC:

```text
fundly_apply_operations(batch_id UUID, operations JSONB) → JSONB
```

`operations` is an envelope `{ "version": 1, "items": [...] }`. Each item
contains `operation` (for example `transaction.create`), a UUID `id`, a `data`
object of allowlisted domain fields, and an `expected_revision` decimal string
for updates/deletes. Creates omit the revision. The response contains `version`,
`batch_id`, and ordered `results`; canonical records use decimal strings for
bigint values. Explicit nulls and omitted fields have separately validated
meanings; partial updates must not accidentally erase nullable references.

- A versioned request contains an ordered list of named domain operations, not
  arbitrary table names or SQL. Reject unknown operations, fields, JSON types,
  fractional money, excessive batch sizes, and unsupported protocol versions.
- Derive the owner from `auth.uid()`. Never accept an owner, audit timestamp or
  chosen revision from the client. New records have client-generated UUIDs;
  updates/deletes include expected revisions. An absent record is an error, not
  an implicit upsert. Cross-owner references return a generic inaccessible-record
  error without revealing the other user's data.
- Hold a transaction-level advisory lock scoped to the user before reading
  receipts or financial records. Apply each batch atomically. Different users
  can write concurrently; operations for one user are serialized.
- Use a fixed empty search path, fully qualified SQL names, and no dynamic SQL
  built from request text. Public EXECUTE is revoked from internal helpers.
  Only the entry RPC is executable by authenticated clients; table write grants
  remain denied. A SECURITY DEFINER entry must explicitly check ownership on
  every read and mutation because it can bypass RLS.
- Return operation results with affected record IDs, canonical values, and
  revisions, including indirectly changed budget accounts and liability rows.
  Deletes return IDs and prior revisions. Decimal strings for bigint money and
  revisions avoid browser JSON-number rounding; the future client adapter must
  convert exactly without `double`. This is a cloud wire contract only.
- Server updates audit timestamps; preserve `created_at` on edits. ISO dates,
  including year 0000 ↔ PostgreSQL 1 BC, are converted explicitly at the RPC
  boundary. No change to the local backup format is included.

## Durable retry receipts

Add a backend-only `fundly_write_receipts` table keyed by `(owner_id, batch_id)`
with a canonical-request SHA-256 fingerprint, protocol version, committed result,
and creation time. Scope its access to internal helpers; do not replicate it.
Store the receipt in the same transaction as accepted financial changes.

An identical retry returns the original result, including generated linked-row
IDs. Reusing the same key for a different request is rejected. Compare receipts
before validating revisions so an already committed request succeeds after a
lost response. No automatic receipt expiry is introduced: expiry could make an
old retry execute twice. Invalid/stale batches roll back without a success
receipt. Durable rejection records and client queue recovery remain S2.3.

## Operations and repository parity

| Area | Required operations and behavior |
|---|---|
| Transactions | Create, edit and delete. Positive PHP amounts; correct account roles per type; no self-transfer; valid category kind; no linked debt category in ordinary pickers; required payee and length limits. Type is immutable. Edits may retain the same archived references but cannot introduce archived references. |
| Custom account types | Create, rename/change base and delete. Trimmed names, no built-in name reuse; base changes and deletion only while no active or archived account uses the type. |
| Accounts | Create, edit metadata/opening amount, archive/unarchive and delete. Base type immutable; matching custom base type; opening amount accepted as nonnegative input and signed server-side. Delete only if archived and unused by transactions. |
| Budget account | Set or clear atomically, validating the current budget selection as well as the chosen account revision so an offline request cannot unknowingly replace a newer selection. Archiving clears the flag. |
| Liability rows | Account creation/rename/archive updates its managed category atomically. Never recreate a permanently deleted Plans row. Direct ordinary-category operations cannot mutate managed rows. Account deletion detaches its category. |
| Categories | Create, rename, change Plans group, archive/unarchive and delete. Kind immutable; inflows stay in the default group. Deletion only when unused by transactions; cascade monthly plans. |
| Monthly plans | Save Target/Assigned or clear by category/month. Preserve null versus zero Target; null Target plus zero Assigned removes the record. Require a spending category and enforce archived/deleted-plan rules exactly as the repository does. |
| Plan lifecycle | Archive/unarchive and delete permanently. Recheck all history and assignments atomically; preserve category/account. Archiving checks current/future remaining allocations using budget-source spending or linked payments. Unarchive requires active parent; permanent deletion requires archived state, zero Assigned in every month and no eligible activity. |

Match Dart trimming and UTF-16 length limits in helpers rather than assuming SQL
`btrim`/`char_length` have identical Unicode behavior. Preserve existing ASCII
case-insensitive database uniqueness. Derive balances/activity from transactions,
never write independent balances or change Ready to assign formulas.

## Two explicit compatibility decisions

1. **Calendar month for archival:** propose requiring a valid IANA timezone on
   the plan-archive operation. The server derives the actual month at application
   time in that timezone; do not trust a supplied month or use server UTC by
   default. Include the timezone in the receipt fingerprint. Delayed offline
   archive requests are checked against current conditions when uploaded. The
   future Flutter integration must supply the device timezone explicitly.
2. **Liability name collisions:** existing suffixes contain integer account IDs.
   For new UUID accounts, propose a deterministic short UUID suffix, with a
   collision counter and the same 40-character limit. Preserve existing names
   during later import; apply the new suffix scheme only when a collision needs
   resolution. Test collisions against both normal and managed categories.

These are proposed adaptations requiring approval with the API plan, not changes
already made to confirmed behavior.

## Delivery slices

Implement and review one slice at a time:

| Slice | Files | Acceptance |
|---|---|---|
| S2.2A — RPC, receipts and transaction operations | New versioned SQL migration; `supabase/tests/database/write_api_test.sql`; an isolated two-session concurrency test; `supabase/README.md` | Secure entry and transaction create/edit/delete against privileged test fixtures, atomic rollback, exact serialization and idempotent retries. |
| S2.2B — Custom types, accounts and linked rows | Separate SQL migration and repository-parity SQL tests | Atomic managed rows, guarded account lifecycle and budget switching, name/custom-type compatibility. |
| S2.2C — Categories and Plans lifecycle | Separate SQL migration and tests | All category/plan workflows, financial allocation checks and timezone boundary cases. |

S2.2A does not expose unfinished operations: they return unsupported-operation
errors. Keep the production Flutter client disconnected until all required
operations and S2.3 recovery are ready. No hosted schema changes are included.

## Verification

Run the existing 173 schema assertions and add positive/negative RPC tests for
both owners, no session, forged ownership, malformed payloads, disallowed fields,
each transaction role/category rule, archived-reference edits, stale revisions,
and ISO date/large-money round trips. Prove whole-batch rollback when a later
operation fails. Verify same-key retries after commit, mismatched-key payloads,
and backend-only receipt privileges.

Use independent database sessions to test overlapping writes: same batch key
with identical and different payloads, and two updates with the same expected
revision. In later slices add budget-switch and archive-versus-spending races.
Document lock/transaction behavior; do not substitute sequential SQL for these
concurrency tests.

Use only the isolated local Supabase stack. Rebuild migrations locally and run
`supabase test db`, schema lint, `dart format .`, `flutter analyze`, and the full
Flutter suite. No iOS build is needed for SQL/docs-only changes. Record exact
commands/counts and stage only the approved slice; never commit or push.

## Approval requested

Approve **S2.2A only**, including the RPC envelope, server-only receipt table,
exact bigint wire format, security helpers and transaction operations/tests.
Review B/C separately; the timezone and name-suffix decisions must be settled
before implementing their affected operations. S2.3 retains tombstones, durable
rejections and dependency-aware client reconciliation. No personal-data import,
SDK integration or hosted deployment is authorized by this proposal.
