# Fundly — Delivery Roadmap

> Companion to [CLAUDE.md](../CLAUDE.md). CLAUDE.md says **what** and **why**;
> this file breaks the work into tasks small enough for one AIDD session each.
> Nothing in section 2 is approved until it is recorded in the CLAUDE.md
> Product Decisions Log.

Last updated: 2026-11-17

---

## 0. Where we are

| Item | State |
|---|---|
| Flutter / Dart | 3.47.9 stable / Dart 3.13.7 |
| Roadmap | **Phases 0–4 done** (MVP delivered), plus the post-MVP refinements below. Phase 5: **5.1 backup export and 5.2 restore done**. **Cloud sync released as 1.2.0 (3)** on 2026-11-23 (`docs/CLOUD_SYNC_PLAN.md`, S1–S7). Approved next: F.1, then planning shared spaces C0 |
| Platforms | iOS (primary), Android best-effort |
| Dependencies | drift + drift_flutter (SQLite), flutter_riverpod, intl, share_plus (share sheet for backups), file_picker (choosing a backup to restore); dev: drift_dev, build_runner, flutter_lints |
| Database | Schema **v13** on the device; signed in, a synced store per user (Supabase + PowerSync). Tables: accounts (any number of budget accounts), custom_account_types, categories, transactions, monthly_plans; migration tests for every step |
| Git | One commit per task on `main` |
| Tests | Domain, repository, migration and widget tests; all passing |

---

## 1. Gaps and conflicts found in CLAUDE.md

These needed a decision before the phase that depended on them. **All are
resolved:** G1 and G4–G9 follow the proposed resolutions and are logged in
CLAUDE.md §11; G2 and G3 were settled by D1 and D2; G11 was done in task 0.1.
G10 is resolved: backups can be exported (5.1) and restored (5.2).

| # | Issue | Affects | Proposed resolution |
|---|---|---|---|
| G1 | Spending requires a **category** (Phase 2), and Phase 3 filters by category, but categories are only defined in **Phase 4**. | Phase 2 | Add a small **seeded category list** (fixed names) in Phase 2. Phase 4 adds create/rename/archive. |
| G2 | No **sign convention** for liabilities is chosen. | Phase 1 | See D1. |
| G3 | "Available money" is mentioned but not defined. | Phase 3 | See D2. |
| G4 | **Loan** accounts have no defined transactions. How is a loan payment recorded? | Phase 2 | Treat a loan payment as a **Transfer** from an asset account to the loan. Interest is out of scope. |
| G5 | Is a Transfer into a Credit account allowed, or must it be a Credit Card Payment? | Phase 2 | Destination is Credit → it must be a **Credit Card Payment**. Transfer is for all other pairs. Both have the same balance effect, so this only affects labels and reports. |
| G6 | Currency is per account, but conversion is out of scope. | Phase 1–3 | MVP: every account is **PHP**. Store the currency code, but don't allow changing it yet. Transfers between accounts with different currencies are rejected. |
| G7 | Behaviour of archived accounts is not defined. | Phase 1 | Archived accounts can't receive new transactions, are hidden from pickers and the summary, and keep their history. **Accounts that have transactions are never hard-deleted.** Archived accounts with no transactions can be deleted permanently (2026-11-17). |
| G8 | Can a transaction's **type** change when it is edited? | Phase 2 | MVP: **no**. To change the type, delete the transaction and create a new one. This keeps validation simple. |
| G9 | The transaction **date** and the created/updated **timestamps** are mixed together. | Phase 2 | The transaction date is a **local calendar date** (no time). Audit timestamps are UTC instants. |
| G10 | The app stores data on the device only, so uninstalling or losing the phone **loses all data**. | Long-term | Resolved: JSON backup export (5.1) and restore (5.2), both 2026-11-17. |
| G11 | There is no git repo, so you can't review AI changes as diffs. | Phase 0 | Run `git init` first. Make one commit per task. |

---

## 2. Decisions needed

Each decision has a recommendation. Once you confirm one, log it in CLAUDE.md §11.

**All of D1–D7 are confirmed** as recommended and logged in CLAUDE.md §11.
For D6 the answer was iOS; the theme seed is teal.

### D1 — Balance sign convention (needed before Phase 1)

**Recommendation: signed balances from the user's point of view.**

- Every account stores a signed balance in integer centavos.
- Asset accounts (Savings/Cash) are usually ≥ 0. Liability accounts (Credit,
  Loan) are usually ≤ 0, and a negative balance means money owed.
