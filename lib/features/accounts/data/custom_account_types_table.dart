import 'package:drift/drift.dart';

import '../domain/account_type.dart';

/// SQLite table for custom account types (added in schema v7).
///
/// Names are unique ignoring ASCII case and 1-40 characters long. A type used
/// by an account cannot be deleted (the foreign key on `accounts` restricts
/// it).
@DataClassName('CustomAccountTypeRow')
class CustomAccountTypes extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();

  /// The built-in type whose rules accounts of this type follow. Stored by
  /// enum name, like `accounts.type`.
  TextColumn get baseType => textEnum<AccountType>()();

  /// UTC instant.
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<String> get customConstraints => [
    'CHECK (length(name) BETWEEN 1 AND 40)',
    "CHECK (base_type IN ('savingsCash', 'credit', 'loan'))",
  ];
}
