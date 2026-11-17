# Fundly --- Initial Product Plan

> **Purpose:** Build a personal finance and budgeting app inspired by
> the core ideas of YNAB, starting with a small, usable MVP.
>
> **Working name:** Fundly\
> **Platform:** Flutter\
> **Language:** Dart\
> **Development approach:** AI-Driven Development (AIDD), with the human
> acting as product owner and orchestrator.

------------------------------------------------------------------------

## 1. Product Direction

Fundly helps an individual understand:

-   How much money they have across their accounts.
-   Where their money goes.
-   How money moves between accounts.
-   How much they have spent and received.
-   Eventually, how to plan and allocate their money.

Fundly is a personal-use project initially. Prioritize correctness,
clarity, maintainability, and a manageable development pace over feature
breadth.

### Product principles

1.  **Start small:** Deliver a useful account and transaction tracker
    before building advanced budgeting.
2.  **Financial correctness first:** Transfers and credit-card payments
    must not be counted as new spending.
3.  **Ledger-driven:** Balances and summaries should be derived from
    recorded transactions, not independently edited in multiple screens.
4.  **Offline-friendly:** The initial app should work without requiring
    bank connections or external financial services.
5.  **Incremental delivery:** Implement, test, and review one small
    feature at a time.

------------------------------------------------------------------------

## 2. Initial Navigation

The initial app has three main destinations:

### Spending

Purpose: Give the user a clear view of their money activity.

Initial contents: - Total account balance / available money summary,
with the meaning clearly defined. - Total inflows for the selected
period. - Total spending for the selected period. - Recent
transactions. - Entry point to view all transactions. - Basic filters by
date, account, and category.

Do not build advanced charts or analytics in the first iteration.

### Plans

Purpose: Become the budgeting area over time.

For the first release, this can be a simple placeholder or a minimal
screen explaining that budgeting is planned.

Future scope: - Spending categories. - Monthly budget amounts. - Planned
versus actual spending. - Remaining amount per category.

Do not implement envelope budgeting or automatic allocation rules until
the account and transaction foundation is stable.

### Account

Purpose: Manage the user's financial accounts and app preferences.

Initial contents: - List accounts. - Create an account. - View account
details and transaction history. - Edit account name and other safe
metadata. - Archive an account when it is no longer active, provided it
has no unresolved balance or the user explicitly confirms the behavior.

Initial account types: - **Savings / Cash:** Bank savings, cash wallet,
emergency fund, and similar asset accounts. - **Credit:** Credit-card
accounts representing amounts owed. - **Loan:** Loan accounts
representing outstanding debt.

Keep account type extensible. Do not assume every account is a bank
account.

Each account should support: - Name. - Type. - Opening balance. -
Current balance derived from the opening balance and posted
transactions. - Currency (default to PHP for the initial personal setup,
but avoid hard-coding currency formatting throughout the app). - Created
date. - Active / archived status.

------------------------------------------------------------------------

## 3. Initial Transaction Types

Support these four transaction types:

### 3.1 Spending

Money leaving an asset account, or a purchase charged to a credit
account.

Examples: - Groceries. - Transportation. - Utilities. - Online
subscriptions.

Required information: - Amount. - Date. - Payee / merchant. -
Category. - Account. - Optional note.

### 3.2 Inflow

Money received into an account.

Examples: - Salary. - Freelance income. - Refund. - Cash deposit.

Required information: - Amount. - Date. - Source / payee. - Destination
account. - Optional category and note.

### 3.3 Credit Card Payment

A payment from an asset account to reduce the outstanding balance of a
credit-card account.

Example: - Pay PHP 3,000 from BDO Savings to RCBC Credit Card.

This must be represented as a movement between two accounts, not as a
second spending transaction. The original card purchase is the expense.
Paying the card reduces cash and reduces the credit-card liability.

### 3.4 Transfer

Move money between two accounts owned by the user.

Example: - Transfer PHP 2,000 from BDO Savings to Cash Wallet.

A transfer: - Has a source account and destination account. - Reduces
the source account balance. - Increases the destination account
balance. - Is not income or spending. - Must not be counted in spending
or inflow totals.

### Transaction trail

Every transaction should make it easy to answer: - Where did the money
come from? - Where did the money go? - Which account was affected? -
What category does it belong to? - When did it happen?

Suggested transaction fields: - ID. - Type. - Amount. - Transaction
date. - Payee / description. - Category (when applicable). - Source
account (when applicable). - Destination account (when applicable). -
Notes. - Created and updated timestamps. - Status, if drafts or pending
transactions are introduced later.

