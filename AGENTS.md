# AGENTS.md — Fundly

Entry point for AI coding agents (Codex and others). Read this first, then
the files it points to. **Every rule in [CLAUDE.md](CLAUDE.md) applies to
you**, even where it says "Claude".

| File | What it is |
|---|---|
| [CLAUDE.md](CLAUDE.md) | Product direction, accounting rules (§4), engineering standards (§7), workflow (§8), definition of done (§9), status (§10) and the **Product Decisions Log (§11)**. §11 is the source of truth for confirmed behaviour. |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Delivery history: phases 0–4, post-MVP refinements (R.1–R.17), Phase 5 (backup), backup format notes. |
| [README.md](README.md) | Setup, run, project structure, conventions. |

Last updated: 2026-11-17.

---

## 1. Working agreement with the product owner

The user is the product owner and orchestrator. They review every change.

- **One task at a time.** Finish it, verify it, report, then **stop**. Do
  not start the next task without a go-ahead.
- **Ask before** changing the database schema, persisted or backup data
  formats, financial rules (CLAUDE.md §4 and §11), architecture, or adding
  a dependency. Propose a short plan (what, files, tests, edge cases) and
  wait for approval. Small, unambiguous UI tasks can be built directly;
  state the defaults you chose.
- **Never commit or push.** Stage the task's changes with `git add` and give
  a one-line commit message the user can paste. If earlier work is still
  staged and uncommitted, leave the new work unstaged and give a separate
  message, unless the user asks to fold it in.
- **Docs:** update CLAUDE.md (including the §11 log), README and ROADMAP only
  when the user asks or approves a scope change. When you add a §11 row,
  keep the table's fixed column widths (each line of the middle column is
  at most 24 characters). If a decision replaces an earlier one, edit that
  row instead of adding a contradicting one.
- **Report honestly:** list what changed, what you verified (with the
  commands), test counts, and known limitations. Never claim tests passed
  unless you ran them.
- Out of scope until explicitly requested: everything in CLAUDE.md §6,
  authentication, cloud sync, and unapproved Phase 5 items.

## 2. Commands

Flutter 3.47.9 (stable) / Dart 3.13.7. iOS is the primary device; Android is
best-effort.

```bash
flutter pub get
dart format .                     # must leave no changes to review
flutter analyze                   # must report "No issues found!"
flutter test                      # 840 tests passing as of 2026-11-17
flutter build ios --simulator --debug
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted com.nilojr.fundly

# Code generation (drift); generated *.g.dart files are committed
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev make-migrations   # after bumping schemaVersion
dart fix --apply --code=directives_ordering   # fixes import order lints
```

Run format, analyze and the full test suite for every task, and the iOS
simulator build for anything that changes app code. macOS has no
`timeout`; `perl -e 'alarm 300; exec @ARGV' <command>` works instead.

## 3. Current state (2026-11-17)

- **Database:** drift (SQLite), **schema v12**. Tables: `accounts`
  (`custom_type_id`, `is_budget_account`), `custom_account_types`,
  `categories` (`kind`, `is_archived`, `is_plan_archived`, `is_plan_deleted`,
  `plan_group`, `linked_account_id`), `transactions`,
  `monthly_plans` (`target_amount_minor` nullable, `assigned_amount_minor`).
  Migration tests cover every upgrade path.
- **Backup format 6** (JSON export and replace-all restore from the Profile
  tab). Restore accepts formats 1–6.
- **Features delivered:** accounts with custom types (Asset, or Liability
  that works like a credit card or a loan), Assets/Liabilities grouping,
  archive/unarchive/permanent delete of unused archived accounts, one
  **budget account**; four transaction types; Spending tab with period
  totals and filters; categories with Plans groups (Spending, Savings,
  Liability); Plans with Target, Assigned, Activity, Available, Status and
  **Ready to assign** (current budget-account balance minus the selected
  month’s remaining allocations). Credit/Loan accounts automatically get a
  linked Liability Plans row; Activity counts payments into that account.
  Plans rows can be archived independently across all months, only when current
  and future remaining allocations are zero. Archived plans keeps history and
  supports unarchive; parent categories/accounts must be active first.
  Unused archived plans can be permanently deleted only with zero Assigned in
  every month and no spending/payment activity. Their categories/accounts remain;
  `is_plan_deleted` prevents unarchive and automatic row recreation.
  Plans shows reconstructed money carry-over (opening balance + transactions
  before the selected month), already included in the live balance. It refreshes
  at local midnight while open and catches up on open/resume; category
  allocations do not roll forward.
- **Nothing further is approved.** The remaining Phase 5 proposal is CSV
  export of transactions (5.3).

## 4. Where things live

