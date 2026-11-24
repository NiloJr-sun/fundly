# Fundly 1.3.0 release checklist (shared spaces C2.4)

Status: **proposed, awaiting the owner's approval.** Nothing in production has
changed yet. Release of private spaces ([plan](SHARED_SPACES_C2_PLAN.md)):
server migration `20261124030000_private_spaces.sql`, publication with seven
tables, the two opt-in streams, then app 1.3.0 (5) on the web and the iPhone.
Follows [OPERATIONS.md](OPERATIONS.md); the agent never commits, pushes or
runs a production write.

## Who and what

| Who | Does |
|---|---|
| Owner | Backups, `db push --remote`, the SQL editor and PowerSync dashboard steps, pushing `main`, the device rows |
| Agent | Dry runs and read-only checks, hosted isolation and stream checks, the iOS build and install, recording results |

Accounts: **A** (real data) and **B** (test account). A space cannot be
deleted before C3, so spaces made for checking are made in **B**; in A,
create a space only if you mean to keep it (it can be renamed).

Devices: the iPhone (A, still 1.2.1 until Part C), Chrome (A, then B in a
second browser profile), the iPhone 16 Plus simulator (B, release build).

## Part A: server and sync, while every device still runs 1.2.1

| # | Step | Pass when |
|---|---|---|
| 0 | **Backups.** Export from the iPhone (Profile → Export backup), copy it to the Mac; owner dumps schema and data into `~/fundly-backups/2026-11-24-c2/` (mode 700) | Files exist; agent confirms the dump is current (read-only aggregates) |
| 1 | Agent: `db push --remote --dry-run` | Lists exactly `20261124030000_private_spaces.sql` |
| 2 | Owner: `db push --remote`. Agent: dry run again, `db lint --remote` (public, fundly_private, fundly_access), `db advisors --remote` | Up to date; no lint errors; advisors show the 3 known warnings plus 2 intended ones for the new `fundly_create_space` and `fundly_rename_space` (SECURITY DEFINER for `authenticated`, like the write API) |
| 3 | Agent, read-only: every existing record still has `owner_id` (all are Personal); the PowerSync replication role can read `spaces` and `space_members` | Both true |
| 4 | Owner: run `powersync/publication.sql` in the SQL editor | Its last result lists exactly the seven tables; agent confirms read-only |
| 5 | Owner: PowerSync dashboard → Sync Streams → paste `powersync/sync-config.yaml` → **Validate** → **Deploy** | Validates and deploys (first hosted check of the per-space syntax). If Validate refuses, stop and send the message |
| 6 | Agent: `api_isolation.py`, `fundly_stream_test.dart` (old stream: Personal only) and **`c2_space_streams_test.dart`** against the hosted services | All pass: the first hosted proof of per-space streams, including a non-member getting nothing |
| 7 | iPhone and Chrome on **1.2.1** (A): Profile "Up to date"; data and balances unchanged; add and delete one transaction on the iPhone, seen in Chrome | Pass: old apps unaffected by the server and sync change |

## Part B: 1.3.0 on the web and the simulator

| # | Step | Pass when |
|---|---|---|
| 8 | Owner pushes `main`; agent checks `version.json` and the cache headers | Vercel serves 1.3.0 (5) |
| 9 | Chrome (A): reload | Profile shows "Version 1.3.0 (5)" and "Personal · Owner"; same data and balances (Personal re-downloads once); "Up to date". The iPhone (still 1.2.1) keeps syncing with it: a transaction added on the iPhone appears in Chrome |
| 10 | Agent installs the 1.3.0 release build on the simulator; owner signs in as **B** there and in a second Chrome profile | Both show B's Personal |
| 11 | Chrome (B): Create space "Release check" | Switches to it; default categories appear; the simulator's sheet lists it |
| 12 | Simulator (B): switch to "Release check", add a transaction; then switch to Personal | Chrome shows it only in "Release check", never in Personal; Spending and Plans name the space |
| 13 | Simulator (B): rename "Release check" | Chrome's list updates |

## Part C: the iPhone (A) to 1.3.0

| # | Step | Pass when |
|---|---|---|
| 14 | Export a backup on the iPhone; agent copies the app's data off the phone (`devicectl`) and keeps the build in `~/fundly-releases/1.3.0-5/` | Copy readable (integrity ok) |
| 15 | Agent installs 1.3.0 over 1.2.1 (never delete the app) | `devicectl` reports 1.3.0 (5); data files present |
| 16 | iPhone: open Fundly | "Version 1.3.0 (5)", "Personal · Owner", the same 7 accounts and 17 transactions and balances, "Up to date"; create, edit and delete a transaction, seen in Chrome (A) |

## Sign-off

All rows pass → C2 complete; docs updated (CLAUDE.md, roadmap, runbook:
publication is seven tables, minimum version stays 1.2.0).

## If something fails

- Before row 8: nothing user-visible changed; fix forward, or the C2 rollback
  (`supabase/rollback/20261124_c2_rollback.sql`, refuses once any record
  lives outside Personal) and redeploy the previous `sync-config.yaml` and
  `publication.sql`.
- After row 8: roll the web back in Vercel (Instant Rollback); 1.2.1 keeps
  working on Personal. Spaces created in B stay on the server until 1.3.0 is
  back (the C2 rollback then refuses; fix forward).
- iPhone: reinstall 1.2.1 from `~/fundly-releases/1.2.1-4/`. Its local
  database is now synced schema v3, which 1.2.1 cannot open: delete the app,
  install 1.2.1, sign in (signed-in data downloads again).