- The user always enters a **positive** amount. The transaction type and the
  account role decide the sign.
- The UI shows balances signed: money owed as "-₱X" in the default text
  colour, positive balances in green (changed 2026-11-17 from "Owed ₱X";
  see CLAUDE.md §11). The domain layer never flips signs per account type.

| Transaction | Source account | Destination account | Counted as spending | Counted as inflow |
|---|---|---|---|---|
| Spending | −amount | — | ✅ | — |
| Inflow | — | +amount | — | ✅ |
| Transfer | −amount | +amount | — | — |
| Credit Card Payment | −amount (asset) | +amount (credit, so less is owed) | — | — |

With this table, a single function covers every account type:
`balance = opening + Σ(effects)`.
- A card purchase is Spending on the credit account. The balance becomes more
  negative, so more is owed, and it is counted as spending once (rule 6).
- A card refund is an Inflow to the credit account, so less is owed.

The opening balance is entered as a positive amount ("amount owed" for
liabilities) and stored with the sign for its account type.

### D2 — Meaning of "Available money" (needed before Phase 3)

**Recommendation:** Available money = the sum of balances of **active
Savings/Cash** accounts. Show "Credit owed" and "Loans owed" as separate
figures next to it. Net worth is out of scope.

### D3 — Persistence (needed before Phase 1)

**Recommendation: `drift` (SQLite).**
- Relational data: accounts ↔ transactions with foreign keys.
- Typed queries and reactive streams.
- **Versioned schema migrations, with tests.** This matters because the data
  is real and lives only on your device.
- Works in-memory in tests.
- Cost: code generation (`build_runner`).

Alternatives: `sqflite` gives raw SQL with no codegen but is more manual and
has no type safety. Hive/Isar don't fit relational, integrity-sensitive data
as well. Check pub.dev for current versions and maintenance status before
adding anything.

### D4 — State management (needed before Phase 1)

**Recommendation: `flutter_riverpod`, written by hand without codegen.**
Repositories are exposed as providers, and screens watch streams from drift.
It is easy to override in tests and it is the most common choice, which helps
AI-generated code stay idiomatic.

Lighter alternative: `provider` + `ChangeNotifier`. It is fine at this size,
but you would need to reinvent async and loading states.

### D5 — Navigation (Phase 0)

**Recommendation:** use Material 3 `NavigationBar` + `IndexedStack` and plain
`Navigator` pushes for detail screens. Skip `go_router` until deep links are
needed (YAGNI).

### D6 — Target device for daily use (Phase 0)

Which do you use every day, iOS or Android? Build and test on that device
first, and treat the other as best-effort.

### D7 — IDs

**Recommendation:** use SQLite auto-increment integer IDs. UUIDs are only
needed for sync, which is out of scope.

---

## 3. Milestones and tasks

Rules for every task:
- One task per AIDD prompt, using the template in CLAUDE.md §8.
- One commit per task.
- Run `dart format .`, `flutter analyze` and `flutter test` before marking a
  task done.

Size: **S** ≈ one short session, **M** ≈ one longer session or two.

### Phase 0 — Foundation — ✅ Done (2026-11-16)

Done *when the app launches with 3 navigable tabs*.

| ID | Task | Size | Done when |
|---|---|---|---|
| 0.1 | `git init` and check `.gitignore` (exclude `build/`, `.dart_tool/`, `.idea/` as needed); initial commit | S | Clean `git status` |
| 0.2 | Replace the counter app: `main.dart` → `app/app.dart`, feature-first folders (only the ones in use now) | S | App runs; analyze is clean |
| 0.3 | Navigation shell: Spending / Plans / Account tabs with placeholder screens | S | A widget test switches between all 3 tabs |
| 0.4 | Theme: M3 `ColorScheme.fromSeed`, light + dark, spacing constants | S | Both themes render |
| 0.5 | Make lints stricter (e.g. `prefer_const_constructors`, `always_declare_return_types`); write the README with setup, run and test commands | S | `flutter analyze` is clean |

### Phase 1 — Accounts — ✅ Done (2026-11-16)

Done *when you can create and view accounts and balances come from the opening balance*.

Before you start, confirm D1, D3, D4 and G6–G7 and log them.

