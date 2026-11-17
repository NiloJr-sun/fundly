# Fundly — Delivery Roadmap

> Companion to [CLAUDE.md](../CLAUDE.md). CLAUDE.md says **what** and **why**;
> this file breaks the work into tasks small enough for one AIDD session each.
> Nothing in section 2 is approved until it is recorded in the CLAUDE.md
> Product Decisions Log.

Last updated: 2026-11-16

---

## 0. Where we are

| Item | State |
|---|---|
| Flutter / Dart | 3.47.9 stable / Dart 3.13.7 |
| Roadmap | **Phases 0–4 done** (MVP delivered). Phase 5 is a proposal, not approved |
| Platforms | iOS (primary), Android best-effort |
| Dependencies | drift + drift_flutter (SQLite), flutter_riverpod, intl; dev: drift_dev, build_runner, flutter_lints |
| Database | Schema **v5**: accounts, categories, transactions, monthly_plans; migration tests for every step |
| Git | One commit per task on `main` |
| Tests | Domain, repository, migration and widget tests; all passing |

---

## 1. Gaps and conflicts found in CLAUDE.md

These needed a decision before the phase that depended on them. **All are
resolved:** G1 and G4–G9 follow the proposed resolutions and are logged in
CLAUDE.md §11; G2 and G3 were settled by D1 and D2; G11 was done in task 0.1.
G10 remains open (see Phase 5).

| # | Issue | Affects | Proposed resolution |
|---|---|---|---|
| G1 | Spending requires a **category** (Phase 2), and Phase 3 filters by category, but categories are only defined in **Phase 4**. | Phase 2 | Add a small **seeded category list** (fixed names) in Phase 2. Phase 4 adds create/rename/archive. |
| G2 | No **sign convention** for liabilities is chosen. | Phase 1 | See D1. |
| G3 | "Available money" is mentioned but not defined. | Phase 3 | See D2. |
| G4 | **Loan** accounts have no defined transactions. How is a loan payment recorded? | Phase 2 | Treat a loan payment as a **Transfer** from an asset account to the loan. Interest is out of scope. |
| G5 | Is a Transfer into a Credit account allowed, or must it be a Credit Card Payment? | Phase 2 | Destination is Credit → it must be a **Credit Card Payment**. Transfer is for all other pairs. Both have the same balance effect, so this only affects labels and reports. |
| G6 | Currency is per account, but conversion is out of scope. | Phase 1–3 | MVP: every account is **PHP**. Store the currency code, but don't allow changing it yet. Transfers between accounts with different currencies are rejected. |
| G7 | Behaviour of archived accounts is not defined. | Phase 1 | Archived accounts can't receive new transactions, are hidden from pickers and the summary, and keep their history. **Accounts that have transactions are never hard-deleted.** |
| G8 | Can a transaction's **type** change when it is edited? | Phase 2 | MVP: **no**. To change the type, delete the transaction and create a new one. This keeps validation simple. |
| G9 | The transaction **date** and the created/updated **timestamps** are mixed together. | Phase 2 | The transaction date is a **local calendar date** (no time). Audit timestamps are UTC instants. |
| G10 | The app stores data on the device only, so uninstalling or losing the phone **loses all data**. | Long-term | Not in scope yet. Suggest a JSON export/backup as the first item after the MVP (see Phase 5). |
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

### Phase 5 — Proposed for after the MVP (not approved)

- JSON export/import for backup (addresses G10). **Recommended first.**
- CSV export of transactions.

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
| Data loss (data is only on the device) | Migration tests from the first schema; do Phase 5 backup early |
| Balance drift between screens | One balance function (2.4); screens never do arithmetic |
| Scope creep from the AI | One task per prompt; CLAUDE.md §8 "Stop" rule; one commit per task |
| Schema churn | Schema changes are always called out in the task plan before you approve it |
| Dependency churn | Few dependencies; check pub.dev maintenance before adding |

---

## 6. Next step

The MVP roadmap is delivered. Nothing further is approved. The product owner
decides what comes next; the recommended candidate is the JSON backup/export
in Phase 5 (G10). Plan it like any other task: propose, approve, then build.
