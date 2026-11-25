# Banks on accounts (plan)

Date: 2026-11-25

Status: **approved 2026-11-25** (B-1 to B-9, all as recommended). **B.1
(server) done 2026-11-25 and deployed by the owner the same day** (migration,
publication, sync config; see [B.1 outcome](#b1-outcome)). **B.2 (app data)**
and **B.3 (UI) done 2026-11-25, not released**; see
[B.2 outcome](#b2-outcome) and [B.3 outcome](#b3-outcome). The agent stops after each
step, never commits or pushes, and does not touch production. Production
migrations, sync-config deploys and pushes to `main` are run by the owner.

## Goal

When creating or editing an account, the user picks the bank it belongs to
from a list of major Philippine banks, adds their own bank if it is missing,
or chooses No bank. The Account tab shows the bank's logo beside the account
name.

This is presentation metadata only. It changes no balance, total, Ready to
assign or transaction rule (CLAUDE.md §4).

## Decisions

| # | Decision | Status |
|---|---|---|
| B-1 | Built-in banks are a fixed list in code: BDO, BPI, Metrobank, Land Bank, PNB, Security Bank, UnionBank, RCBC, China Bank, EastWest, GCash, Maya, GoTyme, SeaBank, CIMB, Tonik. Each has a stable key (`bdo`, `bpi`, `metrobank`, `landbank`, `pnb`, `securitybank`, `unionbank`, `rcbc`, `chinabank`, `eastwest`, `gcash`, `maya`, `gotyme`, `seabank`, `cimb`, `tonik`), a display name, a monogram (2–3 letters) and a badge colour | Agreed |
| B-2 | Logos start as monograms drawn in code (initials on a coloured circle). Real logo files can be added later at `assets/images/banks/<key>.png` and are used when present, with no data change | Agreed |
| B-3 | Every account type can have a bank: Savings/Cash, Credit, Loan and custom types | Agreed |
| B-4 | The bank is optional (No bank, e.g. a cash wallet) and can be changed or cleared when editing. Accounts with no bank show an icon for their type | Agreed |
| B-5 | Custom banks follow the custom account type rules: name trimmed, 1–40 characters, unique ignoring case, cannot reuse a built-in bank's name; can be renamed; deleted only when no account (archived included) uses them. One list per space. They show a monogram from their name, with a colour picked from a fixed palette by name | Agreed |
| B-6 | Starting list as in B-1 | Agreed |
| B-7 | **Account names stay unique ignoring case**, as today. Choosing BDO then typing "Savings" is fine, but a second "Savings" under BPI is refused ("BPI Savings" works). Relaxing this would change the server constraint and make pickers ambiguous, so it is not proposed | Agreed |
| B-8 | **Where custom banks are managed:** "Add a bank…" at the end of the bank picker creates one inline; a Banks screen (Account tab ⋮ menu, next to Account types) lists, renames and deletes them | Agreed |
| B-9 | **Logos shown on:** the Account tab list, Archived accounts and the account detail header. Transaction forms, pickers and lists are unchanged in this slice | Agreed |

## Data model

An account has **at most one** of:

- `bank_key`: a built-in bank key (text), or
- `custom_bank_id`: a reference to a `custom_banks` row, with delete restricted.

Both empty means No bank. This mirrors how `type` and `custom_type_id` work.

Unknown keys: an app that doesn't know a key (an older app, after a later
release adds banks) shows the account as No bank. The local database and the
server check only the key's format (`^[a-z0-9]{1,32}$`). The app's data layer
checks it against the list in B-1, so adding a bank later needs no migration.

### Local (signed out): schema v14 → v15

- New table `custom_banks`: `id`, `name` (`UNIQUE COLLATE NOCASE`, 1–40),
  `created_at`.
- `accounts` gains `bank_key TEXT NULL` and `custom_bank_id INTEGER NULL
  REFERENCES custom_banks(id) ON DELETE RESTRICT`, with
  `CHECK (bank_key IS NULL OR custom_bank_id IS NULL)`.
- Existing accounts get No bank. Migration test: v14 data survives unchanged,
  and every account has null bank fields.

### Synced store: synced v5 → v6

- `SyncedCustomBanks` (`id`, `name`, `created_at`, `updated_at`, `revision`);
  `SyncedAccounts` gains `bank_key` and `custom_bank_id`.
- PowerSync schema in [powersync_store.dart](../lib/core/sync/powersync_store.dart)
  and the label lookup in [sync_rejections.dart](../lib/core/sync/sync_rejections.dart)
  gain `custom_banks`.

### Server: migration `20261126010000_banks.sql` (additive)

- `public.custom_banks`, with `space_id`, `created_by`, `updated_by` and
  per-space RLS like `custom_account_types`. Name unique per space ignoring
  case, and not a built-in name.
- `public.accounts` gains `bank_key` (format check) and `custom_bank_id`
  (same-space foreign key, restrict), plus the "not both" check.
- Write API: new `bank.create`, `bank.update` and `bank.delete` operations,
  with the same role rules as `custom_type.*` (owner and editor, not viewer).
  `account.create` and `account.update` accept optional `bank_key` and
  `custom_bank_id`. `account.update` stays a partial update, so apps 1.2–1.4,
  which never send these fields, keep an account's bank when they edit it.
- Sync protocol: `custom_banks` joins the entity list (receipts, deleted
  records, revision lookup). The publication adds the table.
- Dataset import and reset: `custom_banks` key and the account fields,
  optional for older payloads. Reset deletes custom banks.
- Rollback script `supabase/rollback/20261126_banks_rollback.sql`, rehearsed
  locally.
- Docs: `ACCOUNT_API.md`, `IMPORT_API.md`, `README.md`.

### Sync config

- `fundly_space_data`: add a `custom_banks` query (same membership filter) and
  add `bank_key` and `custom_bank_id` to the `accounts` query.
- `fundly_user_data` (apps 1.2.x) is unchanged.
- Older 1.3/1.4 apps receive the extra columns and table and ignore them.
  The minimum supported version stays 1.2.0.

### Backup: format 8 → 9

- Adds `customBanks` (`id`, `name`, `createdAt`) and account `bankKey` and
  `customBankId`, written as text IDs like format 7.
- Restore accepts formats 1–9. Older formats restore with No bank on every
  account.
- Checks:
  - known `bankKey`
  - `customBankId` refers to a backup row
  - not both set
  - custom bank name rules
- Signed-out device copy and signed-in restore carry banks.
- Apps 1.4.0 and older refuse format 9 files.

## App changes

- **Domain** (`lib/features/accounts/domain/`):
  - `bank.dart`: the built-in list (B-1) and lookup by key.
  - `custom_bank.dart` and `custom_bank_rules.dart`: name rules (B-5).
  - `Account` gains `bankKey` and `customBankId`. `copyWith` can set or clear
    them.
- **Data:**
  - `custom_bank_repository.dart` (local) and a synced counterpart.
  - Account repositories save and validate the bank fields: the bank exists,
    the key is known, and not both are set.
- **Presentation:**
  - Account form: a **Bank** field between Type and Name. It opens a
    searchable list of built-in banks with their monograms, then custom
    banks, then "Add a bank…" and "No bank".
  - `BankAvatar` widget: logo asset if present, else a monogram, else the
    type icon.
  - Account list rows, Archived accounts and the detail header show it.
  - Banks screen (B-8).

## Steps

Each step builds, passes its tests, and stops for review.

1. **B.1 Server.** Migration, rollback, pgTAP tests and doc updates, run on the
   local stack. Owner applies the migration to production (additive and safe
   for current apps).
2. **B.2 App data.** Schema v15, synced v6, repositories, backup format 9 and
   import, plus tests. No UI.
3. **B.3 UI.** Bank picker, monograms, Banks screen and list logos, plus widget
   tests.
4. **B.4 Release 1.5.0 (7).** `RELEASE_CHECKLIST_1.5.0.md`: server migration
   (already live from B.1), then the sync-config deploy, then the iPhone build
   and the push to `main` (the web deploys from it). Then update CLAUDE.md,
   AGENTS.md and the roadmap.

Starts after the 1.4.0 checklist is signed off, so the two releases don't
overlap.

## Tests

- **Domain:**
  - built-in keys are unique
  - custom bank name rules, including a built-in name clash ignoring case
  - an account cannot have both a key and a custom bank
- **Repositories (local and synced):**
  - create, edit, clear and switch banks
  - an unknown key is refused
  - a custom bank in use cannot be deleted, including by archived accounts
  - rename
  - balances unchanged by bank edits
- **Migrations:** app v14→v15 and synced v5→v6 keep all data, and accounts get
  No bank.
- **Backup:**
  - format 9 round trip
  - formats 1–8 still restore
  - invalid references or keys refused with no changes
- **Server (pgTAP):**
  - RLS per space
  - viewer refused
  - `account.update` without bank fields keeps the bank
  - cross-space `custom_bank_id` refused
  - delete in use refused
  - import and reset
- **Contract:** `client_contract_test` (Dart and Python) includes the new table
  and columns.
- **Widgets:**
  - picking a bank fills the account
  - "Add a bank…" creates one and selects it
  - the list shows the monogram
  - No bank shows the type icon

## B.1 outcome

Files:
- `supabase/migrations/20261126010000_banks.sql`
- `supabase/rollback/20261126_banks_rollback.sql`
- `supabase/tests/database/banks_test.sql` (69 assertions)
- `supabase/tests/migration/banks_rollback_test.py`
- `powersync/sync-config.yaml`
- `powersync/publication.sql`
- `supabase/ACCOUNT_API.md`, `supabase/IMPORT_API.md` and `supabase/README.md`

Two existing tests now expect `custom_banks` in import counts:
`dataset_import_test.sql` and `client_contract_test.py`.

One refinement of the plan: the two bank fields are set together. When an
`account.update` carries either field, the account's bank becomes exactly what
is sent, so switching banks needs one field and clearing needs
`{"bank_key": null}`. An update without either field keeps the bank.

**Deploy order (owner):**
1. Apply the migration. It is additive and safe for apps 1.2–1.4.
2. Run `publication.sql`. It should list eight tables.
3. Deploy `sync-config.yaml` in the dashboard. Apps before 1.5.0 ignore the
   new table and columns.

These can wait for B.4 or go earlier. The app needs all three before 1.5.0
ships.

**Verification (local stack, 2026-11-25):**
- pgTAP: 1161 assertions, of which 4 fail outside a transaction.
  - The 4 failures are row counts across the whole database: test 1 and 98
    in `schema_test.sql`, test 71 and 101 in `dataset_import_test.sql`.
  - They fail because the local database holds leftover rows from the local
    PowerSync users.
  - Both files pass in full (173/173 and 103/103) when those rows are deleted
    inside a rolled-back transaction.
- `db lint`: clean.
- The 8 concurrency suites pass.
- `client_contract_test.py`: 14/14.
- `banks_rollback_test.py`: 7/7.
- With the new config, the local PowerSync replicates `custom_banks`, and
  `fundly_stream_test.dart`, `c2_space_streams_test.dart` and
  `c3_sharing_streams_test.dart` pass.
- Not checked live: a stream check that `custom_banks` reaches only its
  space's members. It needs the client schema, so it comes in B.2.

## B.2 outcome

There is no UI yet, so nothing changes on screen.

**Domain** (`lib/features/accounts/domain/`):
- `bank.dart`: the 16 built-in banks, lookup by key, and the built-in name
  check.
- `custom_bank.dart`: custom banks and their validation errors.
- `Account` gains `bankKey`, `customBankId` and `bank`.

**Storage:**
- Local schema v15 adds `custom_banks` and the two account columns. The key's
  shape uses GLOB, since SQLite has no regular expressions. "One bank" and the
  foreign key are column checks, so the migration can add them.
- Synced schema v6 adds the same table and columns, with a deferred foreign
  key. Upgrading re-applies accounts, and any custom banks only PowerSync's
  log holds (from an older app), from that log.
- PowerSync's raw tables now include `custom_banks`.

**Repositories:**
- `CustomBankRepository` and `SyncedCustomBankRepository` add, rename and
  delete banks. They queue `bank.create`, `bank.update` and `bank.delete`.
- The account repositories take `bankKey` or `customBankId` on create, and
  `bank:` on update.
  - The synced one sends both fields only when the bank changes.
  - Unknown keys, a missing custom bank, or two banks are refused as
    programming errors.
- The provider is `customBankRepositoryProvider`.

**Backup format 9:**
- Adds `customBanks`, plus account `bankKey` and `customBankId`.
- Restore accepts formats 1–9; formats 1–8 restore with no banks.
- `BackupCounts.customBanks` counts custom banks.

**Requests sent to the server:**
- Copy, restore and reset send `custom_banks`, its expected count, and the
  account bank fields (only when set).
- The app reads a missing `custom_banks` count as 0.

**Refused changes:**
- Bank changes are undone and labelled: "Add bank", "Rename bank" and
  "Delete bank".
- The account's bank shows as one detail line.
- `custom_bank_in_use` reads as still in use.

**Tests:**
- New:
  - the bank domain, including a check that the names match the server's
    list
  - local and synced repositories
  - v14→v15 and v5→v6 data-integrity migrations, plus marking rows to
    re-apply from the log
  - format 9 restore and refusals
  - the copy request and comparison
  - refused-change wording
  - a real-PowerSync check that a custom bank downloads, and that a refused
    rename and delete are named and undone
- The client contract records 55 batches, including the bank session.
- Totals:
  - `flutter test`: 1511 passed.
  - `flutter analyze`: clean.
  - `client_contract_test.py`: 14/14 against the local server.
- Not checked: replaying custom banks from the log on a real store upgraded
  from 1.4.0. The unit test checks that the rows are marked. The mechanism is
  the one refused changes already rely on.

**Do not push to `main` before B.4.**
- Every push deploys the web.
- Its exports would be format 9, which apps 1.4.0 and older cannot restore.

## B.3 outcome

Done 2026-11-25, not released. No schema, backup, server or sync change.

- **Account form:** a **Bank** field between Type and Name, showing the
  chosen bank's logo and name, or "No bank". Tapping it opens a bottom sheet
  with:
  - a search field
  - the 16 built-in banks
  - "Your banks"
  - "Add a bank…" (a dialog that saves the bank and selects it)
  - "No bank"

  The Name hint follows the bank (e.g. "e.g. GCash Savings").
- **Editing:** an unchanged bank is not sent, so an account keeps a key from
  a later app, which shows as No bank. Picking another bank or No bank sends
  the change.
- **Logos** (`bank_display.dart`):
  - Built-in banks have a fixed monogram (2–3 letters) and colour.
  - Custom banks have initials, with a colour from an 8-colour palette chosen
    by the name, ignoring case.
  - A test checks that white initials meet 4.5:1 contrast on every colour.
  - Without a bank, an account shows its type's icon: wallet, card or loan.
  - Shown on the Account tab rows, Archived accounts and the account detail
    header (logo plus bank name, or "No bank").
- **Banks screen:**
  - Lists the user's banks with logo and account count, archived accounts
    included.
  - Add, rename, and delete after confirming, only while no account uses the
    bank.
  - Built-in banks are not listed. The empty state says they are already in
    the picker.
- **Where Banks opens:** the Account tab has no ⋮ menu, so B-8's "⋮ menu" is
  an app-bar button (bank icon, tooltip "Banks") next to Account types.
- **Logo files (B-2), added the same day at the owner's request:**
  - A 192 px square PNG per built-in bank at `assets/images/banks/<key>.png`
    (224 KB in all), listed in `pubspec.yaml`.
  - Cropped from a screenshot of the banks' logos the owner supplied: the
    symbol where the bank has one (e.g. Metrobank's globe, UnionBank's UB),
    otherwise the wordmark. Padded to fit a circle, on white, except
    UnionBank and CIMB, which fill the circle with their colour.
  - `BankAvatar` draws the image clipped to a circle, with a hairline so
    white logos show on white. If the image fails to load, it shows the
    monogram. Custom banks keep their monograms.
  - The quality is limited by the screenshot: Land Bank's top gear teeth
    were already cut off, and Metrobank has a faint grey edge. Official
    files can replace any image with no code change.
  - The logos are the banks' trademarks, used to identify each bank. Fine
    for personal use. Check each bank's brand rules before a public store
    release.
  - A test checks that every built-in key has a 192 × 192 PNG and that the
    folder is bundled.
- **Tests:**
  - New: `bank_display_test.dart`, `banks_screen_test.dart`,
    `bank_logos_test.dart`, and a bank group in
    `account_form_screen_test.dart` (search, built-in, custom, add, refused
    name, keep, switch, clear, unknown key).
  - Helpers: `FakeCustomBankRepository`; `fakeAccounts` and
    `fakeCustomBanks` override the custom banks.
  - The form's Save button now sits below the 600 px test screen, so the
    form test helper scrolls it into view.
  - Totals: `flutter test` 1545 passed (with the logo tests); `flutter analyze` clean.
- **Not checked:** how it looks on the iPhone or in Chrome (only widget
  tests ran).

**Do not push to `main` before B.4** (same reason as B.2).

## Not in this slice

- Real logo image files (B-2).
- Bank logos on transaction forms and lists.
- Grouping or totals by bank.
- Bank-specific behaviour of any kind (no syncing, imports or links).
