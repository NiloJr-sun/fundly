# Fundly 1.4.0 release checklist (shared spaces C3.4)

Status: **prepared 2026-11-24, not started.** Release of sharing
([plan](SHARED_SPACES_C3_PLAN.md)): server migration
`20261124040000_sharing.sql`, `main`'s sync config (members' email and display
name, with the F.2 condition), then app 1.4.0 (6) on the web and the iPhone.
Follows [OPERATIONS.md](OPERATIONS.md); the agent never commits, pushes or
runs a production write.

## Before starting

- **The web already runs C3.2** (since its push, still labelled 1.3.0 (5);
  [F.2](F2_WEB_SPACE_SEPARATION_PLAN.md#outcome)). Every push to `main` deploys
  the web, so `c3` is merged into `main` only at row 9.
- **The hosted sync config is the F.2 hotfix's** (no member names). `main`'s
  selects `space_members.email` and `display_name`, which exist only after
  the migration: row 2 before row 5, always.
- C3.3 review passed with two users on local sync (owner's sign-off).

## Who and what

| Who | Does |
|---|---|
| Owner | Backups, `db push --remote`, the PowerSync dashboard step, merging `c3` and pushing `main`, the device rows |
| Agent | Local checks, dry runs and read-only checks, hosted isolation and stream checks, the iOS build and install, recording results |

Accounts: **A** (real data) and **B** (test account). Spaces made for
checking are owned by **B**, which invites A; B deletes them at the end
(deleting arrives with this release).

Devices: the iPhone (A, 1.3.0 until Part C), Chrome (A, then B in a second
browser profile), the iPhone 16 Plus simulator (B, release build).

## Part A: server and sync, while devices still run 1.3.0

| # | Step | Pass when |
|---|---|---|
| 0 | Agent, local: `supabase test db`, `db lint`, the C3 rollback test, the concurrency test, and the legacy, C2 and C3 stream probes on local sync with `main`'s config | All pass |
| 1 | **Backups.** Export from the iPhone (Profile → Export backup) and copy it to the Mac; owner dumps schema and data into `~/fundly-backups/2026-11-2x-c3/` (mode 700) | Files exist; agent confirms the dump is current (read-only aggregates) |
| 2 | Agent: `db push --remote --dry-run`. Owner: `db push --remote` | The dry run lists exactly `20261124040000_sharing.sql`; afterwards "Remote database is up to date" |
| 3 | Agent: `db lint --remote` (public, fundly_private, fundly_access) and `db advisors --remote` | No lint errors; advisors: the known ones plus the new sharing RPCs as intended SECURITY DEFINER functions for `authenticated` (list them in Results) |
| 4 | Agent, read-only: every existing member has `email` (and `display_name` where the sign-in had one) backfilled; `space_invites` has RLS on and no client grants | Both true |
| 5 | Owner: PowerSync dashboard → Sync Streams → paste **`main`'s** `powersync/sync-config.yaml` → **Validate** → **Deploy** | Validates and deploys |
| 6 | Agent: `api_isolation.py`, `fundly_stream_test.dart`, `c2_space_streams_test.dart` and **`c3_sharing_streams_test.dart`** against the hosted services | All pass: the first hosted proof of invites, roles and removal |
| 7 | iPhone (1.3.0) and Chrome (A): Profile "Up to date"; data and balances unchanged; add and delete one transaction on the iPhone, seen in Chrome | Pass: 1.3.0 keeps syncing with the new config |

## Part B: 1.4.0 on the web and the simulator

| # | Step | Pass when |
|---|---|---|
| 8 | Agent, local: full app tests, `flutter analyze`, `flutter build web --release` on the merged `main` | All pass |
| 9 | Owner merges `c3` into `main` and pushes; agent checks `version.json`, the cache headers and that `/join` serves the app | Vercel serves 1.4.0 (6); `/join` returns the app, not 404 |
| 10 | Chrome (A): reload | "Version 1.4.0 (6)"; same data and balances; "Up to date"; the space sheet has ⋮ menus and Join a space |
| 11 | Agent installs the 1.4.0 release build on the simulator; owner signs in as **B** there and in a second Chrome profile | Both show B's spaces |
| 12 | Simulator (B): create "Sharing check", ⋮ → Invite A's email as **Editor**, share the link | Link dialog shows once; Members lists the pending invite |
| 13 | Chrome (A): open the link | The address bar loses the secret; preview names B and the role; Accept switches to "Sharing check · Editor" |
| 14 | Both edit: A adds a transaction, B edits it | Each sees the other's change; Members shows both names and emails |
| 15 | Simulator (B): make A a **Viewer** | A's title reads "· Viewer"; A's add and edit show "View only"; Export still works |
| 16 | Removal with an unsent change: make A Editor again; A goes offline (DevTools → Network → Offline) and adds a transaction; B removes A; A goes online | A sees "Sharing check" as Removed with the banner and the refused change; Remove from this device works |
| 17 | B invites A again; A accepts; A ⋮ → Leave space | A is back in Personal with no Sharing check; B's Members no longer lists A |
| 18 | Simulator (B): ⋮ → Delete space, typing the name | Gone on both devices. Also delete the leftover test spaces ("Release check", "C2 check") owned by the test users |

## Part C: the iPhone (A) to 1.4.0

| # | Step | Pass when |
|---|---|---|
| 19 | Export a backup on the iPhone; agent copies the app's data off the phone (`devicectl`) and keeps the build in `~/fundly-releases/1.4.0-6/` | Copy readable (integrity ok) |
| 20 | Agent installs 1.4.0 over 1.3.0 (never delete the app) | `devicectl` reports 1.4.0 (6); data files present |
| 21 | iPhone: open Fundly | "Version 1.4.0 (6)", the same accounts, transactions and balances, "Up to date"; Members of a space shows names; Join a space accepts a pasted link from B |

## Sign-off

All rows pass → C3 complete; docs updated (CLAUDE.md, roadmap, runbook,
`powersync/README.md` log); minimum supported version stays 1.2.0.

## If something fails

- Before row 9: nothing user-visible changed except member names syncing.
  Fix forward, or run `supabase/rollback/20261124_c3_rollback.sql` (after the
  backups) and redeploy the F.2 hotfix's `sync-config.yaml`
  (`git show hotfix/1.3.1:powersync/sync-config.yaml`).
- After row 9: roll the web back in Vercel (Instant Rollback) to the last
  1.3.0 deployment; invites already accepted keep their memberships.
- iPhone: reinstall 1.3.0 from `~/fundly-releases/1.3.0-5/`.

## Results

(Filled in as rows pass.)
