# Cloud write API — protocol 1

Implemented locally in `20261118020000_transaction_write_api.sql`; not deployed
to hosted Supabase. The Flutter app and the separate probe are unchanged.
S2.2B adds [account and custom-type operations](ACCOUNT_API.md) through the same
RPC; the transaction contract below is unchanged.

## Request

Call `fundly_apply_operations` with these PostgreSQL RPC argument names:

```json
{
  "batch_id": "61000000-0000-4000-8000-000000000001",
  "operations": {
    "version": 1,
    "items": [
      {
        "operation": "transaction.create",
        "id": "41000000-0000-4000-8000-000000000001",
        "data": {
          "type": "spending",
          "amount_minor": "12345",
          "date": "2026-11-18",
          "payee": "Groceries",
          "source_account_id": "21000000-0000-4000-8000-000000000001",
          "category_id": "31000000-0000-4000-8000-000000000001"
        }
      }
    ]
  }
}
```

The example IDs must refer to the caller's own records. Account creation is
supported by S2.2B and category creation by S2.2C ([PLANS_API.md](PLANS_API.md)). `transaction.update` requires an
`expected_revision` decimal string and a nonempty partial `data` object.
`transaction.delete` requires the revision and omits `data` (or supplies `{}`).

Create requires `type`, `amount_minor`, and `date`. Currency defaults to PHP;
payee/note to empty strings; account/category references to null. Validated
transaction types still determine which fields and references are required.
On updates, omitted fields retain their values. Explicit null clears a nullable
reference, but must still produce a valid transaction. Type cannot change.

For transaction operations, allowed data keys are `type`, `amount_minor`, `currency_code`, `date`, `payee`,
`note`, `category_id`, `source_account_id`, `destination_account_id`. Reject all
other envelope, operation, and data keys, including owner, IDs inside data,
revisions, and audit timestamps. The target space comes from the envelope's
optional `space_id`, or is the caller's Personal space (see Spaces below).

Limits: 1–100 ordered operations, at most 262144 bytes of canonical JSONB text.
Transaction amounts and expected revisions are positive canonical decimal **strings** without
signs, leading zeroes, fractions or exponent notation, bounded by signed bigint.
Native JSON numbers are rejected for these fields to avoid browser rounding.
Account opening inputs additionally allow `"0"`; see [ACCOUNT_API.md](ACCOUNT_API.md).
UUIDs use the standard hyphenated form. Dates are strict ISO `YYYY-MM-DD`,
including year 0000, converted to/from PostgreSQL 1 BC at the API boundary.
Protocol `version` must be JSON integer `1`.

Payee and note are normalized with Unicode White_Space plus BOM trimming and
validated using UTF-16 code-unit lengths (60/500), matching the current Dart VM
in the differential test. Future browser integration must also verify its
runtime's whitespace behavior; U+0085 can vary by Unicode implementation.

## Results and retries

The result has `version`, `batch_id`, and ordered `results`. Each accepted write
includes `operation`, `id`, a decimal-string `revision`, and a canonical `record`.
Record money/revision values are strings and audit timestamps use UTC `Z`.
A delete returns `deleted: true` and the deleted row's prior revision.

All operations and the success receipt commit atomically. Any failure rolls back
the entire batch, including earlier edits/deletes, and writes no success receipt.
Receipts are keyed by user/batch and contain a SHA-256 fingerprint of canonical
JSONB, protocol version, committed response and time; they have no expiry policy.
They are inaccessible through client table reads/writes and are not for replication.

Retry the **same batch UUID and payload** after a timeout or lost response.
Object key order/JSON formatting are normalized by JSONB; array order and field
presence remain significant. Same-key different-payload requests fail. Receipt
lookup occurs before row revision checks, so a successful retry returns its
original result even if records have since changed or been deleted. That cached
result is not necessarily the current row state; future clients must reconcile
by revision and the synchronized dataset.

