# Cloud sync S7: deployment and release verification (proposal)

Date: 2026-11-22

Status: **proposal, not approved.** Nothing here starts until the product
owner approves the decisions below. S7 is split into three sub-slices; each
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
