import 'package:drift/drift.dart';

import '../../../core/database/calendar_date_converter.dart';
import '../../accounts/data/accounts_table.dart';
import '../../categories/data/categories_table.dart';
import '../domain/transaction_type.dart';

/// SQLite table for transactions (added in schema v3).
///
/// The database enforces every rule that a single row can express: positive
/// amount (rule 8), different source and destination (rule 7), which account
/// and category columns each type uses, and length limits. Rules that need
/// other tables (allowed account types, archived accounts, category kind,
/// and since v16 that only a card purchase may have no category) are
/// enforced by `validateTransaction` in the repository.
///
/// Accounts and categories referenced here cannot be deleted (G7).
@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_date', columns: {#date})
@TableIndex(name: 'transactions_source_account', columns: {#sourceAccountId})
@TableIndex(
  name: 'transactions_destination_account',
  columns: {#destinationAccountId},
)
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stored by enum name, e.g. `creditCardPayment`.
  TextColumn get type => textEnum<TransactionType>()();

  /// Positive minor units (rule 8); [type] decides the sign of its effect.
  IntColumn get amountMinor => integer()();

  TextColumn get currencyCode => text()();

  /// Local calendar date as `YYYY-MM-DD` (G9).
  TextColumn get date => text().map(const CalendarDateConverter())();

  TextColumn get payee => text().withDefault(const Constant(''))();

  IntColumn get categoryId => integer().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.restrict,
  )();

  IntColumn get sourceAccountId => integer().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.restrict,
  )();

  IntColumn get destinationAccountId => integer().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get note => text().withDefault(const Constant(''))();

  /// UTC instants (G9).
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<String> get customConstraints => [
    'CHECK (amount_minor > 0)',
    'CHECK (source_account_id <> destination_account_id)',
    "CHECK (date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
    'CHECK (length(payee) <= 60)',
    'CHECK (length(note) <= 500)',
    // Which account and category columns each type uses. Spending may have
    // no category since v16: a card purchase (R.18), checked in
    // validateTransaction because it depends on the account type.
    "CHECK ((type = 'spending' AND source_account_id IS NOT NULL"
        ' AND destination_account_id IS NULL)'
        " OR (type = 'inflow' AND source_account_id IS NULL"
        ' AND destination_account_id IS NOT NULL)'
        " OR (type IN ('transfer', 'creditCardPayment')"
        ' AND source_account_id IS NOT NULL'
        ' AND destination_account_id IS NOT NULL AND category_id IS NULL))',
  ];
}
