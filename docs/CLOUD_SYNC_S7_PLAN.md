# Cloud sync S7: deployment and release verification

Date: 2026-11-22

Status: **approved 2026-11-22** (Decisions 1–7, all as recommended). S7.1
is in progress. S7 is split into three sub-slices; each
is planned in detail, done, verified and reviewed on its own, and the agent
stops after each.

## Goal

From [CLOUD_SYNC_PLAN.md](CLOUD_SYNC_PLAN.md) S7: release cloud sync for
real use, with evidence that the release matrix passes, and with written
steps for deploying, recovering and rolling back. Acceptance (unchanged):
the release matrix passes and the product owner reviews the result before
release. The agent never commits or pushes.

## Starting point

Much of S7's original list is already in place, done along the way:

| Area | State today |
|---|---|
| Supabase (Tokyo, `jiiuukimazvcxautvmya`) | Every migration through S6.1 applied. History repaired once, for S5.3 (powersync/README.md). Lint clean. Advisors list 3 known items: two intended SECURITY DEFINER RPCs, and leaked password protection off. |
| PowerSync (JP) | `sync-config.yaml` deployed. The publication holds exactly the five tables. Isolation checks passed on 2026-11-20. |
| Web | Deployed on Vercel at `fundly-budget.vercel.app` by `tool/vercel_build.sh`. Sign-in and sync work there; the owner confirmed "Up to date" after the S5 fixes. No `vercel.json` is committed, and powersync/README.md still lists only `localhost` as an allowed redirect. |
| iOS | Release builds installed on the owner's iPhone with `devicectl`, which keeps data. No TestFlight. |
| App version | `1.0.0+1` and never bumped. The app does not show it. |
| Automated checks | 1,102 Flutter tests, 789 pgTAP assertions, 29 concurrency races, the 14-check client contract runner and the 10,000-transaction timing check. All pass locally. |
| Deferred | Hand checks for S6.2 and S6.3 on devices. Android is never exercised. |

What is missing:

- one written release checklist;
- the hand-run two-device matrix;
- a recorded web origin with its headers;
- a compatibility and rollback policy;
- a backup and recovery plan for the cloud data;
- free-tier limits confirmed from the providers' own pages.

## What does not change

Financial rules, the local schema (v12), the synced schema, backup format 7,
the server tables and the write protocol (version 1). S7 adds no features.
The only app change, in S7.1, is showing the version (Decision 5).

## Sub-slices

### S7.1: Release readiness (agent, with owner dashboard steps)

**Result (2026-11-22): done by the agent. Four owner steps remain, listed at
the end.**

| Check | Result |
|---|---|
| Hosted migrations | `db push --remote --dry-run`: up to date |
| Hosted lint | No schema errors |
| Hosted advisors | The 3 known warnings only (accepted; Decision 7) |
| Publication | Exactly the five Fundly tables, not FOR ALL TABLES |
| Hosted size | 12 MB database, 4 Auth users |
| Isolation checks on hosted | **Not run:** test user credentials not available in the agent's shell |
| `vercel.json` | Committed: build command, `build/web` output, `.wasm` type, `no-cache` on the start-up, main and worker files. The live site already sends `public, max-age=0, must-revalidate` and `application/wasm`, so behaviour is unchanged. The file keeps the settings in the repository. Flutter's file names carry no content hash, so nothing gets long-term caching |
| Version | `1.1.0+2`; Profile shows "Version 1.1.0 (2)"; a test keeps `lib/app/app_version.dart` equal to `pubspec.yaml` |
| Builds | `flutter build ios --release` (25.9 MB) and `flutter build web --release`, both with `config/cloud.json` |
| Local suite | Format clean, analyze clean, 1,104 Flutter tests, 789 pgTAP assertions, local lint clean, 29 concurrency checks, 14 contract checks, 10,000 transactions imported in 0.60 s |

**Free-tier limits**, read from the providers' pages on 2026-11-22:

| Service | Limit | Fundly now | What it means |
|---|---|---|---|
| Supabase database | 500 MB per project | 12 MB | Years of personal use |
| Supabase egress | 5 GB a month | Small | Each full download is under 1 MB today |
| Supabase monthly active users | 50,000 | 4 | Not a constraint |
| Supabase inactivity | Free projects **pause after 1 week of inactivity**. A paused project can be restored for 90 days | — | **Can stop sync.** Daily use keeps it active. The runbook (S7.3) covers restoring it |
| PowerSync data synced | 2 GB a month | Small | Not a constraint |
| PowerSync hosted data | 500 MB | Small | Not a constraint |
| PowerSync peak concurrent clients | 50 | 2–3 devices | Not a constraint |
| PowerSync inactivity | Free instances are **deactivated after about 1 week without deploys or client connections**; the pricing page also mentions 2 weeks. A restarted instance reprocesses from scratch and every device downloads again | — | **Can stop sync.** Device data keeps working; the runbook covers the restart |
| PowerSync logs and alerts | Logs kept 24 hours; one email alert rule; no usage alerts | — | Check soon after a problem |

