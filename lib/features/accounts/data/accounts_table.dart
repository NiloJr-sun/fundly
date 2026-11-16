import 'package:drift/drift.dart';

import '../domain/account_type.dart';

/// SQLite table for [Account]s (schema v1).
///
/// The database enforces the integrity rules too, so a bug in Dart code cannot
/// store an invalid account:
/// - names are unique ignoring ASCII case and 1-40 characters long;
/// - the opening balance sign matches the account type (CLAUDE.md §11, D1).
@DataClassName('AccountRow')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();

  /// Stored by enum name (e.g. `credit`), so reordering [AccountType] is safe.
  /// Renaming a value requires a migration.
  TextColumn get type => textEnum<AccountType>()();

  /// Signed minor units (centavos for PHP).
  IntColumn get openingBalanceMinor => integer()();

  TextColumn get currencyCode => text().withDefault(const Constant('PHP'))();

  /// UTC instant.
  DateTimeColumn get createdAt => dateTime()();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => [
    'CHECK (length(name) BETWEEN 1 AND 40)',
    "CHECK ((type = 'savingsCash' AND opening_balance_minor >= 0)"
        " OR (type IN ('credit', 'loan') AND opening_balance_minor <= 0))",
  ];
}
