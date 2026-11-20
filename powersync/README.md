# Fundly hosted sync setup — S3

Steps, files and the verification record for connecting the hosted Supabase
project to PowerSync ([proposal](../docs/CLOUD_SYNC_S3_PLAN.md), approved
2026-11-18). The Fundly app is unchanged: sign-in in the app is S4, and syncing
repositories is S5.

Steps marked **Owner** need a secret or a dashboard and are run by the product
owner. Never paste a database password, service-role key, Google client secret
or replication password into this repository, a config file or a chat.

## Files

| File | Purpose |
|---|---|
| `sync-config.yaml` | Fundly Sync Streams: five tables, each filtered by `auth.user_id()`, explicit columns, `owner_id` not downloaded |
| `publication.sql` | Puts exactly the five Fundly tables in the `powersync` publication and removes the probe tables (idempotent) |
| `probe_cleanup.sql` | Drops the S1 probe's cloud objects; refuses while they are still published |
| `../tool/cloud_checks/api_isolation.py` | Hosted API isolation check (standard-library Python) |
| `../tool/sync_probe/test/fundly_stream_test.dart` | Live stream isolation check (reuses the probe's pinned SDKs) |

## Public configuration (owner fills in; no secrets)

| Setting | Value |
|---|---|
| Supabase project ref / region | `jiiuukimazvcxautvmya` / Tokyo |
| PowerSync instance / region | _to record_ / JP |
| PowerSync publication name | `powersync` (confirm in the PowerSync dashboard) |
| Google OAuth web client ID | `655206339590-4l4kulvsr3ptsmftiiu9eqlna6pbl1en.apps.googleusercontent.com` |
| Google OAuth iOS client ID | `655206339590-gv8k3be2tshp60ucmn5s1qa0c7e86b8l.apps.googleusercontent.com` (bundle ID `com.nilojr.fundly`) |
| Supabase allowed redirect URLs | `http://localhost:7358/**` only, until S7 picks the web origin |

The project URL, publishable key and PowerSync URL used by the checks stay in
the ignored `tool/sync_probe/config.local.json`.

## Steps

### 1. Deploy the S2 migrations (Owner)

From the repository root:

```sh
npx --yes supabase@3.2.0 link --project-ref <ref>     # prompts for the DB password
npx --yes supabase@3.2.0 db push --remote --dry-run
```

CLI v3 targets the local stack unless `--remote` is given; a dry run that says
"Target: local stack" did not check the hosted project.

Stop unless the dry run lists exactly these five files, in order:
`20261118010000_fundly_schema.sql`, `20261118020000_transaction_write_api.sql`,
`20261118030000_account_write_api.sql`, `20261118040000_category_plan_write_api.sql`
and `20261118050000_sync_protocol.sql`. Then:

```sh
npx --yes supabase@3.2.0 db push --remote
npx --yes supabase@3.2.0 db lint --remote --schema public,fundly_private --fail-on warning
```

Record the lint result below. Also open Supabase → Advisors (security and
performance) and record any finding. If the push fails, stop and share the
error. The tables are empty, so a reviewed drop script is the rollback.

### 2. Replication (Owner)

Run `publication.sql` in the Supabase SQL editor. Its last query must list
exactly `accounts`, `categories`, `custom_account_types`, `monthly_plans` and
`transactions`. If it stops with "FOR ALL TABLES", or PowerSync uses a
different publication name, stop and share the message. Then refresh the
Supabase connection in the PowerSync dashboard.

### 3. Sync Streams (Owner)

Paste `sync-config.yaml` into the PowerSync dashboard, **Validate**, then
**Deploy**. This replaces the probe's stream, so the live probe stops syncing.
Keep the existing Supabase client authentication setting; confirm it is still
enabled and valid.

### 4. Google OAuth (Owner)

1. Google Cloud console → APIs & Services → Credentials:
   - OAuth client **Web application**, authorized redirect URI
     `https://<ref>.supabase.co/auth/v1/callback`.
   - OAuth client **iOS**, bundle ID `com.nilojr.fundly`.
   - Configure the consent screen in testing mode, with your Google account as
     a test user.
2. Supabase → Authentication → Providers → Google: enable it, enter the web
   client ID and secret, and add the iOS client ID to the authorized client IDs.
3. Supabase → Authentication → URL Configuration: add `http://localhost:7358/**`
   to the redirect URLs.
4. Manual check: open
   `https://<ref>.supabase.co/auth/v1/authorize?provider=google&redirect_to=http://localhost:7358`
   in a browser and sign in. Confirm a user appears under Authentication → Users.
   The browser then lands on an unused localhost page; that is expected.
5. Record both client IDs above (they are public).

Native iOS sign-in, including `google_sign_in` 7 nonce handling, is built and
verified in S4.

### 5. Verification (Agent, with the owner's test credentials)

The owner exports the two disposable test users' credentials in the agent's
shell. They are read from the environment and never printed:

```sh
export FUNDLY_TEST_A_EMAIL=... FUNDLY_TEST_A_PASSWORD=...
export FUNDLY_TEST_B_EMAIL=... FUNDLY_TEST_B_PASSWORD=...
python3 tool/cloud_checks/api_isolation.py
(cd tool/sync_probe && flutter test test/fundly_stream_test.dart)
```

Each check creates records for the test users and deletes them at the end.
Their tombstones remain, by design.

### 6. Probe cleanup (Owner, last, irreversible)

After steps 1–5 pass, run `probe_cleanup.sql` in the SQL editor. Its final query
must return no rows. The probe package stays in the repository as evidence; its
offline tests still run.

## What the checks cover

**API isolation:**
- anonymous reads and RPC calls are denied, and a tampered token is rejected;
- A writes one record to each table through the RPC, and B writes a category
  with the same name (names are per user);
- each user reads only their own rows in all five tables;
- B cannot edit A's record or learn its revision;
- direct insert, update and delete are denied;
- receipts and tombstones are unreadable, and private functions are not exposed;
- the check's records are removed.

**Stream isolation:**
- A and B each sync a throwaway local database, and for all five tables the
  downloaded IDs equal what that user can read through the API, with nothing
  shared;
- B's category never reaches A;
- integer money and `YYYY-MM-DD` dates download as expected;
- a change committed through the RPC downloads to A only;
- a token with a broken signature never syncs any row.

Not automated: an *expired* (but validly signed) token. The default JWT lifetime
is one hour, and session refresh belongs to S4.

## Verification record

| Date | Check | Result |
|---|---|---|
| 2026-11-18 | `publication.sql` and `probe_cleanup.sql` rehearsed on the local database, with stand-in probe tables in a `powersync` publication | Cleanup refused while probe tables were published; publication ran twice and listed exactly the five tables; cleanup then dropped the probe tables and function; a `FOR ALL TABLES` publication was refused |
| 2026-11-18 | `api_isolation.py` against the full local Supabase stack (local API, Auth and two local users; `FUNDLY_CHECK_CONFIG`) | All 15 checks passed |
| 2026-11-18 | `fundly_stream_test.dart` against the local stack with no PowerSync service | Sign-in, RPC setup and cleanup worked; failed as expected at the first-sync wait. No rows left behind |
| 2026-11-18 | Step 1: `db push --remote --dry-run`, then owner-run `db push --remote` (project ref `jiiuukimazvcxautvmya`, Tokyo) | Dry run listed exactly the five Fundly migrations, with no seeds or roles; after the push, a second dry run reported "Remote database is up to date" |
| 2026-11-18 | Step 1: `db lint --remote --schema public,fundly_private --fail-on warning` | No schema errors found |
| 2026-11-18 | Step 1: `db advisors --remote` | Three warnings: (1) `fundly_apply_operations` is a SECURITY DEFINER function executable by `authenticated`: intended, it is the only write path and checks ownership on every read and write; (2) the same for `probe_apply_batch`: removed by step 6; (3) leaked password protection is disabled: an Auth setting for the owner to review. No performance findings |
| 2026-11-18 | Step 2: read-only check of `pg_publication_tables` after the owner reported running `publication.sql` | Not applied: `powersync` still listed only `probe_entries, probe_parents` |
| 2026-11-18 | Step 2: agent ran `publication.sql` with `db query --remote --file` at the owner's request, then a separate read-only check | `powersync` lists exactly `accounts, categories, custom_account_types, monthly_plans, transactions`; probe tables removed; not FOR ALL TABLES |
| 2026-11-19 | Steps 2–3 (owner): PowerSync Database Connection shows the Supabase project as Complete (no table reconfiguration); `sync-config.yaml` validated and deployed | Owner reported done |
| 2026-11-20 | Step 5: `api_isolation.py` against the hosted project (`jiiuukimazvcxautvmya.supabase.co`), two disposable email/password users | All 15 checks passed; check records removed |
| 2026-11-20 | Step 5: `fundly_stream_test.dart` against the hosted JP PowerSync instance | Passed (1 test, ~15 s). Both users synced only their own rows in all five tables; the RPC change reached A only; the forged token was refused with `401 PSYNC_S2101 signature verification failed` and synced nothing |
| 2026-11-20 | Step 4 (owner): Google OAuth Web application and iOS clients created; Google provider configured in Supabase; client IDs recorded above | Owner reported done |
| 2026-11-20 | Step 4 (owner): manual browser sign-in via `/auth/v1/authorize?provider=google&redirect_to=http://localhost:7358` | Signed in with Google; the user appears under Supabase → Authentication → Users |
| 2026-11-20 | Pre-cleanup read-only check of `pg_publication_tables` | Drift found: `powersync` listed 10 tables (the five Fundly tables plus `probe_entries`, `probe_parents`, `probe_receipts`, `fundly_write_receipts`, `fundly_deleted_records`); not FOR ALL TABLES. Likely cause: the PowerSync dashboard's guided table setup. Do not use **Reconfigure Tables**; manage the publication only through `publication.sql` |
| 2026-11-20 | Agent reran `publication.sql` with `db query --remote --file` at the owner's request, then a separate read-only check | `powersync` lists exactly `accounts, categories, custom_account_types, monthly_plans, transactions` |
| 2026-11-20 | Reran `api_isolation.py` and `fundly_stream_test.dart` on the hosted services after the reset | All 15 API checks passed; stream test passed (forged token refused with `401 PSYNC_S2101`) |
| 2026-11-20 | Step 6: agent ran `probe_cleanup.sql` with `db query --remote --file` at the owner's request, then a separate read-only check | Final query returned no rows; no `probe_*` tables or functions remain; `powersync` still lists exactly the five Fundly tables |
| 2026-11-20 | Final rerun of `api_isolation.py` and `fundly_stream_test.dart` after cleanup | All 15 API checks passed; stream test passed. **S3 complete** |
