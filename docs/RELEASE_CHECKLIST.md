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
| Safety export of the iPhone's signed-out data, taken from 1.1.0 (2) before installing 1.2.0 (3) | Done 2026-11-23, see row 0 |
| Hosted server has the cash advance and several budget accounts migrations | Done 2026-11-23: up to date, functions match the local stack, lint clean, the 3 known advisor warnings (powersync/README.md) |
| Release build 1.2.0 (3) on the iPhone, installed over the old app with its data kept | Done 2026-11-23: `devicectl` reports 1.2.0 (3); the app's data files are unchanged; build kept in `~/fundly-releases/1.2.0-3/` |
| Simulator build 1.2.0 (3) with the cloud config | Done 2026-11-23: installed over the old build; its existing data opens |
| Web app on Vercel shows 1.2.0 (3) | Done 2026-11-23: the live `version.json` says 1.2.0 (3). Headers still live: `no-cache` on `/`, `flutter_bootstrap.js`, `main.dart.js`, `version.json` and the PowerSync worker; `application/wasm` on `sqlite3.wasm` |
| Hosted isolation checks (`api_isolation.py`, `fundly_stream_test.dart`) | Done 2026-11-23: 15 API checks pass; stream test passes (forged token refused, `401 PSYNC_S2101`) |
| PowerSync Sync Streams match `powersync/sync-config.yaml` | Done 2026-11-23 (owner, dashboard) |
| Supabase redirect URLs list `https://fundly-budget.vercel.app/**` and `http://localhost:7358/**` | Done 2026-11-23 (owner, dashboard) |
| Account B exists and can sign in with Google | Done 2026-11-23 (owner) |

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

Result: Pass (2026-11-23, simulator 1.2.0 (3) and Chrome)

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

Result: Pass (2026-11-23). Fresh simulator install signed in as A: 7 accounts, 13 categories (no duplicates), 17 transactions, 7 monthly plans, 4 debt rows for the 4 credit/loan accounts (none missing or doubled), 0 waiting uploads. Every record identical, field by field, to the pre-reinstall store (backup in `~/Downloads/fundly-simulator-backup-2026-11-23/`)

### 3. Two users

1. In the second Chrome profile, sign in as B.
2. Check B sees none of A's accounts or transactions.
3. Add one account as B, and check it does not appear for A on the
   simulator.
4. The agent runs the hosted isolation checks.

Expected: no records cross between the users, and both automated checks
pass.

Result: Pass (2026-11-23). Manual: B in a second Chrome profile sees none of A's records; the account B added is not on the simulator signed in as A. Hosted isolation checks, run by the agent with two new disposable test users: `api_isolation.py` all 15 checks passed (check records removed); `fundly_stream_test.dart` passed, a forged token refused with `401 PSYNC_S2101`.

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

Result: Pass (2026-11-23, Chrome offline as the losing client). X: the simulator's amount change won; Chrome's edit was refused ("Changed on another device first") and Chrome showed the server's version. Y (the same transaction): the simulator's edit won; Chrome's offline delete was refused and the transaction came back in Chrome as "Edit", ₱300.00 (revision 4). Simulator: 18 transactions, no refused changes, nothing waiting.

Follow-up (not blocking): a refused **delete** card names no transaction and shows no details, unlike a refused edit card, so several refused deletes cannot be told apart.

### 6. Archive against spending

1. In Chrome as A, go offline.
2. Add spending on account Z in Chrome.
3. On the simulator, archive account Z. If it has a balance, confirm the
   archive.
4. Put Chrome back online.

Expected: the server applies its rule, and the refused spending is listed
under Refused changes in Chrome. Afterwards both show the same records.

Result: Pass (2026-11-23, Chrome offline). Z was a new Savings/Cash account with a ₱2,345.00 opening balance, archived on the simulator with confirmation. Chrome's offline spending on Z was refused and listed under Refused changes; Z shows as archived in Chrome and the spending is gone. Simulator: 8 accounts, 18 transactions, none on Z, no refused changes, nothing waiting.

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

Result: Pass (2026-11-23, simulator and Chrome; the agent compared before/after figures from the synced store). Budget accounts BPI 1, BPI 2 and Metrobank (already set). Internal transfer BPI 1 → BPI 2 (₱1.00): not money in or moved out. New credit card (opening −₱2,000.00) and loan (opening −₱1,000.00). Cash advance card → BPI 1 (₱100.00): accepted; card owed −₱2,000.00 → −₱2,100.00; November money in ₱17,083.03 → ₱17,183.03; moved out stays ₱0.00; Inflow and Spending totals unchanged; card debt row Activity ₱0.00. Card renamed and its debt row followed; loan archived and its row moved to Archived plans. Chrome's Ready to assign lists the three budget accounts with the same money in. No refused or waiting changes.

### 9. Sign out or switch users with changes waiting

1. In Chrome as A, go offline and make one change.
2. Profile → Sign out. A warning about the waiting change appears; choose
   Cancel.
3. Go back online, and wait for "Up to date".
4. In Chrome's normal profile, sign out of A, then sign in as B in that same
   profile.

Expected: nothing leaves the browser without your confirmation, and B never
sees, or uploads, A's records.

