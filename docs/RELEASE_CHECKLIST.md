# Fundly 1.2.0 release checklist (cloud sync S7.2)

The release session for cloud sync, from the
[approved S7.2 plan](CLOUD_SYNC_S7_PLAN.md). It runs in two parts
(changed 2026-11-23 because the iPhone is not available):

- **Part 1, now:** the simulator and Chrome. Rows 1–3 and 5–12. Chrome's
  DevTools "Offline" switch plays the offline device, because the simulator
  has no airplane mode of its own.
- **Part 2, when the iPhone is back:** rows 0, 1b, 4 and 13, on the iPhone's
  release build. Your real data stays on the iPhone, untouched on 1.1.0,
  until row 0 is done.

Work top to bottom within each part; you can stop after any row and resume
later. Record each result as you go: **Pass**,
**Fail** with what you saw, or **Skipped** with why. A failure stops that row
only. Note it, carry on with unrelated rows, and the agent turns it into its
own fix task. **Row 13 (your real data) starts only when every other row has
passed**, including the Part 2 rows before it.

## Who and what

- **Account A:** your main Google account. It gets your real data in row 13.
- **Account B:** a second Google account you control.
- **Simulator (Part 1):** the 1.2.0 (3) build with the cloud config, on the
  Mac. You use it with the mouse; the agent installs or resets it when a row
  says so. It stands in for the iPhone as the iOS client.
- **Chrome:** <https://fundly-budget.vercel.app>. Use your normal profile for
  A and a second Chrome profile for B. Its Profile must show
  "Version 1.2.0 (3)" too.
- **iPhone (Part 2):** release build 1.2.0 (3), with Profile showing
  "Version 1.2.0 (3)".

"Up to date" below means the sync line on Profile, under the greeting.

## Before the session

| Item | Status |
|---|---|
| Local suite on 1.2.0 (3): format, analyze, 1,149 Flutter tests, 794 pgTAP assertions, 28 concurrency races, 14 contract checks, 10,000-transaction timing | Done 2026-11-23, all pass |
| Safety export of the iPhone's signed-out data, taken from 1.1.0 (2) before installing 1.2.0 (3) | **Part 2:** you (row 0) |
| Hosted server has the cash advance and several budget accounts migrations | Done 2026-11-23: up to date, functions match the local stack, lint clean, the 3 known advisor warnings (powersync/README.md) |
| Release build 1.2.0 (3) on the iPhone, installed over the old app with its data kept | **Part 2:** after the safety export (row 0) |
| Simulator build 1.2.0 (3) with the cloud config | Done 2026-11-23: installed over the old build; its existing data opens |
| Web app on Vercel shows 1.2.0 (3) | **Open:** after your push. 1.1.0 (2) was live on 2026-11-23 with the `vercel.json` headers (`no-cache` on `/`, `main.dart.js` and the PowerSync worker; `application/wasm` on `sqlite3.wasm`) |
| Hosted isolation checks (`api_isolation.py`, `fundly_stream_test.dart`) | **Open:** export the test users' credentials (powersync/README.md step 5), then ask the agent |
| PowerSync Sync Streams match `powersync/sync-config.yaml` | **Open:** you, in the PowerSync dashboard |
| Supabase redirect URLs list `https://fundly-budget.vercel.app/**` and `http://localhost:7358/**` | **Open:** you, in Supabase → Authentication → URL Configuration |
| Account B exists and can sign in with Google | **Open:** you |

## Part 1: simulator and Chrome

### 1. Same account on iOS and web

1. Sign in as A on the simulator and in Chrome. Wait for "Up to date" on
   both.
2. On the simulator, create one account, then one transaction of each type:
   Spending, Inflow, Transfer and Credit Card Payment.
3. In Chrome, check they appear. Then edit one transaction's amount and
   delete another.
4. Back on the simulator, check the edit and the deletion arrived.
5. Compare both: each account's balance, the Spending tab totals for this
   month, and the Plans tab.

Expected: the same records and the same figures on both. "Up to date" on
both, with nothing waiting to upload.

Result:

### 2. New client and default categories (agent)

1. Check the simulator says "Up to date", so row 1 is on the server.
2. The agent copies the simulator's `Documents/fundly.sqlite` to the Mac,
   then deletes and reinstalls the simulator app, then you sign in as A on
   it. You may need to complete the Google sign-in.
3. Wait for the first download to finish.

Expected:

- every record from row 1 is there;
- the categories are not duplicated: one of each default, no extra
  "Utilities" or similar;
- there is one debt row per credit card or loan.

Result:

### 3. Two users

