# Fundly — Google sign-in and cloud synchronization plan

Date: 2026-11-17

Status: **Defaults approved; connection feasibility accepted; S2 proposal ready.**
The owner requested development to proceed on 2026-11-18. Production
schema, data migration, dependency integration, and deployment still require
the relevant task review. Approve and implement one task at a time under
[AGENTS.md](../AGENTS.md) and [CLAUDE.md](../CLAUDE.md).

## Goal and known setup

Use the same personal Fundly dataset in the Flutter web app and installed
iOS/Android app, signed in with the same Google account. Preserve offline
editing and all existing accounting rules. iOS and web are the release gates;
Android remains best-effort.

- Supabase project created in Tokyo; currently on the free tier.
- PowerSync instance created. JP was recommended; confirm its actual region.
- Public client settings have been provided and saved in the ignored prototype
  configuration. The product owner created disposable probe tables and confirmed
  that the PowerSync connection is working. Google OAuth is not yet tested.
- Hosting domain and mobile OAuth identifiers still need confirmation.

## Current implementation

- Drift SQLite schema v12, with five tables: `custom_account_types`,
  `accounts`, `categories`, `transactions`, and `monthly_plans`.
- Every table uses an auto-increment integer ID. Foreign keys and domain
  models refer to these IDs; they are not globally unique across devices.
- `lib/core/database/app_database.dart` opens platform-local storage and seeds
  categories on creation. Web already uses `web/sqlite3.wasm` and
  `web/drift_worker.js`; browser and mobile databases are independent.
- Hand-written Riverpod providers and repositories expose local streams.
- JSON backup format 6 exports records with IDs; restore accepts formats 1–6
  and replaces all local data atomically.
- No Supabase, Google authentication, or PowerSync dependencies are installed.

## Proposed architecture

```text
Flutter mobile / Flutter web
  UI → Riverpod → repositories → local SQLite through Drift
                                  │
                         PowerSync durable upload queue
                                  │ authenticated writes
                                  ▼
                    Supabase API / transactional RPC
                                  │
                     PostgreSQL + ownership constraints
                                  │ replication
                                  ▼
                     PowerSync Cloud (JP)
                                  │ user-filtered downloads
                                  └────────→ local SQLite on each device

Supabase Auth + Google → user session for uploads and PowerSync credentials
```

Supabase is the authoritative shared dataset; local SQLite supplies reactive
reads and pending offline edits. Uploads go to Supabase through an application
connector; PowerSync streams accepted backend changes to clients. It does not
make the current SQLite file automatically syncable.

Retain financial calculations in existing domain code. Never synchronize
derived balances, Spending totals, Ready to assign, or carry-over snapshots.

## Decisions to approve before implementation

| Topic | Proposed default / required decision |
|---|---|
| Data scope | One private dataset per Supabase user; no household sharing. |
| Local mode | Preserve current signed-out local use. Keep it separate from each user's synchronized store. |
| IDs | Prefer UUIDs for shared identity. Prototype full UUID migration versus a durable local-integer/cloud-UUID mapping before selecting one. Never upload raw auto-increment IDs as global identities. |
| Local schema | Evaluate PowerSync-managed tables versus raw tables with Drift. Confirm constraint, trigger, migration, and foreign-key support before choosing; existing SQLite DDL cannot be assumed to work unchanged. |
| Cloud ownership | Every record belongs to `auth.uid()`. Scope uniqueness to the owner and reject references to another owner's records. |
| Write validation | Transactional PostgreSQL functions for operations spanning records or enforcing cross-table rules. Use authenticated user context and validate server-side. |
| Conflicts | Prefer server revisions and rejection of stale edits/deletes, with visible recovery. Do not silently overwrite conflicting financial edits. Prototype how rejected writes are reconciled locally. |
| Initial upload | Explicitly import one local dataset only into an empty cloud dataset. No automatic merging of populated datasets. |
| Sign-out | Never silently discard pending writes. Offer waiting/retry or explicit discard/export; disconnect sync and close the user's store before showing another user's data. |
| Restore | Preserve existing signed-out restore. For the first sync release, propose blocking restore into a signed-in dataset until cloud-wide replacement is designed and approved; show an explanation. |
| Backup | Preserve formats 1–6 as import inputs. Approve any new export version and ID conversion before changing persisted identity. |

The product owner approved these defaults. The ID representation and local
schema implementation still depend on S1 evidence. Production behavior is not
implemented yet; the relevant delivery task must update CLAUDE.md §11 when
that behavior is implemented and its scope includes documenting the decisions.

## Delivery tasks and approval gates

### S1 — Compatibility prototype and final design

- Use disposable data and an isolated prototype; do not replace the real
  `fundly` database or upload personal records.
