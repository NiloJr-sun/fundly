# Fundly 1.1.0 release checklist (cloud sync S7.2)

The release session for cloud sync, from the
[approved S7.2 plan](CLOUD_SYNC_S7_PLAN.md). Work top to bottom; you can
stop after any row and resume later. Record each result as you go: **Pass**,
**Fail** with what you saw, or **Skipped** with why. A failure stops that row
only. Note it, carry on with unrelated rows, and the agent turns it into its
own fix task. **Row 13 (your real data) starts only when every other row has
passed.**

## Who and what

- **Account A:** your main Google account. It gets your real data in row 13.
- **Account B:** a second Google account you control.
- **iPhone:** release build 1.1.0 (2), with Profile showing "Version 1.1.0 (2)".
- **Chrome:** <https://fundly-budget.vercel.app>. Use your normal profile for
  A and a second Chrome profile for B. Its Profile must show
  "Version 1.1.0 (2)" too.
- **iPhone Safari:** the same address.
- **Simulator:** driven by the agent as an extra iOS client for A.

"Up to date" below means the sync line on Profile, under the greeting.

## Before the session

| Item | Status |
|---|---|
| Local suite: analyze, 1,104 Flutter tests, 789 pgTAP assertions, 14 contract checks | Done 2026-11-23, all pass |
| Release build 1.1.0 (2) on the iPhone, installed over the old app with its data kept | Done 2026-11-23 (`devicectl` reports 1.1.0, build 2) |
| Simulator build with the cloud config | Done 2026-11-23 |
| Web app on Vercel shows 1.1.0 (2) | Done 2026-11-23: the live `version.json` says 1.1.0 (2). The `vercel.json` headers are live: `no-cache` on `/`, `main.dart.js` and the PowerSync worker; `application/wasm` on `sqlite3.wasm`; other files keep Vercel's `max-age=0, must-revalidate` |
| Hosted isolation checks (`api_isolation.py`, `fundly_stream_test.dart`) | **Open:** export the test users' credentials (powersync/README.md step 5), then ask the agent |
| PowerSync Sync Streams match `powersync/sync-config.yaml` | **Open:** you, in the PowerSync dashboard |
| Supabase redirect URLs list `https://fundly-budget.vercel.app/**` and `http://localhost:7358/**` | **Open:** you, in Supabase → Authentication → URL Configuration |
| Account B exists and can sign in with Google | **Open:** you |

## Rows

### 0. Safety export

1. On the iPhone, **signed out**, open Profile → Export backup.
2. Save the file to Files, then copy it to the Mac (AirDrop works).
3. Write down the counts the app shows for this device: accounts,
   categories, transactions and plans.

Expected: the file is saved off the phone. Nothing later changes signed-out
data, but this is the way back.

Result:

### 1. Same account on iOS and web

1. Sign in as A on the iPhone and in Chrome. Wait for "Up to date" on both.
2. On the iPhone, create one account, then one transaction of each type:
   Spending, Inflow, Transfer and Credit Card Payment.
3. In Chrome, check they appear. Then edit one transaction's amount and
   delete another.
4. Back on the iPhone, check the edit and the deletion arrived.
5. Compare both devices: each account's balance, the Spending tab totals
   for this month, and the Plans tab.

Expected: the same records and the same figures on both. "Up to date" on
both, with nothing waiting to upload.

Result:

### 2. New client and default categories (agent)

1. The agent installs the simulator build fresh, then signs in as A. You may
   need to complete the Google sign-in on the simulator.
2. Wait for the first download to finish.

Expected:

- every record from row 1 is there;
- the categories are not duplicated: one of each default, no extra
  "Utilities" or similar;
- there is one debt row per credit card or loan.

Result:

### 3. Two users

1. In the second Chrome profile, sign in as B.
2. Check B sees none of A's accounts or transactions.
3. Add one account as B, and check it does not appear for A on the iPhone.
4. The agent runs the hosted isolation checks.

Expected: no records cross between the users, and both automated checks
pass.

Result:

### 4. Offline, restart, reconnect

1. Put the iPhone in airplane mode.
2. Create a transaction, edit another, and delete a third.
3. Check Profile says Offline, with 3 changes waiting.
4. Force-quit Fundly and open it again. Check the 3 changes are still
   waiting.
5. Turn airplane mode off and wait for "Up to date".
6. Check Chrome shows exactly those three changes, once each.

Expected: nothing is lost or duplicated, and both devices end up the same.

Result:

### 5. The same record on two clients

