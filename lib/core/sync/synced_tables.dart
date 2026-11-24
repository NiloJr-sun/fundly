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

/// The spaces the user belongs to (shared spaces C2), from the
/// `fundly_spaces` stream. Download only: spaces are created and renamed
/// online through their own RPCs, never through the upload queue.
@DataClassName('SyncedSpaceRow')
class SyncedSpaces extends Table {
  @override
  String get tableName => 'spaces';

  TextColumn get id => text()();
  TextColumn get name => text()();

  /// The user whose Personal space this is (its id equals theirs), or null.
  TextColumn get personalOf => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get revision => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Members of those spaces and their roles (shared spaces C2), with each
/// member's email and name since C3, from the `fundly_spaces` stream.
/// Download only. No foreign key: rows of one stream arrive in any order.
@DataClassName('SyncedSpaceMemberRow')
class SyncedSpaceMembers extends Table {
  @override
  String get tableName => 'space_members';

  TextColumn get id => text()();
  TextColumn get spaceId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()();

  /// Copied from the member's sign-in when they joined (shared spaces C3,
  /// Decision C3-3); null when the sign-in had none.
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (role IN ('owner', 'editor', 'viewer'))",
  ];
}

/// Changes the server refused (cloud sync S5.4). Local only: it is not one of
/// PowerSync's raw tables, so it is never downloaded or uploaded.
@DataClassName('SyncRejectionRow')
class SyncRejections extends Table {
  @override
  String get tableName => 'sync_rejections';

  /// The refused batch's UUID. One entry per batch, so a retry after a crash
  /// cannot record it twice.
  TextColumn get batchId => text()();

  /// `rejected`, or `dependency_rejected` for a batch that was never sent
  /// because it relied on a refused one.
  TextColumn get kind => text()();

  /// The server's message code; null for `dependency_rejected`.
  TextColumn get code => text().nullable()();

  /// The server's JSON detail, when it sent one.
  TextColumn get detail => text().nullable()();

  /// For `dependency_rejected`: the batch it relied on.
  TextColumn get causedBy => text().nullable()();

  /// The batch envelope exactly as queued: what the user tried to do.
  TextColumn get operations => text()();

  /// JSON list of the IDs the batch would have created.
  TextColumn get createdIds => text()();

  /// JSON object of record ID → name (or payee) as the device showed them
  /// when the change was refused, so it can still be described after the
  /// records return to the server's state.
  TextColumn get labels => text()();

  /// UTC, ISO 8601.
  TextColumn get rejectedAt => text()();

  @override
  Set<Column> get primaryKey => {batchId};

  @override
  List<String> get customConstraints => [
    "CHECK (kind IN ('rejected', 'dependency_rejected'))",
  ];
}