- Check compatible `supabase_flutter`, PowerSync, Drift integration, and Google
  sign-in packages against the installed Flutter/Dart/Drift versions.
- Prove one parent/child write, offline creation, upload retry, deletion,
  and download on iOS and Chrome. Verify browser worker/WASM requirements,
  multi-tab behavior, migrations, and repository watch streams.
- Exercise a rejected write and a multi-record transaction; verify durable
  queue recovery without dropping an unaccepted operation.
- Produce the chosen ID mapping, local schema strategy, conflict protocol,
  dependency list, and backup implications for approval.

Likely locations: an isolated prototype, then a design update to this file.
Acceptance: both clients converge on disposable data; feasibility and
limitations are demonstrated before production schema work.

### S2 — Cloud schema and secure write API

- Add versioned migrations under proposed `supabase/migrations/`.
- Define the five cloud tables, shared IDs, ownership, revisions, timestamps,
  and deletion/conflict metadata selected in S1.
- Reproduce financial and integrity checks in PostgreSQL, including positive
  transaction amounts, allowed account roles, no self-transfer, immutable
  transaction type, PHP integer minor units, and valid category references.
- Enforce owner-scoped names, one budget account per owner, one monthly plan
  per owner/category/month, and one linked liability row per account.
- Make account/linked-plan changes, budget-account switching, archive/delete
  checks, and related writes atomic. Handle concurrent creates and retries.
- Enable RLS and test two users, unauthenticated access, forged ownership,
  cross-user foreign keys, RPC access, and direct Data API bypass attempts.

Acceptance: invalid or unauthorized writes fail even outside the app; no
partial multi-record operation survives. Approve schema/API before applying
it to the existing Supabase project.

### S3 — Connect PowerSync and configure authentication

- Configure replication credentials/publication using the official Supabase
  guide; keep privileged credentials in service configuration only.
- Check publication membership for all intended tables and connect the JP
  instance to Tokyo Supabase.
- Version user-filtered Sync Streams under proposed `powersync/`. Explicitly
  filter downloads by authenticated user; Supabase RLS alone does not define
  the PowerSync replication download scope.
- Configure Supabase JWT validation for PowerSync.
- Configure Google OAuth, Supabase callbacks, exact allowed web redirects,
  iOS callback scheme/client identifiers, and Android identifiers as needed.
- Record public endpoints and publishable client configuration separately
  from secrets. No database password, Google client secret, service-role key,
  or replication credential may ship in Flutter or source control.

Acceptance: two test users authenticate and receive only their own records;
expired/invalid sessions cannot open another user's sync stream.

### S4 — Authentication and isolated local stores

- Add approved dependencies and a feature under proposed `lib/features/auth/`.
- Implement sign-in, callback handling, session restoration, cancellation,
  token refresh, and sign-out with Riverpod lifecycle management.
- Introduce user-scoped database selection in `lib/core/database/` and close
  old subscriptions/stores when the authenticated identity changes.
- Keep the original local database intact. Never automatically associate
  its data with whichever Google account signs in first.

Acceptance: restart, expired sessions, offline reopening, sign-out, and
switching users preserve isolation and the approved pending-write behavior.
Likely additional files: `lib/app/`, `lib/main.dart`, `ios/Runner/`, web auth
configuration, repository providers, and `test/helpers/` overrides.

### S5 — Synchronize repositories and financial operations

- Implement the backend connector under proposed `lib/features/sync/`.
- Route local writes through the chosen PowerSync-compatible database;
  preserve repository interfaces where practical.
- Upload operation batches atomically with durable idempotency keys. A
  retry must not duplicate a transaction or partially repeat a workflow.
- Apply the approved revision/conflict and deletion policy. Do not resurrect
  deleted records from a stale client or permanently block unrelated queued
  writes behind one rejected operation.
- Ensure seeded categories and automatic liability rows are initialized once
  per dataset, rather than independently duplicated by every new client.
- Add user-facing loading, pending, synchronized, offline, and actionable
  failure states. Distinguish locally saved from accepted by the server.

Acceptance: all five tables converge across iOS and web after offline edits;
financial summaries match; concurrent edits and rejected writes are recoverable.
Likely files: all feature repositories/tables, database setup, providers,
domain ID types if selected, generated schemas, and matching tests/fakes.

### S6 — Existing-data migration and backup compatibility

- Export and validate a backup before migration; preserve the source DB.
- Preview the local/cloud state and require explicit selection of import
  into empty cloud or using existing cloud data. Do not merge automatically.
- Map every ID and reference consistently, including linked liability rows
  and monthly plans. Preserve archived/deleted-plan flags, dates, and money.
- Use a resumable, idempotent import with an initialization marker; expose
  the dataset to other clients only after the import is complete.
