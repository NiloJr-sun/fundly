# Fundly

A personal finance and budgeting app for tracking accounts, transactions and
spending. It works offline with data on the device; signing in with Google
syncs it between the iPhone and the web app.

- Product direction and engineering rules: [CLAUDE.md](CLAUDE.md)
- Delivery plan and open decisions: [docs/ROADMAP.md](docs/ROADMAP.md)
- Guide for AI coding agents (Codex and others): [AGENTS.md](AGENTS.md)
- Deploying, rollback and backups: [docs/OPERATIONS.md](docs/OPERATIONS.md)

**Status:** Phases 0–4 are complete, so the MVP is delivered, along with
post-MVP refinements and Phase 5's JSON backup export and restore. Cloud sync
is released as version **1.2.0 (3)** (2026-11-23), the minimum supported
version. Web: <https://fundly-budget.vercel.app>. Next steps are in
[docs/ROADMAP.md](docs/ROADMAP.md).

## Features

- **Account:** create Savings/Cash, Credit and Loan accounts with an opening
  balance; view details and history; rename; archive and unarchive. Archived
  accounts with no transactions can be deleted permanently. Any number of
  asset accounts can be budget accounts ("Use as budget account" in the
  account form); money coming into them funds Ready to assign on Plans.
- **Account types:** add your own types (e.g. E-wallet, Pay later) as an
  Asset or a Liability that works like a credit card or a loan; rename them,
  change their class while unused, and delete them when unused. The Account
  tab groups accounts under Assets and Liabilities, with a collapsible
  section and total per type. Balances show signed: money owed as -₱X,
  positive amounts in green.
- **Transactions:** record Spending, Inflow, Transfer and Credit Card
  Payment; edit and delete them. A Transfer from a Credit account to a
  Savings/Cash account is a cash advance: you owe more on the card, and it is
  not counted as inflow. Balances are always derived from the opening
  balance plus transactions.
- **Spending:** Available money, Credit owed and Loans owed; inflow and
  spending totals for this month, last month or a custom range (transfers and
  card payments excluded); the 10 latest transactions; an All transactions
  list filtered by date, account and category.
- **Plans:** per spending category per month, a Target and an Assigned
  amount, the month's Activity (spending; tap to see the transactions),
  Available (Assigned − Activity) and a status: Overspent when Available is
  negative, otherwise Funded / Underfunded against the Target. Tap
  Target or Assigned to edit just that amount. Categories are listed in
  Spending, Savings and Liability sections (set the group in the category
  form). At the top, Ready to assign shows the selected month’s carry over
  plus money in (inflows into budget accounts, and transfers into them from
  other accounts), minus money
  moved out (transfers to Savings/Cash accounts) and the month’s Assigned
  total. Spending and card or loan payments do not change it; overspending
  shows as a negative Available on its row. Overallocated amounts appear in
  red; saving remains allowed. Allocations do not carry over.
  Transfers between budget accounts don’t count either way.
  “Carry over from last month” is the budget accounts’ balance on the
  month’s first day: the opening balance plus transactions dated before the
  selected month. Plans refreshes at local
  midnight while open, and catches up on the next open or resume if closed.
  Earlier transaction or opening-balance edits recalculate it; it is not a
  frozen month-end snapshot. A month you deliberately browse stays selected.
  Categories can be added, renamed, archived and deleted when unused.
  New installations start with Rent, Utilities, Internet, Subscriptions,
  Food & Groceries, Fuel and Miscellaneous; upgrades add missing defaults
  while keeping existing categories and history.
  Each active credit-card or loan account automatically gets a Liability row
  with no Target and zero Assigned. Its name follows the account, and Activity
  counts payments into it. Payments from the budget account reduce its remaining
  allocation once. Renaming or archiving the account updates its row; history
  stays available. Account rows are managed through accounts rather than Categories.
  Use a row’s ⋮ menu to archive it across all months. Archiving is blocked
  while any current or future month has remaining allocation; the message lists
  amounts to release. Past assignments do not block archiving. Archived rows
  disappear from Plans. Open Archived plans (top right) to browse monthly history
  and unarchive a row. This leaves its category/account active; if its parent is
  archived, restore that category/account first. History and budget reservations
  are retained, including after later transaction edits.
  Archived plans have a Delete permanently button below Unarchive. Deletion
  requires zero Assigned in every month and no spending/payment history for
  that row. Confirmation removes the plan and its saved targets across all
  months, while keeping its category and account. Deleted liability rows do
  not reappear when their account changes.
