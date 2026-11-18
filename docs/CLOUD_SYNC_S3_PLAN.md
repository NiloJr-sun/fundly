# S3 — Connect PowerSync and configure authentication: proposal

Date: 2026-11-18
Status: approved 2026-11-18. Agent files are done and rehearsed locally; the
hosted steps are pending the owner. Procedure and verification record:
[powersync/README.md](../powersync/README.md). The stream check lives at
`tool/sync_probe/test/fundly_stream_test.dart` (host VM test, skipped without
credentials) rather than `integration_test/`, so it needs no device.

## Starting point

S2 (schema, write API, rejection/deletion protocol) is verified on the local
stack only: 5 migrations, 666 SQL assertions, 24 race checks. The hosted Tokyo
Supabase project holds only the S1 probe objects (`probe_parents`,
`probe_entries`, `probe_receipts`, `probe_apply_batch`), created through the SQL
editor. The JP PowerSync instance replicates the probe tables, validates Supabase
JWTs and serves the probe's user-filtered stream. Two disposable email/password
test users exist. Google sign-in is not configured.

S3 is the first step that changes hosted services. Its acceptance (from the
plan): two test users authenticate and receive only their own records, and
expired or invalid sessions cannot open another user's stream. The Fundly app is
not changed. Sign-in in the app is S4, and syncing repositories is S5.

## Who does what

Anything that needs a secret (database password, Google client secret,
replication password) or changes a dashboard is done by the product owner. I
prepare reviewed files and commands, and run read-only checks with test-user
credentials that the owner supplies through environment variables. Those
credentials are never printed or stored.

| Step | Owner | Agent |
|---|---|---|
| 1. Deploy S2 migrations | Runs `link` and `db push` (needs the DB password) | Prepares the commands; reviews the `--dry-run` output with the owner |
| 2. Replication | Runs the reviewed publication SQL; refreshes the PowerSync connection | Writes `powersync/publication.sql` |
| 3. Sync Streams | Validates and deploys in the PowerSync dashboard | Writes `powersync/sync-config.yaml` |
| 4. Google OAuth | Creates Google OAuth clients; enters them in Supabase | Writes the checklist and records public IDs |
| 5. Verification | Supplies test credentials via env vars | Runs the API and stream isolation checks; records results |
| 6. Probe cleanup | Runs the reviewed cleanup SQL | Writes it; reruns checks |

## Decision 1 — deploy S2 to the hosted project (needs approval)

S3 cannot replicate tables that do not exist. The proposal is to apply the five
versioned migrations to the hosted project, unchanged:

```sh
npx --yes supabase@3.2.0 link --project-ref <ref>      # owner; prompts for DB password
npx --yes supabase@3.2.0 db push --remote --dry-run    # review: exactly the 5 Fundly files
npx --yes supabase@3.2.0 db push --remote              # owner, after review
```

- No migration history exists on the hosted project (the probe used the SQL
  editor), so all five apply in order. No name collides with a probe object.
- This only creates empty tables, private functions and the RPC, with direct
  client writes denied. No personal data is imported (that is S6).
- Afterwards, run the Supabase security and performance advisors
  (`db lint --remote`) and record the result.
- If something fails, the tables are empty, so rollback is a reviewed drop
  script. No automatic down migration is added.

## Decision 2 — retire the probe from replication (needs approval)

A PowerSync instance serves one sync configuration. Deploying Fundly's streams
replaces the probe's, so the live probe stops syncing. Its local tests still run.

**Proposal:** deploy only Fundly's streams and remove the probe tables from the
publication. After every S3 check passes, drop the probe's cloud objects with a
reviewed cleanup script. Keep the probe package in the repository as evidence.
The test users stay for S3–S5 checks.

The alternative is a second PowerSync instance for Fundly. That costs another
free-tier instance and gains nothing, because the probe has served its purpose.

## Replication and streams

`powersync/publication.sql` (idempotent, reviewed, run by the owner) adds
exactly the five Fundly tables to the `powersync` publication and removes the
probe tables. `fundly_write_receipts` and `fundly_deleted_records` are never
published. The script ends by listing `pg_publication_tables` for the record.

`powersync/sync-config.yaml` (edition 3) defines one auto-subscribed stream with
five queries, each filtered by `owner_id = auth.user_id()`. They select explicit
columns rather than `SELECT *`, so a future backend-only column cannot leak.
`owner_id` itself is not downloaded. The five tables share one priority, as
deferred foreign keys require (S1 finding).