Result: Pass (2026-11-23, Chrome). Offline change: spending "Row9" ₱9.99 on BPI 1. Sign out showed the waiting-change warning; Cancel kept A signed in. Back online it uploaded under A once (on the simulator: revision 1, 21 transactions, nothing waiting or refused). Signed in as B in the same Chrome profile: none of A's records, no "Row9"; only B's own account.

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

Result: Pass (2026-11-23). Step 2 was done into **A** instead of B: the simulator, signed in as A, restored a format 7 file (7 accounts, 17 transactions, exported 5:40 pm) with Replace and showed "Restored and checked"; the agent confirmed A's counts and every account balance match the file. This replaced A's rows 1–9 test records, whose results were already recorded; A is reset in row 13 anyway. Step 3: a format 6 file restored into B in Chrome with Replace (owner: pass). Step 4: an interrupted Replace in Chrome as B, reopened afterwards, showed whole counts with nothing mixed or doubled (owner: pass). Step 5: signed-out restore on the simulator; the agent confirmed 7 accounts, 13 categories, 17 transactions and 7 monthly plans, with every balance identical to the file.

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

Result: Pass (2026-11-23, owner in Chrome as A): refresh and two tabs stayed consistent; the offline change was marked browser-only; after clearing site data the app signed in again and downloaded every accepted record, losing only that offline change.

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

Result: Pass (2026-11-23). With PowerSync blocked in Chrome as A, spending "ENV" ₱22.00 on BPI 1 stayed usable and uploaded once after unblocking. The simulator signed in as A again ("Not now" on the copy prompt), showed "Up to date" and matched the account: 7 accounts, 13 categories, 18 transactions, 7 plans, "ENV" at revision 1, nothing waiting or refused; its signed-out data stayed unchanged.

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

Result: Done 2026-11-23, with a different safety copy. The owner exported on the phone, but the file did not reach the Mac. Instead the agent copied the app's whole data folder off the phone with `devicectl` (to `~/Downloads/fundly-iphone-backup-1.1.0-2026-11-23/`; integrity check ok) before installing. Findings: the phone's signed-out store was already at schema v13 (the 1.1.0 (2) label also covered later builds) and held **no records**, only the 9 default categories; its signed-in store for A held 7 accounts, 13 categories, 17 transactions and 7 plans as of 3:41 pm, the same data as A before row 1. After the install the owner confirmed Profile shows "Version 1.2.0 (3)" with the data unchanged. Pass.

### 1b. The release build on the iPhone

1. On the iPhone, sign in as A. Wait for "Up to date".
2. Check the records from Part 1 are there, and compare balances, the
   Spending tab and Plans with Chrome.
3. Make one change on the iPhone and one in Chrome, and check each arrives
   on the other.

Expected: the same records and figures on both, "Up to date", nothing
waiting.

Result: Pass (2026-11-23, owner): the iPhone on 1.2.0 (3) signed in as A matched Chrome (balances, Spending tab, Plans), and a change made on each side arrived on the other.

### 4. Offline, restart, reconnect

1. Put the iPhone in airplane mode.
2. Create a transaction, edit another, and delete a third.
3. Check Profile says Offline, with 3 changes waiting.
4. Force-quit Fundly and open it again. Check the 3 changes are still
   waiting.
5. Turn airplane mode off and wait for "Up to date".
6. Check Chrome shows exactly those three changes, once each.

Expected: nothing is lost or duplicated, and both devices end up the same.

Result: Pass (2026-11-23, owner on the iPhone 1.2.0 (3)): three offline changes stayed waiting through a force-quit, uploaded once each after reconnecting, and Chrome matched. The test records were deleted afterwards.

### 13. Your real data (last)

Rewritten 2026-11-23 (owner approved): the real data is already in account A,
and the iPhone's signed-out store is empty, so there is no reset and no copy.
Copying the empty device data would have wiped A.

Before tests, A held 7 accounts, 13 categories, 17 transactions and 7
monthly plans (the iPhone's copy from 3:41 pm, kept in
`~/Downloads/fundly-iphone-backup-1.1.0-2026-11-23/`). The row 10 restore
put that data back with new IDs, and the leftover test records were deleted
afterwards. On 2026-11-23 the agent found A identical to it, field by field
(IDs aside).

Start only when every other row has passed.

1. On the iPhone (1.2.0 (3)), signed in as A, wait for "Up to date".
2. The agent copies the iPhone's synced store off the phone and compares it
   with the before-tests copy, field by field.
3. Compare balances, the Spending tab and Plans on the iPhone with Chrome.
4. The agent reads the server's counts for A (read only).

Expected: A holds exactly the real data from before testing, the same on the
iPhone, in Chrome and on the server, with nothing waiting or refused.

Result: Pass (2026-11-23). After rows 1b and 4 and the clean-up, the iPhone (signed in as A, copied off the phone with `devicectl`) is identical, field by field and IDs aside, to the before-tests copy: 7 accounts, 13 categories, 17 transactions, 7 monthly plans, 0 custom account types; nothing waiting or refused. The server holds the same counts for A, and the same transaction amount total (₱44,253.06). The owner compared the iPhone with Chrome in row 1b.

## Sign-off

| | |
|---|---|
| Rows passed | All: 0, 1, 1b, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 (Part 1 on the simulator and Chrome, Part 2 on the iPhone) |
| Failures and fix tasks | None so far. Follow-up (row 5): refused delete cards do not say which record |
| Owner sign-off (release 1.2.0) | Signed off 2026-11-23 |