Use a consistent sign convention in the domain layer. Do not let
individual screens invent their own balance arithmetic.

------------------------------------------------------------------------

## 4. Accounting and Data Integrity Rules

These rules are non-negotiable. Add automated tests for them before
relying on dashboard totals.

1.  A spending transaction decreases the balance of the account used.
2.  An inflow increases the balance of the receiving account.
3.  A transfer decreases the source account and increases the
    destination account by the same amount.
4.  A credit-card payment decreases the paying asset account and reduces
    the amount owed on the credit account.
5.  Transfers and credit-card payments are excluded from spending
    totals.
6.  A credit-card purchase increases the amount owed on the credit
    account and is counted as spending once.
7.  A transaction must not transfer money from an account to itself.
8.  Amounts must be positive values at input; transaction type
    determines the accounting effect.
9.  Use decimal-safe money representation. Do not use floating-point
    `double` for persisted monetary calculations. Prefer integer minor
    units (for PHP, centavos) or an explicitly designed decimal
    representation.
10. Store timestamps consistently and display dates in the user's local
    timezone.
11. Editing or deleting a transaction must correctly recalculate derived
    balances and summaries.
12. Validate account references and transaction constraints in the
    domain/data layer, not only in the UI.

For the initial version, use a simple transaction model if it can
satisfy these rules. If a ledger-entry model is introduced, document its
debit/credit or signed-entry convention clearly and test it thoroughly.

------------------------------------------------------------------------

## 5. MVP Scope and Delivery Order

Build in small vertical slices. Each slice should compile, run, and have
appropriate tests before moving on.

### Phase 0 --- Project foundation ✅ Complete (2026-11-16)

-   [x] Create Flutter project.
-   [x] Confirm supported Flutter and Dart SDK versions (Flutter 3.47.9
    / Dart 3.13.7).
-   [x] Establish folder structure and app entry point.
-   [x] Add navigation shell with Spending, Plans, and Account tabs.
-   [x] Add theme, typography, spacing, and reusable UI conventions.
-   [x] Configure formatter, analyzer, and test workflow.
-   [x] Add a README with setup and run instructions.

**Acceptance:** The app launches and the three main tabs are navigable.
No production feature logic is required yet.

### Phase 1 --- Account management ✅ Complete (2026-11-16)

Roadmap tasks 1.1–1.6 are done. The acceptance criterion about
transactions was met in Phase 2 (task 2.4): `balancesFor()` in
`features/accounts/domain/account_balance.dart` derives every balance
from the opening balance plus transaction effects.

-   [x] Define account types: Savings/Cash, Credit, Loan.
-   [x] Define account domain model and persistence (drift schema v1).
-   [x] Create account list screen.
-   [x] Create account form.
-   [x] Support opening balance.
-   [x] Show account details and derived current balance.
-   [x] Add validation and tests.

Also delivered: `Money` value type, parser and formatter (`lib/core/`);
archive with confirmation when the balance is non-zero; an Archived
accounts screen with unarchive.

**Acceptance:** A user can create and view multiple accounts. Account
balances are calculated consistently from opening balances and
transactions.

### Phase 2 --- Transaction foundation ✅ Complete (2026-11-16)

Roadmap tasks 2.1–2.8 are done. The database is at schema v3
(accounts, seeded categories, transactions), with migration tests for
every upgrade path.

-   [x] Define transaction domain model.
-   [x] Implement spending.
-   [x] Implement inflow.
-   [x] Implement transfer.
-   [x] Implement credit-card payment.
-   [x] Implement transaction persistence.
-   [x] Implement transaction list and details.
-   [x] Add edit and delete behavior with recalculation.
-   [x] Add domain tests for all balance effects.

Also delivered: a fixed, seeded category list (G1); `CalendarDate` for
transaction dates (G9); per-account transaction history on the account
detail screen; "All transactions" reachable from the Spending tab.

**Acceptance:** A user can record all four transaction types and see
correct account balances and transaction history.

### Phase 3 --- Spending overview ✅ Complete (2026-11-16)

Roadmap tasks 3.1–3.5 are done. Totals come from `periodTotals()` and
`summarizeBalances()` in `features/spending/domain/period_summary.dart`;
only Spending and Inflow count, so transfers and credit-card payments
are excluded. No schema change was needed (still v3).

-   [x] Show account balance summary (Available money, Credit owed,
    Loans owed; D2).
-   [x] Show inflow total for a selected period.
-   [x] Show spending total for a selected period.
-   [x] Show recent transactions.
-   [x] Add basic date, account, and category filters.

