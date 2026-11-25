import 'package:drift/drift.dart';

import '../domain/account_type.dart';
import 'custom_account_types_table.dart';
import 'custom_banks_table.dart';

/// SQLite table for [Account]s (schema v1; `custom_type_id` in v7;
/// `is_budget_account` in v9; several budget accounts from v13; `bank_key`
/// and `custom_bank_id` in v15).
///
/// The database enforces the integrity rules too, so a bug in Dart code cannot
/// store an invalid account:
/// - names are unique ignoring ASCII case and 1-40 characters long;
/// - the opening balance sign matches the account type (CLAUDE.md §11, D1);
/// - only Savings/Cash accounts can be budget accounts;
/// - an account has at most one bank, and a key has the server's shape.
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

  /// The custom type the account is shown under, or null for its built-in
  /// [type]. When set, [type] equals that custom type's base type; the
  /// repository enforces this, because SQLite checks cannot see other tables.
  IntColumn get customTypeId => integer().nullable().references(
    CustomAccountTypes,
    #id,
    onDelete: KeyAction.restrict,
  )();

  /// Whether money coming into this account funds Ready to assign on Plans.
  /// Any number of Savings/Cash accounts can be budget accounts.
  BoolColumn get isBudgetAccount => boolean()
      .withDefault(const Constant(false))
      // The check refers to the column itself, which is drift's documented
      // way to write a column CHECK; the generated code does not recurse.
      .check(
        // ignore: recursive_getters
        isBudgetAccount.not() | type.equals('savingsCash'),
      )();

  /// The built-in bank the account belongs to (`Bank.key`), or null. Same
  /// shape as the server's check, `^[a-z0-9]{1,32}$`, which SQLite has no
  /// regular expressions for.
  TextColumn get bankKey => text().nullable().customConstraint(
    'CHECK (bank_key IS NULL OR (length(bank_key) BETWEEN 1 AND 32 '
    "AND bank_key NOT GLOB '*[^a-z0-9]*'))",
  )();

  /// The custom bank the account belongs to, or null; never together with
  /// [bankKey]. Column-level, so the v15 migration can add it to existing
  /// tables.
  IntColumn get customBankId => integer()
      .nullable()
      .references(CustomBanks, #id, onDelete: KeyAction.restrict)
      // Refers to another column, like isBudgetAccount's check.
      // ignore: recursive_getters
      .check(customBankId.isNull() | bankKey.isNull())();

  @override
  List<String> get customConstraints => [
    'CHECK (length(name) BETWEEN 1 AND 40)',
    "CHECK ((type = 'savingsCash' AND opening_balance_minor >= 0)"
        " OR (type IN ('credit', 'loan') AND opening_balance_minor <= 0))",
  ];
}