Every batch holds a transaction-level advisory lock derived from the target
space (for a Personal space, the authenticated user's id), through commit/rollback. RPCs use PostgreSQL's default READ COMMITTED
isolation with VOLATILE writes/queries, so a waiting request sees the preceding
commit. Future domain operations must share this lock protocol. Direct admin
writes outside the API are not covered by this serialization contract; row
locks also protect referenced accounts/categories during validation and commit.

## Spaces (shared spaces C1)

Records belong to a **space**; users are members of spaces with a role
(`owner`, `editor`, `viewer`). Every user has a **Personal** space whose id is
their user id. Wherever these documents say "owner" or "the caller's", read
"the target space's".

- The envelope may carry an optional `space_id` (UUID string). Without it, the
  batch goes to the caller's Personal space, which is what every app up to
  1.2.1 sends. An explicit `null` or a malformed value is `invalid_request`.
- The caller must be an owner or editor of the target space. Otherwise the
  whole batch is refused with `P0001`:
  - `not_space_member`: not, or no longer, a member (or no such space);
  - `space_read_only`: a viewer.
  These are final rejections (SYNC_PROTOCOL.md): apps 1.2.x log them in
  Refused changes and continue.
- A retried batch is answered from its receipt before the role check, so a
  batch applied before a membership ended still returns its original result.
- The advisory lock is per **space** (`'fundly:' || space_id`); for a Personal
  space it is the same key as before C1. Receipts stay keyed by the sender and
  record the space.
- Each record stores `created_by` and `updated_by` (the sender). They are not
  downloaded yet; results may include them, and clients ignore them.
- Since C2, `owner_id` is set only on a Personal space's records (null in any
  other space), so the legacy stream carries exactly Personal.

### Creating and renaming spaces (C2, online only)

All space and member management, including C3's invites, roles, leaving and
deleting, is in [SPACES_API.md](SPACES_API.md).

```sql
select public.fundly_create_space(space_id uuid, name text);
select public.fundly_rename_space(space_id uuid, name text, expected_revision text);
```

Both return `{ "id", "name", "personal", "revision" }` (revision as a decimal
string). Names are trimmed, 1–40 UTF-16 units, and unique among the spaces the
caller owns, ignoring ASCII case; Personal can be renamed. Creating makes the
caller the owner; retrying the same id and name returns the space. A user owns
at most 10 spaces, Personal included. Both take a per-user lock.

| SQLSTATE | Message | Meaning |
|---|---|---|
| `22023` | `invalid_request` | Missing id, or a malformed `expected_revision`. |
| `P0001` | `invalid_name` | Empty after trimming, or over 40 UTF-16 units. |
| `P0001` | `name_taken` | The caller already owns a space with that name. |
| `P0001` | `space_id_unavailable` | The id is used by another space (or the same id with another name). |
| `P0001` | `space_limit_reached` | The caller already owns 10 spaces. |
| `P0001` | `not_space_member` / `space_owner_only` | Rename by a non-member / non-owner. |
| `P0001` | `revision_conflict` | Rename from a stale revision; detail has `current_revision`. |


## Errors

| SQLSTATE | Message | Meaning |
|---|---|---|
| `42501` | PostgreSQL permission error | Anonymous RPC or direct forbidden table/helper access. |
| `28000` | `authentication_required` | No authenticated user claim. |
| `22023` | `invalid_request` | Invalid shape, field/type, limit, decimal string, UUID or calendar date. |
| `P0001` | `unsupported_operation` | Operation outside this implemented slice. |
| `P0001` | `record_not_accessible` | Referenced/edited/deleted record is missing or not owned by the caller. |
| `P0001` | `revision_conflict` | Update/delete expected revision is stale. |
| `P0001` | `invalid_transaction` | A financial/domain rule fails. |
| `P0001` | `transaction_id_unavailable` | Create would reuse an existing UUID; no other owner's record details are returned. |
| `P0001` | `batch_key_reused` | A committed key was used for another payload. |
| `P0001` | `not_space_member` | The caller is not a member of the target space. |
| `P0001` | `space_read_only` | The caller is a viewer of the target space. |

Database availability/serialization failures can still occur; retry the whole
request with the original key after transient errors. Do not silently retire a
client queue item because a domain error occurred. Error classes, rejection
details, deleted-UUID retirement (`record_deleted`) and the client recovery
contract are defined in [SYNC_PROTOCOL.md](SYNC_PROTOCOL.md).
Keep the production client disconnected until the remaining slices are ready.

## Verification

From the repository root, with the disposable local stack running:

```sh
npx --yes supabase@3.2.0 db reset --yes
npx --yes supabase@3.2.0 test db
npx --yes supabase@3.2.0 db lint --schema public,fundly_private --fail-on warning
python3 supabase/tests/concurrency/write_api_test.py
```

The reset targets the local `fundly-schema-dev` database. Do not pass `--remote`.
The concurrency runner hardcodes that local container, proves contention with
independent open SQL sessions, cleans up test records, and does not use `.env`.