| ID | Task | Size | Done when |
|---|---|---|---|
| 1.1 | `core/money`: a `Money` value object (int minor units + currency code), parsing user input, formatting with `intl` | M | Unit tests: parsing (`"1,234.50"` → 123450), rounding/rejection of >2 decimals, negative/zero rejection, formatting |
| 1.2 | Account domain: `AccountType` enum, `Account` model, validation (non-empty name, opening balance sign per D1) | S | Unit tests |
| 1.3 | Add dependencies (drift + riverpod), DB setup, `accounts` table, schema v1, `AccountRepository` | M | Repository tests on in-memory DB |
| 1.4 | Account list screen (grouped by type, shows the balance) with an empty state | S | Widget test: empty and populated |
| 1.5 | Create/edit account form (name, type, opening balance); type is locked after creation | M | Widget test: validation errors and successful save |
| 1.6 | Account detail screen (balance, metadata); archive with confirmation if balance ≠ 0 | S | Tests for the archive rule |

**Balance source of truth:** In Phase 1 the balance is the opening balance.
Task 2.4 replaces this with `opening + Σ effects` in **one** domain function.
Screens never compute balances themselves.

### Phase 2 — Transactions — ✅ Done (2026-11-16)

Done *when all 4 types are recorded with correct balances*.

Before you start, confirm G1, G4, G5, G8 and G9.

| ID | Task | Size | Done when |
|---|---|---|---|
| 2.1 | Seeded categories table (fixed list, e.g. Food, Transport, Utilities, Subscriptions, Shopping, Health, Other) + schema migration v1→v2 **with a migration test** | S | Migration test passes |
| 2.2 | Transaction domain model + validators for all 4 types (positive amount, source ≠ destination, required fields per type, active accounts only, same currency, CC payment destination must be Credit) | M | One test per CLAUDE.md §4 rule that applies |
| 2.3 | `transactions` table (FKs to accounts and categories) + repository (create, update, delete, list by account/date) | M | Repository tests |
| 2.4 | **Balance calculator** (a pure function) wired into the account screens | M | Tests: every row of the D1 table, an edit that changes the amount or account, delete, a multi-transaction scenario |
| 2.5 | Add-transaction flow: type picker → Spending and Inflow forms | M | Widget tests |
| 2.6 | Transfer and Credit Card Payment forms (account pickers filtered by rule) | M | Widget tests including the self-transfer rejection |
| 2.7 | Transaction list (on the account detail screen + all transactions) and a detail view | M | Widget test |
| 2.8 | Edit and delete with confirmation; balances update automatically through the streams | S | Tests: balance after edit/delete |

### Phase 3 — Spending overview — ✅ Done (2026-11-16)

Done *when dashboard totals match the records*.

Before you start, confirm D2.

| ID | Task | Size | Done when |
|---|---|---|---|
| 3.1 | `PeriodSummary` domain service: inflow total and spending total for a local-date range, **excluding transfers and CC payments** | M | Unit tests, including dates at the boundary and the excluded types |
| 3.2 | Summary cards: Available money, Credit owed, Loans owed, Inflow and Spending for the period | S | Widget test |
| 3.3 | Period selector (this month / last month / custom range) | S | Widget test |
| 3.4 | Recent transactions (latest 10) + "See all" | S | — |
| 3.5 | Filters on the all-transactions list: date range, account, category | M | Tests for the filter query |

### Phase 4 — Basic Plans — ✅ Done (2026-11-16)

Done *when you can compare a monthly plan with actual spending*.

| ID | Task | Size | Done when |
|---|---|---|---|
| 4.1 | Manage categories: add, rename, archive (no hard delete while transactions use the category) | S | Tests |
| 4.2 | `monthly_plans` table (month, category, planned amount) + migration test | S | Migration test |
| 4.3 | Plan calculator: planned vs actual (Spending only) vs remaining, per category per month | M | Unit tests |
| 4.4 | Plans screen: month selector, a row per category, edit the planned amount | M | Widget test |

### Post-MVP refinements — ✅ Done (2026-11-17)

Requested by the product owner after the MVP and logged in CLAUDE.md §11.

