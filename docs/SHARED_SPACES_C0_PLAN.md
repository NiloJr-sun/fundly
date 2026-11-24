# Shared spaces C0: sync prototype (plan)

Date: 2026-11-24

Status: **approved 2026-11-24** (Decisions C0-1 to C0-4, all as
recommended). The PowerSync free plan allows only one instance (Fundly's
production one), so C0-1 fell back to the **local** option, approved the same
day (see C0-1). **Complete 2026-11-24: go** (owner decision); findings in
[SHARED_SPACES_C0_FINDINGS.md](SHARED_SPACES_C0_FINDINGS.md). The local C0
environment was removed with `down.sh --wipe` (Decision C0-3); the files
stay as the record and `up.sh` can recreate it. Slice C0 of
[SHARED_SPACES_PROPOSAL.md](SHARED_SPACES_PROPOSAL.md) (approved 2026-11-22).
C0 is a throwaway prototype in the style of S1
([CLOUD_SYNC_S1_FINDINGS.md](CLOUD_SYNC_S1_FINDINGS.md)). It produces go/no-go
evidence and changes no Fundly app code, no app schema, no backup format, no
production server object and no root dependency. The agent stops after each
sub-slice and never commits or pushes.

## Goal

Before C1 rewrites every table and write function around spaces, prove that
the sync design in the proposal works on the hosted services and on iOS and
Chrome:

1. A user's devices download **only** the spaces they are a member of, and a
   non-member who asks for another space's records gets nothing.
2. Each space can live in its **own device store**, and the app can switch
   between two space stores cleanly (Decision 5).
3. When a membership ends, that space's records are **removed from the
   device** at the next checkpoint, also when the device was offline at the
   time (Decision 8).
4. A removed member's **unsent changes** are refused by the server and stay
   identifiable on the device, so C3 can list them in Refused changes.
5. A viewer's writes are refused; an editor's are accepted.

## Starting point

- Production sync is one auto-subscribed stream, `fundly_user_data`, that
  filters every table by `owner_id = auth.user_id()`
  ([powersync/sync-config.yaml](../powersync/sync-config.yaml), edition 3).
- The app keeps one PowerSync store per signed-in user
  (`fundly_sync_<user id>`, [database_name.dart](../lib/core/database/database_name.dart))
  and already switches stores when the user changes, on iOS and web.
- PowerSync 2.6.2, drift 2.35.4, sqlite_async 0.14.8 in the app and in
  [tool/sync_probe](../tool/sync_probe/README.md), which S1 and S3 used and
  which already has live, credential-gated tests (`fundly_stream_test.dart`).
- The hosted checks read their endpoints from `FUNDLY_CHECK_CONFIG`, so they
  can point at a different project without code changes.
- Production holds real data (account A) and is released as 1.2.0. The
  runbook requires the publication to list exactly the five Fundly tables
  ([OPERATIONS.md](OPERATIONS.md)).

## What does not change

- The Fundly app (`lib/`), its schema (v13), backup format 7, `pubspec.yaml`
  and lockfile.
- The production Supabase project, its publication and migrations, and the
  production PowerSync instance and its sync config (C0 runs locally).
- Financial rules. C0 records are minimal stand-ins, not Fundly accounts or
  transactions.

## Proposed design

### Where it runs (Decision C0-1, local fallback)

All **on the Mac**, in [tool/sync_probe/cloud/c0](../tool/sync_probe/cloud/c0/README.md):
a separate local Supabase stack (`fundly-c0`, ports 563xx, beside Fundly's own
local stack), the PowerSync open edition service
(`journeyapps/powersync-service:1.29.1`, telemetry off) and its Postgres bucket
storage in Docker. `up.sh` starts it and creates the test users; `down.sh
--wipe` removes it. Production is never touched.

Limit: this proves the design on the self-hosted service, which runs the same
sync engine as PowerSync Cloud. The hosted behaviour is confirmed when C1 is
deployed (a release-checklist row, after the usual backups).