Also delivered: a period selector (this month / last month / custom
range, defaulting to this month); the 10 latest transactions with "See
all"; filter chips on the All transactions list (`TransactionFilter` in
`features/transactions/domain/`), which reset each time the list opens
and include archived accounts.

**Acceptance:** Dashboard totals agree with the underlying transaction
records and exclude transfers and credit-card payments from
spending/inflow totals.

### Phase 4 --- Basic Plans ✅ Complete (2026-11-16)

Roadmap tasks 4.1–4.4 are done. The database is at schema v5
(`categories.is_archived` in v4, `monthly_plans` in v5), with migration
tests for every upgrade path. Planned vs actual vs remaining comes from
`planSummaries()` in `features/plans/domain/plan_summary.dart`; actual
counts Spending only, so transfers, card payments and inflows (including
refunds) are excluded.

-   [x] Define spending categories (add, rename, archive, delete when
    unused; Categories screen opened from the Plans tab).
-   [x] Allow transactions to be assigned a category (since Phase 2; new
    transactions cannot use archived categories).
-   [x] Create a monthly budget record (`monthly_plans`,
    `PlanRepository`).
-   [x] Set a planned amount per category (Plans tab).
-   [x] Calculate actual spending and remaining amount.

Also delivered: `CalendarMonth` value type stored as `YYYY-MM`; a month
selector on the Plans tab with a "This month" shortcut; overspending
shown in red.

**Acceptance:** A user can set a simple monthly amount for a category
and compare it with eligible spending.

------------------------------------------------------------------------

## 6. Explicitly Out of Scope for the Initial MVP

Do not implement these unless the product owner explicitly reprioritizes
them:

-   Bank account synchronization or open banking.
-   Automatic transaction imports.
-   Multi-user collaboration or household sharing.
-   Cloud sync and account registration.
-   Recurring transactions and scheduled payments.
-   Investment and net-worth tracking.
-   Loan amortization schedules and interest calculations.
-   Advanced reports, charts, and financial insights.
-   Receipt scanning / OCR.
-   Notifications.
-   Currency conversion.
-   Full YNAB-style envelope budgeting and automatic money allocation.

Keep future extension in mind, but do not build abstractions for
hypothetical requirements.

------------------------------------------------------------------------

## 7. Engineering Standards

Follow these principles throughout implementation:

### Core principles

-   **KISS:** Prefer the simplest design that meets current
    requirements.
-   **DRY:** Reuse genuinely shared logic; do not create abstractions
    prematurely.
-   **YAGNI:** Do not implement features or extension points without a
    current use case.
-   **SOLID:** Keep responsibilities focused and dependencies clear,
    without turning every class into an interface.
-   **Separation of concerns:** UI, application logic, domain rules, and
    persistence should not be tangled.
-   **Single source of truth:** Transaction records are the source for
    derived balances and totals.

### Dart and Flutter practices

-   Follow official Dart formatting and lint recommendations.
-   Use sound null safety.
-   Prefer immutable models where practical.
-   Use `const` constructors where appropriate.
-   Keep widgets small and focused.
-   Avoid business rules inside widgets.
-   Avoid oversized `build()` methods.
-   Use descriptive names; avoid unexplained abbreviations.
-   Handle loading, empty, success, and error states.
-   Do not suppress analyzer warnings without explaining why.
-   Add tests for domain logic and important user flows.

### Architecture

Use a lightweight feature-first structure. Start simple and add layers
only where they provide value.

Suggested starting structure (adapt when implementation evidence
supports a better choice):

``` text
lib/
  app/
    app.dart
    router/
    theme/
  core/
    formatting/
    errors/
    utils/
  features/
    spending/
      presentation/
    plans/
      presentation/
    accounts/
      data/
      domain/
      presentation/
    transactions/
      data/
      domain/
      presentation/
  main.dart

test/
  features/
    accounts/
    transactions/
```

Guidance: - Keep account and transaction business rules in
domain/application code, not in widgets. - Keep persistence details
behind a small repository boundary. - Do not create generic frameworks
or layers that the current feature does not need. - Choose state
management and persistence packages only after checking project
constraints and current package maintenance. Explain the trade-offs
before adding major dependencies. - Keep the initial app local-first. Do
not add a backend unless explicitly requested.

------------------------------------------------------------------------

## 8. AI-Driven Development Workflow

The human is the **product owner and orchestrator**. Claude is the
implementation assistant.

Do not attempt to implement the entire roadmap in one prompt.

For each task:

1.  **Understand:** Read this file and inspect the existing code before
    proposing changes.
