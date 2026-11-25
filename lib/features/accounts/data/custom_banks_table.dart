import 'package:drift/drift.dart';

/// SQLite table for custom banks (added in schema v15, docs/BANKS_PLAN.md).
///
/// Names are unique ignoring ASCII case and 1-40 characters long; the
/// repository also refuses built-in bank names. A bank used by an account
/// cannot be deleted (the foreign key on `accounts` restricts it).
@DataClassName('CustomBankRow')
class CustomBanks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();

  /// UTC instant.
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<String> get customConstraints => [
    'CHECK (length(name) BETWEEN 1 AND 40)',
  ];
}