Sources: [Supabase pricing](https://supabase.com/pricing),
[Supabase billing](https://supabase.com/docs/guides/platform/billing-on-supabase),
[PowerSync pricing](https://powersync.com/pricing),
[PowerSync usage and billing](https://docs.powersync.com/resources/usage-and-billing).
Some figures differ between pages; the runbook uses the strictest one.

**Owner steps still open:**

1. Export the two test users' credentials (powersync/README.md step 5) and
   ask the agent to run the hosted isolation checks.
2. In the PowerSync dashboard, confirm the deployed Sync Streams match
   `powersync/sync-config.yaml`.
3. In Supabase → Authentication → URL Configuration, confirm the redirect
   URLs list `https://fundly-budget.vercel.app/**` and
   `http://localhost:7358/**`.
4. After pushing (which deploys to Vercel through Git), check the Vercel
   build log shows `bash tool/vercel_build.sh`, and that the web app still
   signs in and syncs. The agent can then re-read the live headers.

**Plan as approved:**

1. **Hosted server check, read only.** The agent runs these and records the
   results in powersync/README.md:
   - `db push --remote --dry-run` must say up to date;
   - `db lint --remote`;
   - `db advisors --remote`;
   - the publication table list;
   - `api_isolation.py` and `fundly_stream_test.dart` against the hosted
     project.

   The owner confirms the deployed PowerSync config matches
   `sync-config.yaml`.
2. **Free-tier limits.** Read the current Supabase and PowerSync pricing and
   limits pages. Record each limit next to Fundly's size, with the page and
   date:
   - database and egress size;
   - monthly active users;
   - PowerSync connections and synced data;
   - what happens after a period of inactivity (pause or deprovision).

   Anything that could stop the app becomes a line in the operations
   runbook (S7.3).
3. **Web origin** (Decision 2):
   - commit a `vercel.json` with the build command and output folder;
   - give `.wasm` files the `application/wasm` content type;
   - set cache rules: `index.html`, `flutter_bootstrap.js`, the service
     worker and the PowerSync worker are revalidated every time, so a deploy
     reaches browsers; other assets may be cached;
   - the owner confirms Supabase's allowed redirect URLs list
     `https://fundly-budget.vercel.app/**` and keeps `http://localhost:7358/**`
     for development. The agent records both.
4. **Version** (Decision 5): bump to `1.1.0+2` and show "Version 1.1.0 (2)"
   at the bottom of Profile, so each device's build is known while testing.
   This needs a small widget test.
5. **Builds:** iOS release (`flutter build ios --release`) and web release
   with the cloud config. Then the full local suite: format, analyze, tests,
   pgTAP, concurrency, contract and timing.

Done when every check above is recorded and passing, or a failure is
reported to the owner and fixed under its own approval.

### S7.2: Release verification matrix (owner and agent together)

A new `docs/RELEASE_CHECKLIST.md` turns the CLOUD_SYNC_PLAN matrix into
numbered steps. Each step has its devices, the exact actions, the expected
result, and a result column filled in on the day. Devices are the owner's
iPhone (release build), desktop Chrome and iPhone Safari, with two Google
accounts.

The matrix rows:

- same account on iOS and web;
- two users, so neither can see the other's data;
- offline edits, then a restart and reconnect;
- two clients editing or deleting the same record;
- archive or delete against concurrent spending;
- a retry after the server committed;
- a budget switch and a liability row update;
- a new client and the seeded default categories;
- sign-out or an account switch with changes waiting;
- restore and first import interrupted;
- browser refresh, several tabs, and cleared storage;
- an expired session or the service being unavailable.

It also includes the deferred hand checks:

- **S6.2:** copy this phone's data into the account.
- **S6.3:** restore a format 7 backup and an old format 6 backup while
  signed in, and restore a format 7 backup signed out.

The agent prepares each step, runs what it can from the Mac, and records
the results. Two-device steps need the owner. **Copying the owner's real
data comes last**, after every other row passes, and starts with a fresh
format 7 export of this phone's signed-out data.

Done when every row has a result. A failure becomes its own fix task, with
a plan and approval, and the row is run again afterwards.

#### S7.2 detailed plan (proposal, not approved)

The agent writes `docs/RELEASE_CHECKLIST.md`, prepares the devices, and runs
everything it can from the Mac. The owner does the two-device steps. Results
go into the checklist as they happen. The agent writes no app code; a failure
stops that row and becomes its own fix task.

**Before the session (agent):**

- Run the full local suite again, and the hosted isolation checks once the
  owner has exported the test credentials (S7.1 owner step 1).
- Install the 1.1.0 (2) release build on the owner's iPhone with `devicectl`.
  It installs over the existing app and keeps its data. Confirm Profile
  shows "Version 1.1.0 (2)".
- Check that the web app on Vercel shows the same version after the owner's
  push.

**Accounts and devices** (Decision S7.2-1):

- **Account A:** the owner's main Google account. It holds test records now;
  at the end it is reset and receives the real data.
- **Account B:** a second Google account the owner controls. It is used only
  for isolation and account-switch rows.
- **Devices:**
  - the iPhone (release build);
  - desktop Chrome (a normal window for A, a second Chrome profile for B);
  - iPhone Safari;
  - the iOS simulator, where the agent can drive a second iOS client for A.

**Safety first** (Decision S7.2-2): step 0 exports the iPhone's signed-out
data as a format 7 backup and saves it off the phone (Files, then the Mac).
Every later step leaves signed-out data alone, but this is the way back if
anything goes wrong.

**The checklist, in order:**

| # | Row | Who and how | Expected |
|---|---|---|---|
| 0 | Safety export | Owner: signed-out export on the iPhone, saved off the phone | File saved; counts noted |
| 1 | Same account, iOS and web | Owner: sign in as A on the iPhone and Chrome. Create an account and a few transactions of each type on one device, then edit and delete on the other | Same records, balances, Spending/Inflow totals and Plans on both; "Up to date" |
| 2 | New client, default categories | Agent: sign in as A on the simulator (a fresh client) | Downloads everything; no duplicated categories, plans or debt rows |
| 3 | Two users | Owner: B in the second Chrome profile. Agent: hosted isolation checks | B sees none of A's records and A none of B's; API and stream checks pass |
| 4 | Offline, restart, reconnect | Owner: iPhone in airplane mode; create, edit and delete; force-quit and reopen; turn the network back on | Changes kept as waiting while offline; they upload once each; Chrome matches |
| 5 | Same record on two clients | Owner: edit the same transaction on the iPhone (offline) and in Chrome; reconnect the iPhone. Then delete in one and edit in the other | One change wins; the other appears in Refused changes with Review, and its records go back to the server's state; nothing comes back after a delete |
| 6 | Archive or delete against spending | Owner: archive an account in Chrome while the offline iPhone adds spending to it; reconnect | The server applies its rule; the refused change is listed and recoverable |
| 7 | Retry after the server committed | Automated evidence (Decision S7.2-3): receipts in pgTAP, concurrency and contract tests | Exactly one accepted change; recorded by reference, not by hand |
| 8 | Budget switch and liability rows | Owner: switch the budget account, add a credit account and a loan, rename and archive one, on one device | Exactly one budget account and matching debt rows on both devices |
| 9 | Sign-out or switch with waiting changes | Owner: iPhone offline, make a change, sign out (the warning appears), cancel; then sign in as B in Chrome after A signed out | Nothing lost without confirming; no change uploads under the other user |
| 10 | Copy and restore (S6.2 and S6.3) | Owner, on account B: restore a format 7 backup; restore an old format 6 backup with Replace; turn on airplane mode during a copy, then open the screen again; restore format 7 signed out on the simulator | "Restored and checked" each time; an interrupted copy shows the account's counts when reopened, with nothing duplicated |
| 11 | Browser refresh, tabs, cleared storage | Owner: refresh Chrome; open two tabs; make a change offline, then clear site data | Reconnects safely; downloads again after clearing; the browser-only warning was shown before clearing |
| 12 | Expired session or service down | Owner: leave Chrome signed in past the token lifetime (or sign in again after Supabase sign-out on all devices); agent: block the PowerSync URL in Chrome DevTools | Data stays usable; status shows offline or reconnecting; sync resumes afterwards |
| 13 | Real data (last) | Owner: Reset all data on account A (checkpoint saved); then on the iPhone, Profile → Copy this device's data → Copy | "Copied and checked" with matching balances; Chrome shows the same data |

Rows 1 and 13 are the release-blocking pair: everything else must pass
before row 13 starts.

**After the session (agent):**

- read-only hosted counts for account A, compared with the iPhone's counts;
- the checklist filled in, with every row's result, and any failure written
  up as a proposed fix task.

**Expected time:** about two hours for the owner, splittable after any row.

**Decisions for the product owner:**

1. **Accounts:** A is the owner's main account, reset before the real copy;
   B is a second Google account the owner controls (recommended).
   Alternative: two separate test Google accounts, keeping the main one
   untouched until row 13.
2. **Safety export first** (row 0), even though signed-out data is never
   changed by these steps (recommended).
3. **Automated evidence for row 7**, which cannot be reproduced reliably by
   hand (recommended). Rows 3 and 12 also lean on the automated isolation
   check and on blocking the network.
4. **Failures stop the row, not the session.** Unrelated rows can continue,
   and row 13 waits until everything passes (recommended).

### S7.3: Operations runbook and docs (agent)

A new `docs/OPERATIONS.md`, written for the owner as the only operator:

- **Deploying, step by step:**
  - server migrations: dry run, take a backup (Decision 4), push, lint,
    advisors, record;
  - the PowerSync config;
  - the web app on Vercel;
  - iOS with `devicectl`;
  - in what order, when a change touches more than one.
- **Compatibility** (Decision 3): server changes stay additive under
  protocol 1, and an older installed app keeps working. A breaking change
  needs a new protocol version and its own approved plan. The minimum
  supported app version is 1.1.0.
- **Rollback:**
  - **web:** Vercel's instant rollback to the previous deployment;
  - **iOS:** reinstall the previous build;
  - **server:** forward-only migrations, so a fix is a new migration and a
    bad one is never edited in place;
  - **data:** restore a format 7 export (S6.3).
- **Outages:**
  - **Supabase or PowerSync down:** the app keeps working on device data,
    and changes wait with "Offline" or "Reconnecting".
  - **Expired session:** sign in again; queued changes are kept.
  - **Free-tier pause:** use the restore steps from S7.1.
- **Monitoring:** where to look (Supabase logs and usage, the PowerSync
  dashboard, Vercel deployments) and when, for example after each deploy
  and monthly.
- **Backup and recovery** (Decision 4): sync carries deletions to every
  device, so it is not a backup.
  - Keep regular format 7 exports from the app, kept off the phone.
  - The owner runs `supabase db dump` before every migration and monthly,
    stored outside the repository.
  - The doc includes the recovery steps for each.

**Docs to update on completion:**

- README (deployment and version);
- ROADMAP;
- CLAUDE.md:
  - §6: cloud sync and account registration become approved and delivered;
  - §10 status;
  - a §11 row for the release decisions;
- AGENTS.md;
- this plan.

Done when the runbook exists and the owner has reviewed it together with the
S7.2 results. Cloud sync is then released, and shared spaces (C0) can be
planned.

## Decisions for the product owner

Approved 2026-11-22: 1–7, each as recommended.

1. **Distribution:** personal use. iOS is installed straight from the Mac
   with `devicectl`, and the web app is on Vercel (recommended).
   Alternative: TestFlight, which needs a paid Apple Developer membership
   and review steps.
2. **Web origin:** keep `fundly-budget.vercel.app` (recommended; it already
   works and needs no domain). Alternative: a custom domain, which adds DNS,
   a Supabase redirect and Google OAuth origin changes.
3. **Compatibility policy:** additive server changes under protocol 1, no
   forced-update mechanism for now, and a written minimum app version
   (recommended). Alternative: build a minimum-version check into the app
   and server now.
4. **Cloud backup:** user-kept format 7 exports, plus an owner-run
   `supabase db dump` before every migration and monthly (recommended; free).
   Alternative: Supabase Pro for automatic daily backups and point-in-time
   recovery, which costs money.
5. **Version on Profile:** bump to 1.1.0+2 and show it (recommended; it tells
   which build each device runs). Alternative: no app change in S7.
6. **Android:** record it as not verified (no device), per D6. Recommended.
7. **Leaked password protection** (advisor warning): accept it. Users sign in
   with Google only; email and password exist only for the disposable test
   users the isolation check creates (recommended). Alternative: turn the
   feature on if the plan offers it.

## Risks

- **Free tier:** a free project that sleeps or is removed after inactivity
  would stop sync. S7.1 confirms the rule; the runbook says how to wake or
  restore it, and the local data on devices keeps working meanwhile.
- **Real data:** the first copy of the owner's data is the one irreversible
  step. It comes last in S7.2, after a fresh export, using the checked copy
  flow (S6.2).
- **Hand-run checks miss things automated tests cover poorly**, such as
  multi-tab browsers and storage clearing. The checklist makes each one
  explicit, with a result.
- **Web caching:** a stale cached build after a deploy can mix old and new
  files. The S7.1 cache rules and a check after each deploy cover it.