- Compare row counts, relationships, account balances, Spending summaries,
  and Plans values before switching to the synchronized store.
- Keep a rollback path to the untouched local dataset. Rollback must isolate
  local mode rather than silently overwrite an already changed cloud dataset.
- Update exporter/importer, backup version if needed, migration snapshots,
  and tests for every existing supported backup and database upgrade path.

Acceptance: interrupted/retried migration produces no duplicate or missing
records, all formats 1–6 remain restorable under the approved policy, and a
second device downloads the complete imported dataset.

### S7 — Deployment and release verification

- Deploy the versioned Supabase migrations/functions and PowerSync config
  against test data first; verify free-tier availability and usage limits.
- Select a stable HTTPS web origin, configure redirects and required browser
  asset headers, then deploy the Flutter web build. The web host serves the
  app; Supabase and PowerSync host the shared data and sync service.
- Install the iOS build and test a physical device plus desktop/mobile
  browsers; exercise Android if available.
- Verify older-client compatibility before deployment and document minimum
  supported app/schema versions, service outages, monitoring, and rollback.
- Define cloud backup/recovery separately: sync propagates deletions and is
  not a replacement for recoverable backups.
- Update README, ROADMAP, CLAUDE.md status and §11 only for approved and
  delivered behavior, preserving existing financial decisions.

Acceptance: the release matrix below passes and the product owner reviews
the implementation before release. No commit or push by the coding agent.

## Verification matrix

| Scenario | Required result |
|---|---|
| Same Google account on iOS and web | Same accepted records and financial results. |
| Two different users | No access through UI, direct API, RPC, or sync stream. |
| Offline create/edit/delete, restart, reconnect | Durable pending changes; no duplication; eventual convergence. |
| Two clients edit/delete the same record | Approved conflict policy with visible recovery; no silent resurrection. |
| Archive/delete versus concurrent spending | Server enforces existing rules atomically; rejected change is recoverable. |
| Retry after server commit but before client acknowledgement | Exactly one accepted operation. |
| Budget switch / liability row update | One valid budget account and consistent linked rows. |
| New client and seeded defaults | No duplicated categories, plans, or account links. |
| Sign-out / account switch with pending writes | No loss without explicit action and no cross-user upload. |
| Restore and first import interrupted | Approved behavior, consistent references, recoverable original dataset. |
| Browser refresh / multiple tabs / cleared storage | Safe reconnection; accepted cloud data downloads again; clearly describe loss of unsynced browser-only changes. |
| Auth expiry / service unavailable | Local data remains usable under the approved session policy; sync resumes safely. |

For every implementation task run `dart format .`, `flutter analyze`, and
the full `flutter test` suite. Build iOS for app-code changes; also build web
for integration changes. Add meaningful SQL security/transaction tests and
two-client integration tests, not only mocked SDK tests. Record exact commands,
test counts, failures, and device checks. Back up simulator data and verify
SQLite integrity/foreign keys after any local schema migration.

## Next task

S2 (S2.1–S2.3) is implemented and verified locally; see
[supabase/README.md](../supabase/README.md). S3 is complete (2026-11-20): the
hosted Supabase project and JP PowerSync instance replicate exactly the five
Fundly tables, Google OAuth is configured, both isolation checks pass on the
hosted services and the probe objects are removed; see
[powersync/README.md](../powersync/README.md). The next task is S4
(authentication and isolated local stores), which needs its own proposal and
approval before work starts. The owner accepted the connection checks and
requested development to proceed; unverified rejection/conflict cases remain
explicit development and release requirements. See
[S1 findings](CLOUD_SYNC_S1_FINDINGS.md) for evidence and gaps. Keep the probe
separate from production and do not migrate personal data yet.

## Technical references

Checked 2026-11-17; verify current SDK requirements again during S1.

- [Drift backend synchronization](https://drift.simonbinder.eu/examples/server_sync/)
  — available sync approaches and PowerSync integration.
- [PowerSync Supabase guide](https://docs.powersync.com/integrations/supabase/guide)
  — replication, authentication, upload connector, and Sync Streams setup.
- [PowerSync Flutter SDK](https://pub.dev/documentation/powersync/latest/)
  — client integration reference.
- [PowerSync Drift integration](https://powersync.com/blog/using-orms-with-powersync)
  — ORM integration; compatibility still needs the S1 prototype.
- [Supabase Google sign-in](https://supabase.com/docs/guides/auth/social-sign-in/auth-google)
  — provider and platform configuration.
- [Supabase row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security)
  — server-side ownership enforcement.
- [PowerSync pricing](https://powersync.com/pricing)
  — confirm limits and inactivity behavior before rollout.