Download types, recorded for S5 rather than changed now:
- **Money and revisions download as integers.** App input is capped at 12 whole
  digits, about 10^14 centavos, well inside the 2^53 that Flutter web can hold
  exactly. The API accepts up to the bigint maximum, so S5 must refuse or flag
  downloaded values outside ±(2^53−1) on web rather than round them.
- **Dates download as text.** S5 must verify how PowerSync serializes year 0000
  (SQL 1 BC) and map it explicitly, as the README already requires.

## Authentication

- **PowerSync ↔ Supabase JWT:** already configured and working for the probe.
  Keep it, and confirm that the audience and signing-key settings match
  production use.
- **Google OAuth (owner, dashboards):**
  - Create a Google Cloud OAuth *Web* client with authorized redirect
    `https://<ref>.supabase.co/auth/v1/callback`, and an *iOS* client for bundle
    ID `com.nilojr.fundly`.
  - Enable the Google provider in Supabase with the web client ID and secret.
    Add the iOS client ID to the authorized client IDs for native ID-token
    sign-in.
  - Allowed redirect URLs for now: only `http://localhost:7358/**` (the probe's
    stable development origin). The production web origin is chosen in S7.
- Android identifiers are skipped (best-effort platform) unless you ask.
- The secrets stay in the Google and Supabase dashboards. Public values (project
  URL, publishable key, PowerSync URL, client IDs) are recorded in
  `powersync/README.md`, with the private values kept in ignored local config.
- Verification in S3 is a manual browser sign-in through Supabase's hosted Google
  flow, confirming that a user appears. Native iOS sign-in, including nonce
  handling for `google_sign_in` 7, is built and verified in S4.

## Verification (agent, read-only apart from test-user data)

1. **API isolation** (`tool/cloud_checks/api_isolation.py`, standard-library
   Python). Signs in both test users with the publishable key. Checks:
   - anonymous reads and RPC calls are denied;
   - each user reads only their own rows;
   - direct table writes are denied for both;
   - the RPC creates records for A, and B gets `record_not_accessible` on them;
   - receipts and tombstones are unreadable, and private functions cannot be
     called.
2. **Stream isolation** (a live integration check in `tool/sync_probe`, reusing
   its pinned SDK so Fundly's dependencies stay unchanged):
   - A and B each connect, and each local database receives only that user's
     rows from all five tables;
   - a change committed through the RPC arrives;
   - an expired or invalid token cannot open a stream.
3. Results are recorded with commands and counts in `powersync/README.md`.
4. Records created by the checks belong to the test users only. Transactions are
   deleted afterwards; any remaining test accounts/categories stay disposable.
5. Local regression: `supabase test db` (666), all race runners, `dart format .`,
   `flutter analyze`, `flutter test`. No Fundly app or iOS build change.

## Files

| File | Change |
|---|---|
| `powersync/sync-config.yaml` | New: Fundly user-filtered streams |
| `powersync/publication.sql` | New: publication membership |
| `powersync/probe_cleanup.sql` | New: drops probe cloud objects after S3 checks pass |
| `powersync/README.md` | New: deployment steps, public configuration, verification record |
| `tool/cloud_checks/api_isolation.py` | New: hosted API isolation check |
| `tool/sync_probe/test/fundly_stream_test.dart` | New: live stream isolation check |
| `docs/CLOUD_SYNC_PLAN.md` | Next-task pointer |

## Not included

App sign-in, session handling and user-scoped databases (S4), repository sync
and the client recovery contract (S5), data import (S6), the production web
origin and release deployment (S7), and Android OAuth.

## Risks

- The free-tier Supabase project pauses after inactivity, and PowerSync free
  limits apply. Check both before relying on the checks.
- `db push` changes a shared hosted project. The dry run must list only the five
  files before the real push.
- Dropping the probe objects is irreversible. It happens last, after review.

## Approval requested

1. **Decision 1:** deploy the five S2 migrations to the hosted project
   (owner-run, after reviewing the dry run).
2. **Decision 2:** replace the probe's streams and publication entries with
   Fundly's, then drop the probe cloud objects after checks pass.
3. The Google OAuth setup as listed (web and iOS clients, localhost redirect
   only for now), and the verification plan.