2.  **Clarify:** Identify ambiguities that materially affect data
    integrity, UX, or architecture. Ask concise questions instead of
    guessing.
3.  **Plan:** Propose a small implementation plan, files likely to
    change, and tests.
4.  **Approve:** Wait for approval before making changes when the task
    has meaningful architectural or data-model impact. For small,
    unambiguous tasks, follow the user's explicit instruction.
5.  **Implement:** Make the smallest complete change that satisfies the
    task.
6.  **Verify:** Run formatter, analyzer, and relevant tests. Report
    commands and results honestly.
7.  **Review:** Summarize what changed, design decisions, limitations,
    and any follow-up work.
8.  **Stop:** Do not silently continue into the next backlog item.

### Working rules for Claude

-   Treat this document as product direction, not permission to build
    every listed feature at once.
-   Work only on the feature or task the user asks for.
-   Do not add unrequested features.
-   Do not rewrite unrelated code.
-   Do not install dependencies without explaining why they are needed.
-   Do not change the database schema or persisted data format without
    calling it out first.
-   Never claim tests passed unless they were actually run and passed.
-   If a command fails, report the failure and investigate before
    claiming completion.
-   If requirements conflict, stop and ask the product owner.
-   Prefer a short task plan over a large speculative implementation.
-   Update this document only when the user asks or approves a
    product-scope change.

### Suggested task prompt

Use this when starting a development task:

``` text
Read CLAUDE.md first.

Task:
[Describe one small feature or fix.]

Before coding:
1. Inspect the relevant existing code.
2. Summarize your understanding.
3. Identify important edge cases and files likely to change.
4. Propose a small implementation and test plan.

Wait for my approval before implementing if this changes architecture, persistence, or financial rules.

After approval:
- Implement only this task.
- Follow the project standards in CLAUDE.md.
- Run formatter, analyzer, and relevant tests.
- Report changed files, verification results, and known limitations.
- Do not start another task.
```

------------------------------------------------------------------------

## 9. Definition of Done

A task is complete only when:

-   [ ] The requested behavior is implemented.
-   [ ] Existing behavior has not been unintentionally broken.
-   [ ] Relevant validation and error states are handled.
-   [ ] Tests cover important business rules and edge cases.
-   [ ] `dart format` has been run on changed Dart files.
-   [ ] `flutter analyze` has no new unresolved issues.
-   [ ] Relevant tests pass.
-   [ ] No unrelated changes or dependencies were added.
-   [ ] The implementation and any limitations are summarized.

For financial calculations, passing domain tests is required; a visually
correct screen is not sufficient.

------------------------------------------------------------------------

## 10. Current Status

Phases 0–4 are complete: the MVP roadmap is delivered. Nothing beyond
it is approved yet. Phase 5 in [docs/ROADMAP.md](docs/ROADMAP.md) is a
proposal only (JSON backup/export recommended first); the product owner
must approve any next step before work starts.

Every schema change must bump `schemaVersion`, run
`dart run drift_dev make-migrations`, and ship with a data-integrity
migration test.

Work one roadmap task at a time and stop after each. Do not implement
authentication, cloud sync, Phase 5 items, or anything in §6 until
explicitly requested.

------------------------------------------------------------------------

## 11. Product Decisions Log

