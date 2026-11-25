# Fundly 1.4.0 release checklist (shared spaces C3.4 and Plans)

Status: **in progress (updated 2026-11-25).** 1.4.0 (6) releases:

- **Sharing** ([plan](SHARED_SPACES_C3_PLAN.md)): server migration
  `20261124040000_sharing.sql`, members' email and display name in the sync
  config (with the F.2 condition).
- **Default Target per category** (CLAUDE.md §11, 2026-11-25): server
  migration `20261125010000_category_default_target.sql`,
  `categories.default_target_minor` in the sync config, device schema v14
  (synced store v5), backup format 8. Commit `62131f9`.
- **Compact Plans rows** (Assigned and an Available pill, group totals, a
  details sheet) and **editing Assigned in place** (keypad, Activity,
  Details, target hint). Display only. Commits `6428567` and `12c5c6c`.

Follows [OPERATIONS.md](OPERATIONS.md); the agent never commits, pushes or
runs a production write.

## Where the release stands

| What | State | Evidence |
|---|---|---|
| Web app | **Already 1.4.0 (6) with sharing** (C3 pushed with `b416f03` on 2026-11-24, earlier than this plan's row 9). Not yet the three Plans commits | `version.json` reads 1.4.0 (6) on 2026-11-25 |
| Hosted database | **Both migrations applied** | `db push --remote --dry-run`: "Remote database is up to date"; latest migration `20261125010000`; `categories.default_target_minor`, `space_members.email` and `fundly_create_invite` exist (read-only query, 2026-11-25) |
| Backups | Taken (see row 1) | Files in `~/Documents/fundly-backup/` |
| Hosted sync config | **Deployed by the owner** (row 5, 2026-11-25) | Not visible to the agent; row 6 passes against it |
| Plans commits `62131f9`, `6428567`, `12c5c6c` | **Pushed**, with banks, R.18 and debt-row Targets after them | `main` equals `origin/main` (2026-11-25) |
| iPhone (A) | 1.3.0 (5) until Part C | |

## Before continuing

- **Every push to `main` deploys the web.** The three Plans commits are
  pushed only at row 9, after row 5.
- **Row 5 before row 9, always.** The default-Target app reads and writes
  `default_target_minor`. If the hosted sync config does not send it, every
  download writes categories back without their default Target, so a value
  set on the web disappears. That happened on local sync until local
  PowerSync was restarted with the new config (2026-11-25).
- `main`'s sync config also selects `space_members.email` and
  `display_name`; both exist on the hosted database now (row 2 done).

## Who and what

| Who | Does |
|---|---|
| Owner | Backups, `db push --remote`, the PowerSync dashboard step, pushing `main`, the device rows |
| Agent | Local checks, dry runs and read-only checks, hosted isolation and stream checks, the iOS build and install, recording results |

Accounts: **A** (real data) and **B** (test account). Spaces made for
checking are owned by **B**, which invites A; B deletes them at the end
(deleting arrives with this release).

Devices: the iPhone (A, 1.3.0 until Part C), Chrome (A, then B in a second
browser profile), the iPhone 16 Plus simulator (B, release build).

## Part A: server and sync

| # | Step | Pass when |
|---|---|---|
| 0 | Agent, local: `supabase test db` (including `category_default_target_test.sql`), `db lint`, the C3 rollback test, the concurrency tests, `client_contract_test.py`, and the legacy, C2 and C3 stream probes on local sync with `main`'s config | All pass, except count-based pgTAP checks that fail only because of dev data in the local database (list them in Results with the row counts) |
| 1 | **Backups.** Export from the iPhone (Profile → Export backup) and copy it to the Mac; owner dumps schema and data | **Done.** See Results |
| 2 | Agent: `db push --remote --dry-run`. Owner: `db push --remote` | **Done.** Both migrations applied; the dry run says "Remote database is up to date" |
| 3 | Agent: `db lint --remote` (public, fundly_private, fundly_access) and `db advisors --remote` | No lint errors; advisors: the known ones plus the new sharing RPCs as intended SECURITY DEFINER functions for `authenticated` (list them in Results) |
| 4 | Agent, read-only: every existing member has `email` (and `display_name` where the sign-in had one) backfilled; `space_invites` has RLS on and no client grants; every category has `default_target_minor` null, as nobody can set it yet | All true |
| 5 | Owner: PowerSync dashboard → Sync Streams → paste **`main`'s** `powersync/sync-config.yaml` → **Validate** → **Deploy**. Confirm the pasted text has `default_target_minor` in both categories queries and `email, display_name` in `space_members` | Validates and deploys |
| 6 | Agent: `api_isolation.py`, `fundly_stream_test.dart`, `c2_space_streams_test.dart` and `c3_sharing_streams_test.dart` against the hosted services | All pass |
| 7 | iPhone (1.3.0) and Chrome (A, current 1.4.0 build): Profile "Up to date"; data and balances unchanged; add and delete one transaction on the iPhone, seen in Chrome | Pass: both builds keep syncing with the new config |

## Part B: the Plans commits on the web and the simulator

| # | Step | Pass when |
|---|---|---|
| 8 | Agent, local: full app tests, `flutter analyze`, `flutter build web --release` on `main` with the three Plans commits | All pass |
| 9 | **Only after row 5.** Owner pushes `main`; agent checks `version.json`, the cache headers and that `/join` serves the app | Vercel serves the new deployment; `/join` returns the app, not 404. The version stays 1.4.0 (6), so row 10 confirms the new build by what it shows |
| 10 | Chrome (A): reload | "Version 1.4.0 (6)"; same data and balances; "Up to date"; Plans shows compact rows (Assigned and an Available pill) with group totals; Categories → edit a spending category shows a **Target** field |
| 11 | Chrome (A), default Target: set Target ₱1,000 on a spending category with no plan next month; Plans → next month | The row's details show Target ₱1,000 and the pill is yellow (or green once assigned). A month with its own Target keeps it |
| 12 | Older apps keep it: on the iPhone (1.3.0), rename that category, then reload Chrome | Chrome still shows Target ₱1,000 on the category form |
| 13 | Chrome (A), editing in place: tap the row, type `500+500`, `=`, Done | The keypad covers the tab bar; Assigned ₱1,000.00 saved; the hint "Assign … more to reach your target" filled the Target when tapped; Cancel discards; the row's Activity button and the keypad's Activity open the month's transactions; the keypad's Details opens the details sheet |
| 14 | Chrome (A): Profile → Export backup | The file says `"formatVersion": 8` and the category has `defaultTargetMinor` 100000 |
| 15 | Agent installs the 1.4.0 release build on the simulator; owner signs in as **B** there and in a second Chrome profile | Both show B's spaces |
| 16 | Simulator (B): create "Sharing check", ⋮ → Invite A's email as **Editor**, share the link | Link dialog shows once; Members lists the pending invite |
| 17 | Chrome (A): open the link | The address bar loses the secret; preview names B and the role; Accept switches to "Sharing check · Editor" |
| 18 | Both edit: A adds a transaction, B edits it; B sets a default Target on a category, A assigns to it in place | Each sees the other's change, including the default Target and the Assigned amount; Members shows both names and emails |
| 19 | Simulator (B): make A a **Viewer** | A's title reads "· Viewer"; A's add, edit and tapping Assigned show "View only"; Export still works |
| 20 | Removal with an unsent change: make A Editor again; A goes offline (DevTools → Network → Offline) and adds a transaction; B removes A; A goes online | A sees "Sharing check" as Removed with the banner and the refused change; Remove from this device works |
| 21 | B invites A again; A accepts; A ⋮ → Leave space | A is back in Personal with no Sharing check; B's Members no longer lists A |
| 22 | Simulator (B): ⋮ → Delete space, typing the name | Gone on both devices. Also delete the leftover test spaces ("Release check", "C2 check") owned by the test users |

## Part C: the iPhone (A) to 1.4.0

| # | Step | Pass when |
|---|---|---|
| 23 | Export a backup on the iPhone; agent copies the app's data off the phone (`devicectl`) and keeps the build in `~/fundly-releases/1.4.0-6/` | Copy readable (integrity ok) |
| 24 | Agent installs 1.4.0 over 1.3.0 (never delete the app) | `devicectl` reports 1.4.0 (6); data files present |
| 25 | iPhone: open Fundly | "Version 1.4.0 (6)", the same accounts, transactions and balances, "Up to date"; the category from row 11 shows Target ₱1,000 (the synced store upgrades to v5 and downloads it); Plans shows compact rows; Members of a space shows names; Join a space accepts a pasted link from B |

## Sign-off

All rows pass → C3 and the Plans changes complete; docs updated (CLAUDE.md,
roadmap, runbook, `powersync/README.md` log); minimum supported version
stays 1.2.0.

## If something fails

- **Before row 9:** the web still runs the C3 build and ignores
  `default_target_minor`. Fix forward. Sharing can still be undone with
  `supabase/rollback/20261124_c3_rollback.sql` (after a fresh backup); it
  replaces none of the functions the default-Target migration changed
  (`category_wire`, `apply_category`, `apply_plan_save`,
  `fundly_import_dataset`). Redeploy the F.2 hotfix's sync config
  (`git show hotfix/1.3.1:powersync/sync-config.yaml`) only together with
  that rollback.
- **Default-Target migration:** additive, with no rollback script. Older apps
  ignore the column and keep its value on update. Leave it in place; a fix is
  a new migration (never edit an applied one). To restore data, use the
  pre-migration dump (Results, row 1).
- **After row 9:** roll the web back in Vercel (Instant Rollback) to the
  deployment of `997260b` (the C3 build, also labelled 1.4.0 (6)). Default
  Targets already set stay on the server and return when the Plans build is
  redeployed.
- **iPhone:** reinstall 1.3.0 from `~/fundly-releases/1.3.0-5/`.

## Results

| # | Result |
|---|---|
| 1 | Hosted dumps in `~/Documents/fundly-backup/`: `2026-11-24_c3_*` (19:39, before sharing); `YYYY-MM-DD_schema.sql` / `YYYY-MM-DD_data.sql` (2026-11-25 01:15: sharing applied, **before the default-Target migration**: the only pre-migration copy, so keep it; rename it to `2026-11-25_pre-default-target_*`); `2026-11-25_1.4.0_*` (01:18, after both migrations). iPhone export not recorded |
| 2 | Both migrations applied. Dry run on 2026-11-25: "Remote database is up to date"; latest migration `20261125010000` (read-only check) |
| 9 (C3 part) | The C3 app reached the web with `b416f03` (2026-11-24), before Part A finished: `version.json` reads 1.4.0 (6) |
| 0 (partial) | 2026-11-25. `supabase test db`: 1,178 of 1,182 pass. The 4 failures are counts of dev data in the local database: `schema_test` 1 (24 = 5 + 19 existing transactions) and 98 (9 = 2 + 7 existing plans); `dataset_import_test` 72 and 102 (1 existing import receipt). Local `db lint`: no errors. All 7 concurrency tests and `client_contract_test.py` (14 checks) pass. **Not run yet:** `c3_rollback_test.py` (it resets the local database; waiting for the owner) and the local stream probes |
| 2 (recheck) | 2026-11-25, owner: dry run says "Remote database is up to date". The local migrations end at `20261127020000`, so banks (`20261126010000`), card purchases (`20261127010000`) and debt-row Targets (`20261127020000`) are on production too. The web (`main`, pushed) already runs those 1.5.0 changes, still labelled 1.4.0 (6); Part B does not check them |
| 3 | 2026-11-25. `db lint --remote` (public, fundly_private, fundly_access): no errors. `db advisors --remote`: only WARN `authenticated_security_definer_function_executable` for 14 intended RPCs (`fundly_apply_operations`, `fundly_import_dataset`, `fundly_create_space`, `fundly_rename_space`, and the C3 ones: `fundly_create_invite`, `fundly_list_invites`, `fundly_preview_invite`, `fundly_accept_invite`, `fundly_decline_invite`, `fundly_revoke_invite`, `fundly_set_member_role`, `fundly_remove_member`, `fundly_leave_space`, `fundly_delete_space`) and `auth_leaked_password_protection` (Google sign-in only) |
| 4 | 2026-11-25, read-only. 9 members, none missing an email; 5 without a display name, none of whom has a name from sign-in; `space_invites` RLS on, no `anon` or `authenticated` grants. 7 of 43 categories already have a default Target, set since the Plans build reached the web (not a failure) |
| 5 | 2026-11-25, owner: `main`'s `powersync/sync-config.yaml` (as of `811f831`, with banks) deployed in the PowerSync dashboard |
| 6 | 2026-11-25, against the hosted services: `api_isolation.py` 15/15 pass (test records removed); `fundly_stream_test.dart`, `c2_space_streams_test.dart` and `c3_sharing_streams_test.dart` pass |