Feature-first: `lib/features/<feature>/{data,domain,presentation}`, shared
code in `lib/core` and `lib/app`. Tests mirror `lib/` under `test/`.

| Concern | Location |
|---|---|
| Money, parsing, formatting | `core/money/` (`Money` = integer minor units), `core/formatting/` (`MoneyFormatter`, `DateFormatter`) |
| Dates | `core/time/` (`CalendarDate`, `CalendarMonth`, `DateRange`) |
| Database, migrations | `core/database/app_database.dart` (`schemaVersion`, `stepByStep` migrations), snapshots in `drift_schemas/`, tests in `test/drift/` |
| Balances | `accounts/domain/account_balance.dart` (`balancesFor`, `totalsByType`, `totalBalance`) |
| Account grouping | `accounts/domain/account_groups.dart` (`groupAccounts`) |
| Transaction rules | `transactions/domain/transaction_rules.dart` (`validateTransaction`, allowed account types per transaction type) |
| Spending totals | `spending/domain/period_summary.dart` (`periodTotals`, `summarizeBalances`) |
| Plans maths | `plans/domain/plan_summary.dart` (`planSummaries`, `readyToAssign`) |
| Backup | `backup/data/backup_exporter.dart`, `backup_importer.dart` (`parseBackup`, `BackupImporter.replaceAll`) |
| Theme colours outside the colour scheme | `app/theme/app_colors.dart` (`AppColors` theme extension) |

Rules that matter everywhere:

- Balances are derived from opening balance plus transactions; never store
  or compute them in widgets. Signed convention D1: liabilities are negative
  when owed.
- Never use `double` for money. Format with `MoneyFormatter`.
- State management is hand-written `flutter_riverpod` (no codegen).
  Repositories expose `watch…` streams; screens read `StreamProvider`s and
  combined `Provider<AsyncValue<…>>`s.
- Business rules live in `domain/` or the repository, never in widgets. The
  repository enforces rules and the database repeats them as CHECKs and
  foreign keys where it can.

## 5. Recipes and pitfalls learned so far

**Schema change** (needs approval first):
1. Change the table, bump `schemaVersion`, add a `fromNToM` step.
2. `dart run build_runner build …`, then `dart run drift_dev make-migrations`,
   then `build_runner` again.
3. Add a data-integrity test to `test/drift/app_database/migration_test.dart`.
4. If the change affects user data, update the backup exporter and importer,
   bump `BackupExporter.formatVersion`, and keep older formats restorable.
5. Verify on the simulator: back up `Documents/fundly.sqlite` from
   `xcrun simctl get_app_container booted com.nilojr.fundly data`, install,
   launch, then check `PRAGMA user_version`, row counts,
   `PRAGMA integrity_check` and `PRAGMA foreign_key_check`. Reinstalling
   changes the container path, so look it up again.

**Drift gotchas**
- `seedDefaultCategories` uses raw SQL so old migration steps keep working;
  don't switch it to generated companions.
- A column `.check(...)` that refers to its own column trips the
  `recursive_getters` lint. Put `// ignore: recursive_getters` on that line
  with a comment explaining it. Compare enum columns with string literals in
  checks (for example `type.equals('savingsCash')`), because the generated
  schema snapshots store them as text.
- Use `@TableIndex.sql(...)` for partial unique indexes.
- In tests, `import 'package:drift/drift.dart' hide isNotNull, isNull;`.

**Tests**
- Every repository has a fake in `test/helpers/`. When you add a repository
  method, add it to the fake too.
- Widget tests must override every provider the screen reads, normally via
  `fakeAccounts(...)` / `fakeCustomAccountTypes(...)` in
  `test/helpers/provider_overrides.dart`. If a test prints "created the
  database class AppDatabase multiple times", something is reaching the real
  database.
- The account list waits for custom types, so pump twice after the first
  frame. For long lists, set `tester.view.physicalSize` and
  `tester.view.devicePixelRatio = 1`.
- Texts such as "Spending" appear in several places (category kind, Plans
  group, section heading). Find widgets by type, not just by text.
- Dropdown items need unique, non-null values; headings use their own value
  with `enabled: false`.

## 6. Known limitations (agreed, not bugs)

- Ready to assign uses the live budget-account balance for every selected
  month, including opening money. Remaining allocations are calculated per
  category as max(Assigned minus that month’s Spending (or linked debt payments)
  from the budget account,
  0). Other-account spending does not release allocations. Monthly allocations
  do not carry over; overallocation warns but does not block saving.
- Restore replaces all data; there is no merge and no encryption. Backups
  are plain text.
- Accounts with transactions can only be archived, never deleted (G7).
- All money is PHP (G6); currency is stored but not editable.
