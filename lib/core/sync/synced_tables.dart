import 'package:drift/drift.dart';

// Raw tables for a signed-in user's synchronized records (cloud sync S5.2).
//
// PowerSync fills them from the user's download stream, matching columns by
// name, so table and column names equal the server's
// (`powersync/sync-config.yaml`). IDs are server UUIDs. Timestamps stay in the
// text form they download in and are parsed when mapped to the domain.
//
// Rows arrive in any order within one download checkpoint, so foreign keys
// are deferred to the end of the transaction. CHECKs mirror rules the server
// already enforces exactly; a mismatch would stop downloads, so rules with
// different SQL semantics are left to the server. There are no unique indexes:
// SQLite cannot defer them, and a rename swap in one checkpoint would briefly
// break one.

const _deferred = 'DEFERRABLE INITIALLY DEFERRED';
const _accountTypes = "('savingsCash', 'credit', 'loan')";

@DataClassName('SyncedCustomAccountTypeRow')
class SyncedCustomAccountTypes extends Table {
  @override
  String get tableName => 'custom_account_types';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get baseType => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get revision => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (base_type IN $_accountTypes)',
    'CHECK (revision > 0)',
  ];
}

@DataClassName('SyncedAccountRow')
class SyncedAccounts extends Table {
  @override
  String get tableName => 'accounts';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get openingBalanceMinor => integer()();
  TextColumn get currencyCode => text()();
  BoolColumn get isArchived => boolean()();
  TextColumn get customTypeId => text().nullable()();
  BoolColumn get isBudgetAccount => boolean()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get revision => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (type IN $_accountTypes)',
    "CHECK ((type = 'savingsCash' AND opening_balance_minor >= 0)"
        " OR (type IN ('credit', 'loan') AND opening_balance_minor <= 0))",
    "CHECK (currency_code = 'PHP')",
    "CHECK (NOT is_budget_account OR (type = 'savingsCash' AND NOT is_archived))",
    'CHECK (revision > 0)',
    'FOREIGN KEY (custom_type_id) REFERENCES custom_account_types (id) '
        '$_deferred',
  ];
}

@DataClassName('SyncedCategoryRow')
class SyncedCategories extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  BoolColumn get isArchived => boolean()();
  BoolColumn get isPlanArchived => boolean()();
  BoolColumn get isPlanDeleted => boolean()();
  TextColumn get planGroup => text()();
  TextColumn get linkedAccountId => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get revision => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (kind IN ('spending', 'inflow'))",
    "CHECK (plan_group IN ('spending', 'savings', 'liability'))",
    "CHECK (NOT is_plan_deleted OR (is_plan_archived AND kind = 'spending'))",
    'CHECK (linked_account_id IS NULL OR '
        "(kind = 'spending' AND plan_group = 'liability'))",
    'CHECK (revision > 0)',
    'FOREIGN KEY (linked_account_id) REFERENCES accounts (id) $_deferred',
  ];
}

@DataClassName('SyncedTransactionRow')
class SyncedTransactions extends Table {
  @override
  String get tableName => 'transactions';

  TextColumn get id => text()();
  TextColumn get type => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text()();

  /// `YYYY-MM-DD`; see `parseSyncedDate` for year 0000.
  TextColumn get date => text()();
  TextColumn get payee => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get sourceAccountId => text().nullable()();
  TextColumn get destinationAccountId => text().nullable()();
  TextColumn get note => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get revision => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (type IN ('spending', 'inflow', 'transfer', 'creditCardPayment'))",
    'CHECK (amount_minor > 0)',
    "CHECK (currency_code = 'PHP')",
    'CHECK (source_account_id <> destination_account_id)',
    'CHECK (revision > 0)',
    'FOREIGN KEY (category_id) REFERENCES categories (id) $_deferred',
    'FOREIGN KEY (source_account_id) REFERENCES accounts (id) $_deferred',
    'FOREIGN KEY (destination_account_id) REFERENCES accounts (id) $_deferred',
  ];
}

@DataClassName('SyncedMonthlyPlanRow')
class SyncedMonthlyPlans extends Table {
  @override
  String get tableName => 'monthly_plans';

  TextColumn get id => text()();

  /// `YYYY-MM`.
  TextColumn get month => text()();
  TextColumn get categoryId => text()();
  IntColumn get targetAmountMinor => integer().nullable()();
  IntColumn get assignedAmountMinor => integer()();
  TextColumn get currencyCode => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get revision => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (target_amount_minor IS NULL OR target_amount_minor >= 0)',
    'CHECK (assigned_amount_minor >= 0)',
    "CHECK (currency_code = 'PHP')",
    'CHECK (revision > 0)',
    // The server deletes a category's plans with it (ON DELETE CASCADE), and
    // both deletions arrive in the same checkpoint.
    'FOREIGN KEY (category_id) REFERENCES categories (id) $_deferred',
  ];
}
