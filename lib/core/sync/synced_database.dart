import 'package:drift/drift.dart';

import '../time/calendar_date.dart';
import 'synced_database.steps.dart';
import 'synced_tables.dart';

part 'synced_database.g.dart';

/// A signed-in user's synchronized records (cloud sync S5.2).
///
/// Separate from the signed-out [AppDatabase] and its integer IDs: these
/// tables hold server UUIDs and are filled by PowerSync downloads. Schema
/// changes follow the same rule as the local database: bump [schemaVersion],
/// add a migration step and run `dart run drift_dev make-migrations`.
@DriftDatabase(
  tables: [
    SyncedCustomAccountTypes,
    SyncedAccounts,
    SyncedCategories,
    SyncedTransactions,
    SyncedMonthlyPlans,
    SyncRejections,
  ],
)
class SyncedDatabase extends _$SyncedDatabase {
  SyncedDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      // v2 (S5.4): the local log of refused changes.
      from1To2: (migrator, schema) =>
          migrator.createTable(schema.syncRejections),
    ),
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  /// How many downloaded rows hold a number that Flutter web cannot represent
  /// exactly. Repositories skip those rows everywhere, so every platform shows
  /// the same records; the sync status reports the count.
  Stream<int> watchUnsafeNumberCount() => customSelect(
    'SELECT '
    '(SELECT count(*) FROM custom_account_types WHERE ${unsafe('revision')}) + '
    '(SELECT count(*) FROM accounts WHERE ${unsafeAccount('accounts')}) + '
    '(SELECT count(*) FROM categories WHERE ${unsafe('revision')}) + '
    '(SELECT count(*) FROM transactions WHERE ${unsafeTransaction('transactions')}) + '
    '(SELECT count(*) FROM monthly_plans WHERE ${unsafePlan('monthly_plans')}) '
    'AS unsafe',
    readsFrom: allTables.toSet(),
  ).watchSingle().map((row) => row.read<int>('unsafe'));
}

/// The largest integer Flutter web holds exactly (2^53 − 1).
const maxSafeInteger = 9007199254740991;

/// SQL that is true when [column] cannot be represented exactly on web.
String unsafe(String column) => 'abs($column) > $maxSafeInteger';

String unsafeAccount(String table) =>
    '${unsafe('$table.opening_balance_minor')} OR ${unsafe('$table.revision')}';

String unsafeTransaction(String table) =>
    '${unsafe('$table.amount_minor')} OR ${unsafe('$table.revision')}';

String unsafePlan(String table) =>
    '${unsafe('coalesce($table.target_amount_minor, 0)')} OR '
    '${unsafe('$table.assigned_amount_minor')} OR ${unsafe('$table.revision')}';

final _syncedDatePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})( BC)?$');

/// Parses a downloaded date. The server stores the app's year 0000 as
/// PostgreSQL's 1 BC, which downloads as `0001-01-01 BC`; no earlier year is
/// allowed by the server.
CalendarDate parseSyncedDate(String text) {
  final match = _syncedDatePattern.firstMatch(text);
  if (match == null) throw FormatException('Not a synced date', text);
  final year = int.parse(match.group(1)!);
  final isBc = match.group(4) != null;
  if (isBc && year != 1) throw FormatException('Year out of range', text);
  return CalendarDate(
    isBc ? 0 : year,
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

/// Parses a downloaded timestamp (PostgreSQL text, with a space or `T`) as
/// UTC.
DateTime parseSyncedTimestamp(String text) => DateTime.parse(text).toUtc();