### Server objects (`tool/sync_probe/cloud/c0/supabase/migrations/`)

| Object | Purpose |
|---|---|
| `c0_spaces` (`id`, `name`, `created_by`, timestamps) | A space |
| `c0_space_members` (`space_id`, `user_id`, `role` owner/editor/viewer) | Membership; primary key (`space_id`, `user_id`) |
| `c0_entries` (`id`, `space_id`, `label`, `amount_minor`, `created_by`, `updated_by`, timestamps, `revision`) | Stand-in for Fundly records |
| `c0_receipts` (backend only) | Idempotent batch receipts, as today |
| `c0_apply_batch(batch_id, space_id, items)` SECURITY DEFINER | Writes entries after checking the caller is an owner or editor of that space; per-space advisory lock |
| `c0_create_space(name)`, `c0_set_member(space_id, user_id, role)`, `c0_remove_member(space_id, user_id)` | Owner-only membership changes used by the checks (no invites; that is C3) |

RLS: members read their spaces, memberships and entries; no direct writes.
Only `c0_spaces`, `c0_space_members` and `c0_entries` are published to
PowerSync.

### Streams (`tool/sync_probe/cloud/c0/powersync/sync-config.yaml`)

```yaml
config:
  edition: 3
streams:
  c0_my_spaces:            # every store: the user's spaces and memberships
    auto_subscribe: true
    queries:
      - SELECT * FROM c0_spaces WHERE id IN
          (SELECT space_id FROM c0_space_members WHERE user_id = auth.user_id())
      - SELECT * FROM c0_space_members WHERE space_id IN
          (SELECT space_id FROM c0_space_members WHERE user_id = auth.user_id())
  c0_space_entries:        # one space's records, subscribed per store
    query: SELECT * FROM c0_entries
      WHERE space_id = subscription.parameter('space_id')
        AND space_id IN
          (SELECT space_id FROM c0_space_members WHERE user_id = auth.user_id())
```

The service validates the syntax when it loads the config; if subqueries or
parameters behave differently from the docs, that is a finding, and the
fallback (a parameter-only stream checked by a membership join) is tried and
recorded.

### Device side (in tool/sync_probe)

- One managed-view PowerSync store per (user, space), named like the app
  would: `c0_<user id>_<space id>`. Each subscribes `c0_space_entries` with
  its own `space_id`. Switching closes or disconnects one store and opens
  the other, as the app does for users today.
- Managed views are enough here: what C0 tests is scoping, removal and
  switching, which do not depend on the raw-table setup S1 already proved.

## Sub-slices

### C0.1: Local environment (agent) ✅ Done 2026-11-24

The C0 Supabase stack with the schema and replication migrations, PowerSync
and its storage in Docker, `up.sh`/`down.sh`, git-ignored generated config and
test users (A owner, B member, C outsider), and
`tool/cloud_checks/c0_connection_check.py`.

Result: the service accepted the per-space sync config (subquery and
`subscription.parameter`); the connection check passed 7 of 7 (users sign in,
PowerSync accepts a session and rejects a tampered token, outsiders cannot see
a space). The schema had already passed a 21-assertion rehearsal. Details in
the [C0 README](../tool/sync_probe/cloud/c0/README.md) verification log.

### C0.2: Server and stream checks (agent, automated, VM) ✅ Done 2026-11-24

`tool/cloud_checks/c0_space_isolation.py` (API, publishable key only) and
`tool/sync_probe/test/c0_space_stream_test.dart` (live PowerSync, skipped
without credentials). Each run creates its own spaces and removes them.