1. With the iPhone in airplane mode, change the payee of transaction X.
2. In Chrome, change X's amount.
3. Turn the iPhone's network back on.
4. Then, with the iPhone offline again, delete transaction Y on the iPhone
   and edit Y in Chrome. Reconnect the iPhone.

Expected:

- In each case the server keeps one change.
- The device whose change lost shows "1 change refused · Review" on
  Profile; the Refused changes screen explains it.
- That device's records return to the server's version.
- A deleted transaction never comes back.

Result:

### 6. Archive against spending

1. Put the iPhone in airplane mode.
2. Add spending on account Z on the iPhone.
3. In Chrome, archive account Z. If it has a balance, confirm the archive.
4. Reconnect the iPhone.

Expected: the server applies its rule, and the refused spending is listed
under Refused changes. Afterwards both devices show the same records.

Result:

### 7. Retry after the server committed (automated evidence)

No hand steps: a lost response cannot be reproduced reliably by hand
(Decision S7.2-3). The evidence is:

- the pgTAP retry and receipt tests (`write_api_test.sql`,
  `dataset_import_test.sql`);
- the identical-retry concurrency checks;
- the client contract runner, which retries the first batch.

All passed on 2026-11-23.

Result: Pass (automated)

### 8. Budget account and debt rows

1. On the iPhone, open a Savings/Cash account's form and turn on "Use as
   budget account". Confirm moving it if asked.
2. Add a credit card account and a loan account.
3. Rename the credit card, then archive the loan.
4. Check Chrome.

Expected:

- exactly one budget account on both devices;
- Plans shows a debt row named after the renamed card;
- the loan's debt row has moved to Archived plans.

Result:

### 9. Sign out or switch users with changes waiting

1. With the iPhone in airplane mode, make one change.
2. Profile → Sign out. A warning about the waiting change appears; choose
   Cancel.
3. Reconnect, and wait for "Up to date".
4. In Chrome's normal profile, sign out of A, then sign in as B in that same
   profile.

Expected: nothing leaves the device without your confirmation, and B never
sees, or uploads, A's records.

Result:

### 10. Copy and restore (S6.2 and S6.3)

Do these as **account B**, so A stays clean for row 13.

1. In Chrome as A, export a backup (format 7). Keep the file.
2. On the iPhone, sign in as B, then Profile → Restore from backup and pick
   that file. Choose Restore into my account (or Replace, with the
   checkpoint and "replace my data").
3. Restore an older backup file in format 6 or earlier, if you have one, the
   same way. Use Replace.
4. Start a restore, then turn on airplane mode right after tapping the
   button. Turn it off and open Restore again.
5. The agent restores the row 10.1 file signed out on the simulator.

Expected:

- steps 2 and 3 end with "Restored and checked" and matching balances;
- in step 4, reopening shows the account's counts, either the old ones or
  the backup's, never a mix, and no record is duplicated;
- step 5 restores locally with the same counts.

Result:

### 11. Browser refresh, tabs, cleared storage

1. In Chrome, refresh the page while signed in as A.
2. Open the app in a second tab, and make a change in each tab.
3. Go offline (DevTools → Network → Offline), make a change, and check
   Profile says it is saved only in this browser.
4. Clear the site's data (DevTools → Application → Clear site data) and
   reload.

Expected:

- steps 1 and 2 stay consistent;
- after clearing, the app signs in again and downloads every accepted
  record;
- only the offline change from step 3 is gone, as the browser-only note
  warned.

Result:

### 12. Expired session or service down

1. In Chrome DevTools → Network, block requests to the PowerSync address
   (request blocking). Make a change.
2. Unblock it.
3. Sign out on the iPhone and sign in again.

Expected:

- while blocked, the data stays usable and Profile shows Reconnecting or
  waiting changes;
- after unblocking, it uploads and shows "Up to date";
- after signing in again, the iPhone downloads and matches.

Result:

### 13. Your real data (last)

Start only when rows 0–12 have passed.

1. On the iPhone, signed in as A, Profile → Reset all data. Export the
   checkpoint, type "delete my data", then wait for "All data deleted".
2. Profile → Copy this device's data → check the counts match row 0 →
   Copy to my account.
3. Wait for "Copied and checked", with every balance "Same in your
   account".
4. Open Chrome as A and compare balances, the Spending tab and Plans with
   the iPhone.
5. The agent compares the server's counts for A with row 0's counts (read
   only).

Expected: your real data is in the account, checked record by record, and
the same on the web.

Result:

## Sign-off

| | |
|---|---|
| Rows passed | |
| Failures and fix tasks | |
| Owner sign-off (release 1.1.0) | |