1. In the second Chrome profile, sign in as B.
2. Check B sees none of A's accounts or transactions.
3. Add one account as B, and check it does not appear for A on the
   simulator.
4. The agent runs the hosted isolation checks.

Expected: no records cross between the users, and both automated checks
pass.

Result:

### 5. The same record on two clients

1. In Chrome as A, go offline (DevTools → Network → Offline) and change the
   payee of transaction X.
2. On the simulator, change X's amount.
3. Put Chrome back online.
4. Then, with Chrome offline again, delete transaction Y in Chrome and edit
   Y on the simulator. Put Chrome back online.

Expected:

- In each case the server keeps one change.
- The client whose change lost shows "1 change refused · Review" on
  Profile; the Refused changes screen explains it.
- That client's records return to the server's version.
- A deleted transaction never comes back.

Result:

### 6. Archive against spending

1. In Chrome as A, go offline.
2. Add spending on account Z in Chrome.
3. On the simulator, archive account Z. If it has a balance, confirm the
   archive.
4. Put Chrome back online.

Expected: the server applies its rule, and the refused spending is listed
under Refused changes in Chrome. Afterwards both show the same records.

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

### 8. Budget accounts and debt rows

1. On the simulator, turn on "Use as budget account" for two Savings/Cash
   accounts (each has its own switch).
2. Transfer between those two accounts.
3. Add a credit card account and a loan account.
4. Record a cash advance: a Transfer from the credit card to one of the
   budget accounts.
5. Rename the credit card, then archive the loan.
6. Check Chrome.

Expected:

- the same two budget accounts on both, and the Ready to assign card lists
  both;
- the transfer between them is neither money in nor moved out;
- the cash advance raises the card's owed amount, counts as money in for
  Ready to assign, and is not on the card's debt row Activity or in the
  Spending/Inflow totals;
- nothing for this row appears in Refused changes;
- Plans shows a debt row named after the renamed card;
- the loan's debt row has moved to Archived plans.

Result:

### 9. Sign out or switch users with changes waiting

1. In Chrome as A, go offline and make one change.
2. Profile → Sign out. A warning about the waiting change appears; choose
   Cancel.
3. Go back online, and wait for "Up to date".
4. In Chrome's normal profile, sign out of A, then sign in as B in that same
   profile.

Expected: nothing leaves the browser without your confirmation, and B never
sees, or uploads, A's records.

Result:

### 10. Copy and restore (S6.2 and S6.3)

Do these as **account B**, so A stays clean for row 13.

1. In Chrome as A, export a backup (format 7). Keep the file.
2. Drag the file onto the simulator window, which saves it to Files. On the
   simulator, sign in as B, then Profile → Restore from backup and pick that
   file. Choose Restore into my account (or Replace, with the checkpoint and
   "replace my data").
3. Restore an older backup file in format 6 or earlier, if you have one, the
   same way. Use Replace.
4. In Chrome as B, start a restore of the same file, then go offline right
   after tapping the button. Go back online and open Restore again.
5. On the simulator, sign out, then restore the step 1 file signed out.

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
3. On the simulator, sign in as A again (sign out first if signed in), and
   wait for the download.

Expected:

- while blocked, the data stays usable and Profile shows Reconnecting or
  waiting changes;
- after unblocking, it uploads and shows "Up to date";
- after signing in again, the simulator downloads and matches Chrome.

Result:

## Part 2: when the iPhone is back

### 0. Safety export

1. On the iPhone, still on 1.1.0 and **signed out**, open Profile → Export
   backup.
2. Save the file to Files, then copy it to the Mac (AirDrop works).
3. Write down the counts the app shows for this device: accounts,
   categories, transactions and plans.

Do this **before** 1.2.0 (3) is installed: the new build upgrades the
signed-out data to schema v13 when it first opens. Then the agent installs
1.2.0 (3) with `devicectl`, keeping the data. Check Profile shows
"Version 1.2.0 (3)" and the signed-out data opens with the same counts.

Expected: the file is saved off the phone, and the upgraded app shows the
same data. Nothing later changes signed-out data, but this is the way back.

Result:

### 1b. The release build on the iPhone

1. On the iPhone, sign in as A. Wait for "Up to date".
2. Check the records from Part 1 are there, and compare balances, the
   Spending tab and Plans with Chrome.
3. Make one change on the iPhone and one in Chrome, and check each arrives
   on the other.

Expected: the same records and figures on both, "Up to date", nothing
waiting.

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

### 13. Your real data (last)

Start only when every other row has passed.

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
| Owner sign-off (release 1.2.0) | |