| # | Check |
|---|---|
| 1 | A creates spaces S1 and S2; A's S1 store downloads only S1's entries, S2's only S2's |
| 2 | C subscribes to S1's `space_id`: zero entries, also after A adds more |
| 3 | C reads `c0_entries` and calls `c0_apply_batch` for S1 through the API: nothing returned, write refused |
| 4 | A adds B as editor: B's new S1 store downloads S1; B's write is accepted and reaches A |
| 5 | A makes B viewer: B's write is refused; B still downloads S1 |
| 6 | A removes B while B is connected: B's S1 rows disappear at the next checkpoint; `c0_my_spaces` no longer lists S1 |
| 7 | B offline, then removed, then reconnects: rows removed on reconnect |
| 8 | B queues a write offline, is removed, reconnects: the upload is refused; the queued item is still readable on the device (so C3 can log it) and the local rows are removed |
| 9 | Same write batch sent twice: applied once (receipt) |
| 10 | Two members writing to one space at once: both applied in order, revisions consistent |

**Result: all 10 checks pass**, against the local environment:
`c0_space_stream_test.dart` 6 of 6 tests (checks 1-2, 4-8, plus 8b below),
three runs in a row; `c0_space_isolation.py` 7 of 7 (checks 3, 9, 10), two
runs. No spaces left behind. Fundly's own suite unchanged (format and analyze
clean, 1156 tests pass). Every change below reached the device within one
250 ms poll of the test, locally:

| Event | Seen on the device |
|---|---|
| New entry, editor write, role change | ~0.25 s |
| Member removed while connected | entries ~0.25 s, space and members right after |
| Member removed while offline | on reconnect, ~0.25 s |
| Queued write of a removed member | refused and logged ~0.25 s; space removed right after |
| Viewer's refused local write | reverted right after the refusal is logged |

Findings for C0.4 and C1-C3:

1. **The design works as proposed.** A subscription parameter combined with a
   membership subquery scopes each store to one space; an outsider who
   subscribes with another space's ID gets nothing; membership and role
   changes re-evaluate the streams; removal clears the space from the device,
   also after being offline.
2. **A new member's first sync can finish empty.** Once (test 6, second run)
   the store's first sync completed before the just-granted membership had
   reached PowerSync, and the data arrived a moment later. The app should
   treat a space as ready only when it appears in the member's own spaces
   stream, not when the first sync finishes. The tests now wait for that.