- **Backup:** Profile tab → Export backup creates a JSON file of all your
  records and opens the share sheet (Save to Files, AirDrop, Mail…). The file
  is plain text, so keep it private. Restore from backup picks a backup
  in Files, checks it fully, shows what it holds next to what's on the phone
  (with an option to export the current data first), and on confirmation
  replaces all data in one step. An invalid file changes nothing.
- **Sign-in and sync:** Profile → Sign in with Google keeps your records in
  your account and in sync on the iPhone and the web app. The app keeps
  working offline; changes wait and upload when you are back online. A change
  the server refuses (for example, edited on another device first) is listed
  under Refused changes. Signed-out data on a device stays separate and can be
  copied into the account once.

## Requirements

| Tool | Version |
|---|---|
| Flutter | 3.47.9 (stable) |
| Dart | 3.13.7 (bundled with Flutter) |
| Xcode | Needed for iOS. iOS is the main target device. |
| Android Studio / SDK | Optional, for Android |

Check your setup:

```bash
flutter --version
flutter doctor
```

## Setup

```bash
git clone git@github.com:NiloJr-sun/fundly.git
cd fundly
flutter pub get
```

## Code generation

The database code (`*.g.dart`) is generated by drift and committed. Regenerate
it after changing a table or the database class:

```bash
dart run build_runner build --delete-conflicting-outputs
```

After a **schema change** (bump `schemaVersion` in
`lib/core/database/app_database.dart` and add a migration), also run:

```bash
dart run drift_dev make-migrations
```

This saves a snapshot of the new schema in `drift_schemas/` and generates
migration tests in `test/drift/`.

## Run

```bash
open -a Simulator        # start an iOS simulator
flutter devices          # list available devices
flutter run              # run on the only device, or pick one with -d <id>
```

For Chrome, run `flutter run -d chrome --web-port=7357`.
Browser data is stored locally for that origin, separately from iOS data.
Keep the same port between runs to reuse it. Clearing site data removes it.
The files `web/sqlite3.wasm` and `web/drift_worker.js` come from the official
Drift 2.35.4 release; update both together when upgrading Drift.

## Before each commit

Run all three. Each must finish with no issues and no failures.

```bash
dart format .            # format code
flutter analyze          # static analysis (rules in analysis_options.yaml)
flutter test             # run all tests
```

The analyzer uses `flutter_lints`, strict type checks (`strict-casts`,
`strict-inference`, `strict-raw-types`) and a few extra rules. See
[analysis_options.yaml](analysis_options.yaml).

## Project structure

```text
lib/
  main.dart                 # entry point
  app/
    app.dart                # MaterialApp and theme setup
    home_shell.dart         # bottom navigation: Spending, Plans, Accounts,
                            # Profile
    theme/                  # AppTheme (light/dark), AppColors, Spacing
  core/
    database/               # drift AppDatabase (SQLite), migrations, converters
    formatting/             # MoneyFormatter, DateFormatter
    money/                  # Money, MoneyParser
    time/                   # CalendarDate, CalendarMonth, DateRange
    widgets/                # shared widgets
  features/
    accounts/
      data/                 # accounts and custom types tables, repositories
      domain/               # Account, AccountType, custom types, grouping,
                            # rules, balance calculator
      presentation/         # Accounts tab, account form, Account types screen
    profile/
      presentation/         # Profile tab: greeting, backups, sign-out
    categories/
      data/                 # table, seeded defaults, repository
      domain/               # Category, CategoryKind, rules
      presentation/         # Categories screen and form
    transactions/
      data/                 # table, repository
      domain/               # Transaction, effects, rules, filter
      presentation/
    spending/
      domain/               # period totals, balance summary
      presentation/         # Spending tab
    plans/
      data/                 # monthly_plans table, repository
      domain/               # MonthlyPlan, plan summaries
      presentation/         # Plans tab, Ready to assign card
    backup/
      data/                 # BackupExporter and BackupImporter: JSON backup
                            # format (version 6), checks, replace-all restore
      presentation/         # Export and restore actions, confirmation dialog
test/                       # mirrors lib/; helpers/ holds fakes and fixtures
drift_schemas/              # schema snapshot per version (currently v13)
```

Code is organised by feature. Folders for `data/` and `domain/` are added
when a feature needs them.

## Conventions

- Colours and text styles come from `Theme.of(context)`. Don't hard-code
  them in widgets. Colours the colour scheme lacks (such as the green for
  positive balances) live in the `AppColors` theme extension.
- Use `Spacing` constants (`xs`–`xl`) for padding and gaps.
- Keep business rules out of widgets.
- Money is stored as integer minor units (centavos for PHP), never `double`.