Record confirmed decisions here as the project evolves. Do not treat
suggestions as approved decisions.

  -----------------------------------------------------------------------
  Date                    Decision                Status
  ----------------------- ----------------------- -----------------------
  2026-11-16              Working app name is     Selected working name
                          Fundly                  

  2026-11-16              Initial navigation:     Confirmed
                          Spending, Plans,        
                          Account                 

  2026-11-16              Initial account types:  Confirmed
                          Savings/Cash, Credit,   
                          Loan                    

  2026-11-16              Initial transaction     Confirmed
                          types: Spending,        
                          Inflow, Credit Card     
                          Payment, Transfer       

  2026-11-16              Build slowly in small   Confirmed
                          phases; human           
                          orchestrates AIDD       

  2026-11-16              Phase 0 navigation:     Confirmed
                          Material 3              
                          NavigationBar +         
                          IndexedStack; no        
                          go_router yet (D5)      

  2026-11-16              Primary device: iOS;    Confirmed
                          Android best-effort     
                          (D6). Theme seed: teal  

  2026-11-16              Signed balances in      Confirmed
                          integer centavos:       
                          assets usually >= 0,    
                          Credit/Loan owed        
                          amounts negative;       
                          balance = opening +     
                          sum of effects (D1)     

  2026-11-16              Persistence: drift      Confirmed
                          (SQLite), local-first.  
                          Supabase considered     
                          and deferred (D3)       

  2026-11-16              State management:       Confirmed
                          flutter_riverpod,       
                          hand-written, no        
                          codegen (D4)            

  2026-11-16              All accounts PHP for    Confirmed
                          now; currency code      
                          stored but not          
                          editable; cross-        
                          currency transfers      
                          rejected (G6)           

  2026-11-16              Archived accounts:      Confirmed
                          hidden from pickers     
                          and summaries, keep     
                          history, accept no new  
                          transactions; accounts  
                          with transactions are   
                          never hard-deleted (G7) 

  2026-11-16              IDs: SQLite auto-       Confirmed
                          increment integers;     
                          no UUIDs until sync is  
                          in scope (D7)           

  2026-11-16              Account type is locked  Confirmed
                          after creation; opening 
                          balance stays editable  
                          (balances recalculate)  

  2026-11-16              Account names: trimmed, Confirmed
                          1-40 characters, unique 
                          ignoring case (enforced 
                          in the data layer),     
                          including archived      
                          accounts                

  2026-11-16              Generated code          Confirmed
                          (*.g.dart) is committed 

  2026-11-16              Archiving: confirm only Implemented in task
                          when balance is non-    1.6
                          zero; archived accounts 
                          can be unarchived from  
                          an Archived accounts    
                          screen                  

  2026-11-16              Phase 2 categories:     Confirmed
                          fixed seeded list.      
                          Spending: Food,         
                          Transport, Utilities,   
                          Subscriptions,          
                          Shopping, Health,       
                          Other. Inflow           
                          (optional): Salary,     
                          Other income. Phase 4   
                          adds management (G1)    

  2026-11-16              Loan payments are       Confirmed
                          Transfers from an asset 
                          account to the Loan     
                          account; no interest    
                          (G4)                    

  2026-11-16              A destination Credit    Confirmed
                          account requires a      
                          Credit Card Payment;    
                          Transfers cannot target 
                          Credit accounts (G5)    

  2026-11-16              A transaction's type    Confirmed
                          cannot change on edit   
                          (delete and re-create)  
                          (G8)                    

  2026-11-16              Transaction date is a   Confirmed
                          local calendar date (no 
                          time); created/updated  
                          timestamps are UTC (G9) 

  2026-11-16              Allowed accounts:       Confirmed
                          Spending from           
                          Savings/Cash or Credit; 
                          Inflow to Savings/Cash  
                          or Credit; Transfer     
                          from Savings/Cash to    
                          Savings/Cash or Loan;   
                          CC Payment from         
                          Savings/Cash to Credit  

  2026-11-16              Payee required for      Confirmed
                          Spending and Inflow,    
                          optional otherwise; max 
                          60 chars. Note max 500. 
                          Future dates allowed    

  2026-11-16              Available money = total Confirmed
                          of active Savings/Cash  
                          balances; Credit owed   
                          and Loans owed shown    
                          separately; no net      
                          worth (D2)              

  2026-11-16              Spending tab totals     Confirmed
                          default to the current  
                          calendar month          

  2026-11-16              Transaction filters     Implemented in task
                          (date range, account,   3.5
                          category) reset when    
                          the list is reopened;   
                          the account filter      
                          includes archived       
                          accounts and matches    
                          either side             

  2026-11-16              Categories can be       Confirmed
                          added, renamed,         
                          archived and            
                          unarchived; deleted     
                          only when no            
                          transaction uses them.  
                          Names follow the        
                          account-name rules;     
                          kind is locked; new     
                          transactions cannot use 
                          archived categories,    
                          edits may keep them     
                          (task 4.1)              

  2026-11-16              Monthly plans: spending Confirmed
                          categories only; one    
                          plan per category per   
                          month; zero allowed and 
                          differs from no plan;   
                          no new plans for        
                          archived categories; no 
                          carry-over between      
                          months; deleting a      
                          category deletes its    
                          plans (task 4.2)        

  2026-11-16              Plan actual counts      Confirmed
                          Spending only; archived 
                          categories appear only  
                          with a plan or spending 
                          that month; no whole-   
                          month totals yet (tasks 
                          4.3, 4.4)               

  2026-11-17              Spending tab list: This Confirmed
                          month shows the 10      
                          newest transactions     
                          overall; Last month and 
                          custom ranges show only 
                          that period's 10        
                          newest. See all opens   
                          All transactions pre-   
                          filtered to that period 
                          (unfiltered for This    
                          month)                  
  -----------------------------------------------------------------------