3. **Refused uploads must be logged and completed, not retried** (check 8b).
   If a removed member's queued write is retried, PowerSync keeps the queue
   and will not apply checkpoints ("Could not apply checkpoint due to local
   data"), so the removed space **stays on the device**. Logging the refusal
   and completing the transaction, as Fundly's uploader already does with
   Refused changes, lets removal take effect and keeps the change for the
   member (Decision 8).
4. **Refused local writes revert by themselves** once the queue is empty, as
   in Fundly today.
5. **Stream subscriptions must be unsubscribed** when a store closes; the SDK
   warns about leaked subscriptions otherwise.

### C0.3: Switching on iOS and Chrome (agent, with owner observing) ✅ Done 2026-11-24

Integration test in the probe, run on the iPhone 16 Plus simulator and in
Chrome (`flutter test --platform chrome` with the probe's asset prefix):

- Open A's S1 store, sync, close; open S2 store, sync; switch back without a
  new full download; both stores hold only their own entries.
- Two stores on one device for two users (A and B) do not see each other.
- Chrome: stores persist across a reload; two tabs on different spaces
  (recorded as a finding; the app may restrict it to one active space).

The owner watches one manual round on the simulator and Chrome with the
probe UI, as in S1.

**Result: passed on every platform.** `test/c0_switching_test.dart` (2 tests,
also run on the simulator through `integration_test/c0_switching_test.dart`)
passed on the VM, the iPhone 16 Plus simulator and Chrome:

- Switching S1 → S2 → S1 keeps each store's data on the device: on switching
  back, S1's entries are there before connecting, a change made while switched
  away arrives (~0.25 s), and S2 stays intact.
- Four stores open at once (A's S1 and S2, B's S2 and S1) stay apart: B's
  store of S1, where B is not a member, stays empty; B's write in S2 reaches
  A's S2 store only.

Manual round, observed by the owner with the probe screen (`lib/c0_main.dart`,
two seeded spaces): every step passed. On the simulator, switching back to a
space showed its entries "already on this device"; in Chrome, B saw only the
shared space, edits crossed between the simulator and Chrome, and after a
reload the space's entries were still on the device. **Two tabs on different
spaces (C0-4) stayed separate**, each showing and editing only its own space.

Findings:

6. **One browser, one signed-in user.** Supabase web auth shares the session
   between every client of the same server in a page and across tabs (a
   broadcast channel), so signing in as another user replaces the session
   everywhere. That suits the app (one user per browser); the two-user test
   uses B's client under `localhost` to keep them apart.
7. **Per-space stores work in Chrome too**: several PowerSync databases in one
   tab, a reload keeping each, and two tabs on different spaces, with the
   shared sync worker. C2 can allow different spaces in different tabs
   (Decision C0-4).

### C0.4: Findings and go/no-go (agent; owner reviews) ✅ Written 2026-11-24

`docs/SHARED_SPACES_C0_FINDINGS.md`: what passed, failed or behaved
unexpectedly, timings (download after membership change, removal delay),
the stream syntax that works, and a recommendation for C1 (go, go with
changes, or no-go with alternatives). Then `down.sh --wipe` removes the local
environment (Decision C0-3).

## Verification

- `flutter analyze` and `flutter test` in `tool/sync_probe` (offline tests
  pass; live tests skip without credentials).
- Root `dart format`, `flutter analyze`, `flutter test` unchanged and passing,
  showing the app was not touched.
- `git status` shows no change under `lib/`, `supabase/`, `powersync/` or the
  root `pubspec.*`.
- Results recorded as observed, with commands; no check claimed without a run.

## Decisions for the product owner

- **C0-1. Where the prototype runs.** *Outcome:* the PowerSync free plan
  allows one instance, so the owner approved the local option on 2026-11-24.
  - *(Recommended)* A new disposable Supabase project and PowerSync
    instance. No risk to production; costs two dashboard setups.
  - Production project with `c0_` tables and streams added beside
    `fundly_user_data`. No new project, but a production publication change
    and sync-config deploy, against the runbook's rule.
  - Local only (Supabase CLI stack plus a self-hosted PowerSync container).
    Fully automatable, but does not prove the hosted PowerSync behaviour that
    C1 depends on.
- **C0-2. Test users.** *(Recommended)* Three email/password users in the
  C0 environment (owner, member, outsider). Alternative: two users, with
  B as both member and, after removal, outsider (weaker check 2).
- **C0-3. After C0.** *(Recommended)* Remove the C0 environment once the
  findings are accepted; C1 is rehearsed on the local Supabase stack as S2–S6
  were. Alternative: keep it running as a C1 rehearsal environment.
- **C0-4. Two tabs on different spaces in Chrome.** *(Recommended)* Only
  observe and record it in C0; decide the app rule in C2.

## Risks

- **PowerSync stream features.** Subqueries on `auth.user_id()` combined with
  subscription parameters may not re-evaluate promptly on membership change,
  or may differ on web. That is exactly what C0 is for; a no-go means
  redesigning before C1 (for example one stream per user listing all their
  spaces' records, filtered in the store).
- **Removal of queued writes.** If PowerSync discards a removed member's
  queued items or blocks the queue, Decision 8 needs another mechanism
  (for example copying the queue to Refused changes before a checkpoint
  removes access). Check 8 finds out.
- **Self-hosted versus hosted.** Resolved for C0 by running locally (the
  free plan allows one instance). Any hosted-only difference would show when
  C1 is deployed, which its release checklist covers.
- **Secrets.** Test passwords are random, local only and live in the
  git-ignored `.env.local`; nothing for production is written down.
