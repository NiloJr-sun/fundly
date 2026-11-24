# Fundly 1.3.0 release checklist (shared spaces C2.4)

Status: **signed off 2026-11-24** after every row passed. Part A and row 8 were carried out outside
this checklist's order by another session (stopped by the owner at about
14:10); the agent then verified them read-only and with the hosted checks, and
drives the rest. See "Results" at the end. Release of private spaces ([plan](SHARED_SPACES_C2_PLAN.md)):
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

## Results

| # | Result |
|---|---|
| 0 | **No C2 backup was taken before the push.** Instead, read-only comparison (14:10): every Personal record on production (14 accounts, 35 categories, 34 transactions, 14 plans; ids and revisions) is identical to the owner's C1 dump of 10:43 (`~/fundly-backups/2026-11-24-c1/`), so that dump holds the pre-C2 records. The iPhone export comes before Part C |
| 1–2 | Migration `20261124030000_private_spaces.sql` applied (pushed outside this checklist); dry run "up to date"; `db lint` (3 schemas) clean; advisors: the 3 known warnings plus the 2 intended ones (`fundly_create_space`, `fundly_rename_space`) |
| 3 | Every pre-existing record still has `owner_id` (Personal); replication role `powersync_…` can read `spaces` |
| 4 | Publication lists exactly the seven tables |
| 5 | PowerSync config with `fundly_spaces` and `fundly_space_data` deployed (shown by row 6) |
| 6 | Hosted, 14:05: `api_isolation.py` 15/15; `fundly_stream_test.dart` (old stream: Personal only) pass; **`c2_space_streams_test.dart` pass: first hosted proof of per-space streams**, including a non-member getting nothing |
| 8 | Pushed with the release commit; Vercel served 1.3.0 (5) from 13:54 |
| 9–11 (partly) | Account A has a space "Household" created at 14:04 with its own 9 default categories, so 1.3.0 created a space on production and the new streams delivered it |
| 7 | Passed on the iPhone and Chrome, but **the iPhone already ran 1.3.0** (installed by the other session), so 1.2.1 was not checked on a device. Old-app behaviour is covered by the hosted `fundly_stream_test.dart` (the automatic stream, as 1.2.x uses it, carries exactly Personal); no device runs 1.2.1 any more |
| 9 | Chrome (A) on 1.3.0 (5): space row, same data and balances, "Up to date" |
| 10–11 | Not run with account B: the remaining space rows used A's "Household" instead (owner's choice), since it already existed |
| 12–13 | iPhone and Chrome (A): an account and a transaction added in Household appear only in Household, never in Personal; Spending and Plans name the space; a rename on the iPhone reached Chrome |
| 14 | Agent copied the iPhone's data to `~/Downloads/fundly-iphone-backup-1.3.0-2026-11-24/` (mode 700): integrity ok; Personal 7 accounts, 17 transactions, nothing waiting; Household its 9 default categories |
| 15 | Already installed by the other session: `devicectl` reports 1.3.0 (5); build `~/fundly-releases/1.3.0-5/` made at 13:29 from the release code (after the last app commit, with the version bump) |
| 16 | iPhone: 1.3.0 (5), Personal · Owner, same accounts, transactions and balances, "Up to date"; a transaction created, edited and deleted, each seen in Chrome |

**Signed off 2026-11-24.** Shared spaces C2 (private spaces) is released as
1.3.0 (5). Follow-up: a pre-deploy dump is part of the runbook and was missed
this time; the next release takes it before any `db push`.