| ID | Task | Schema | Done when |
|---|---|---|---|
| R.1 | Spending tab list follows the period: 10 newest overall for This month, only that period's 10 newest otherwise; See all opens All transactions pre-filtered | — | Widget tests |
| R.2 | Plans: Target (optional), Assigned, Activity, Available and Funded / Underfunded status per category per month; existing plans became Target = Assigned | v6 | Migration, calculator and widget tests |
| R.3 | Plans quick edit: tap Target or Assigned to edit just that amount; Activity opens that month's transactions | — | Widget tests |
| R.4 | Zero amounts in input fields are placeholders, not values | — | Widget tests |
| R.5 | Account tab: collapsible section per account type with its total | — | Widget tests |
| R.6 | Balances shown signed: owed as -₱X in the default colour, positive in green (`AppColors` theme extension) | — | Widget tests |
| R.7 | Custom account types, each an Asset or a Liability that works like a credit card or a loan; accounts store the base type, so no rule changes | v7 | Migration and repository tests |
| R.8 | Account tab grouped under Assets and Liabilities; type dropdown with "New account type…" in the account form | — | Widget tests |
| R.9 | Account types screen: rename, change class while unused, delete when unused | — | Repository and widget tests |
| R.10 | Archived accounts with no transactions can be deleted permanently (button below Unarchive account) | — | Repository and widget tests |
| R.11 | Plans groups: each spending category is in Spending, Savings or Liability (fixed list), set in the category form; Plans shows a section per group. Backup format 2 adds `planGroup` | v8 | Migration, repository, backup and widget tests |
| R.12 | Ready to assign on Plans: live budget-account balance including opening money minus the selected month’s remaining allocations; each category reserves max(Assigned − that month’s Spending from the budget account, 0); other-account spending does not release allocations; no allocation carry-over; red warning when overallocated, saving allowed | — | Calculator and widget tests |
| R.13 | Budget account: one active Savings/Cash account (custom asset types included) can be tagged in the account form; moving the tag asks first; archiving removes it. Backup format 3 adds `isBudgetAccount` | v9 | Migration, repository, backup and widget tests |
| R.14 | New default spending categories; keep existing data and add missing defaults on upgrade. Auto-create linked Liability Plans rows for Credit/Loan accounts, synchronize names/archive status, count payments as Activity, release remaining allocations only for payments from the budget account. Backup format 4 adds linkedAccountId; older formats remain restorable | v10 | Migration, repository, calculator, backup and widget tests |
| R.15 | Archive Plans rows independently across all months, hide archived rows from Plans, and browse read-only history/unarchive from Archived plans. Block archive when any current/future month has remaining budget allocation. Backup format 5 adds isPlanArchived; earlier formats default false | v11 | Migration, repository, archive guard, backup and widget tests |
| R.16 | Automatic budget-money carry-over: show the previous closing ledger balance in Plans without adding a transaction or duplicating money. Refresh at local midnight and on resume/open; catch up missed months while preserving browsed months. Category allocations stay monthly; edits recalculate carry-over | — | Calculator, month-boundary and lifecycle widget tests |
| R.17 | Permanently delete unused archived Plans rows: zero Assigned in every month, no spending/payment activity, confirmation, and a red button below Unarchive. Remove monthly targets while keeping category/account; a persistent deletion flag prevents automatic recreation. Backup format 6 adds isPlanDeleted; earlier formats default false | v12 | Migration, eligibility, atomic deletion/rollback, backup and widget tests |

### Phase 5 — After the MVP (one item approved)

| ID | Task | Status |
|---|---|---|
| 5.1 | JSON backup export: Account tab ⋮ → Export backup; versioned JSON (now format 7) of every record, shared through the system share sheet (`share_plus`) | ✅ Done (2026-11-17) |
| 5.2 | JSON restore: Account tab ⋮ → Restore from backup; pick a file (`file_picker`), check it fully, confirm with counts (option to export current data first), replace all data in one transaction | ✅ Done (2026-11-17) |
| 5.3 | CSV export of transactions | Proposed |

### After the 1.2.0 release (1.2.0 signed off 2026-11-23)

| ID | Task | Status |
|---|---|---|
| F.1 | Name the record on refused-change cards (S7.2 row 5 follow-up) | ✅ Built 2026-11-23 as 1.2.1 (4); deploy per `docs/OPERATIONS.md` (web, then iPhone) |

F.1 plan, approved 2026-11-23 with all three decisions as recommended:

- **Problem:** a refused delete card reads only "Delete transaction" (also
  account, category and account type deletes). Labels are read from the
  device's tables when the refusal is recorded, and a delete has already
  removed the row.
- **Fix:** in `_labels` (`lib/core/sync/sync_rejections.dart`), when an ID is
  not in the device's tables, read its name or payee from PowerSync's
  download log (`ps_oplog`), which keeps the server's copy until the server
  confirms the delete. Row 5's card becomes "Delete transaction · Edit".
- **Transactions without a payee** (Decision F.1-2): label by type, amount
  and date, for example "Transfer ₱2,600.00 · Nov 10", for every refused
  transaction card, edits included.
- **Delete cards keep no detail lines** (Decision F.1-3): the record comes
  back, so there is nothing to redo.
- **Timing** (Decision F.1-1): after the 1.2.0 sign-off, released as
  1.2.1 (4), so Part 2 tests the same app as Part 1.
- No schema, backup format, server or protocol change. Cards already
  recorded keep their labels.
- Tests: `batch_uploader_test.dart` (transaction and account delete labels
  from the download log; an ID found nowhere gets none) and
  `refused_change_description_test.dart` (delete title with the label;
  payee-less label). Then format, analyze and the full Flutter suite.

Backup format 6: a header (`app`, `formatVersion`, `schemaVersion`,
`exportedAt`) and arrays `customAccountTypes`, `accounts`, `categories`,
`transactions` and `monthlyPlans`. Format 2 added `planGroup` to
categories, format 3 added `isBudgetAccount` to accounts, and format 4 adds
`linkedAccountId` to categories for automatic liability Plans rows. Format 5
adds `isPlanArchived` to categories, independent of category/account archives.
Format 6 adds `isPlanDeleted`, preserving permanent plan removal while keeping
its category/account. Restore accepts formats 1–5 as well (the deletion flag defaults
false; the archive flag defaults false for formats 1–4).
Formats 1–3 retain their previous defaults (format 1 categories default to
Spending; formats 1–2 have no budget account). Missing liability rows are
generated and included in the restore preview counts. Money is integer minor units, dates
`YYYY-MM-DD`, months `YYYY-MM`, timestamps UTC ISO-8601; IDs are kept and
derived balances are left out. Format 7 (2026-11-22, cloud sync S6.3) is
format 6 with every ID and reference written as text: UUIDs from a signed-in
account, decimal strings from this device. It is what every export writes.
On restore, text IDs (1–64 characters, unique per table) become local numbers
in file order and the format 6 checks apply; restore accepts formats 1–7.
Signed in, a restore goes into the account through the copy screen. Field names are mapped explicitly in
`BackupExporter`, so a schema change does not change the format by itself;
bump `formatVersion` when the format changes.

Restore rules: **replace, not merge**. The whole file is checked before
anything changes: header and format version (newer formats are refused),
field types, enum values, dates and UTC timestamps, PHP only, unique IDs and
names, references, account/custom-type base match, opening-balance signs,
plans on spending categories only, and every transaction against the same
rules as the app, except that archived accounts and categories may hold
history. The replace runs in one database transaction with the database's
own checks as a backstop, so a failure leaves the data unchanged. IDs and
timestamps are restored as they are; balances are recalculated.

---

## 4. Testing strategy

| Layer | Tool | What is tested |
|---|---|---|
| Domain (Money, validators, balance calculator, summaries, plans) | `test` (pure Dart) | Every rule in CLAUDE.md §4 has at least one named test |
| Data (repositories, migrations) | drift in-memory DB | CRUD, foreign keys, every schema version step |
| UI | `flutter_test` widget tests | Main flows, empty/error states, validation messages |

Suggested naming: `test/features/<feature>/<layer>/<subject>_test.dart`.
Group tests by rule number, e.g. `group('Rule 5: transfers excluded from spending', …)`.

---

## 5. Risks

| Risk | Mitigation |
|---|---|
| Data loss (data is only on the device) | Migration tests from the first schema; JSON backup export (5.1) and restore (5.2); backups are manual |
| Balance drift between screens | One balance function (2.4); screens never do arithmetic |
| Scope creep from the AI | One task per prompt; CLAUDE.md §8 "Stop" rule; one commit per task |
| Schema churn | Schema changes are always called out in the task plan before you approve it |
| Dependency churn | Few dependencies; check pub.dev maintenance before adding |

---

## 6. Next step

The MVP roadmap, the post-MVP refinements, JSON backup export and restore
(5.1, 5.2) and cloud sync (released as 1.2.0) are delivered. Approved next,
one at a time: F.1 (above), then planning shared spaces slice C0
(`docs/SHARED_SPACES_PROPOSAL.md`). The remaining Phase 5 proposal is CSV
export of transactions (5.3). Plan each task like any other: propose,
approve, then build.
