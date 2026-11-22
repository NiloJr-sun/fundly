import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../core/sync/synced_database.dart';
import '../../../core/sync/synced_store.dart';
import '../../../core/time/calendar_date.dart';
import '../domain/transaction.dart';
import '../domain/transaction_type.dart';
import 'transaction_repository.dart';

/// Transactions from the signed-in user's synchronized store. Read-only until
/// sync uploads arrive (S5.3).
class SyncedTransactionRepository implements TransactionRepository {
  SyncedTransactionRepository(this._database);

  final SyncedDatabase _database;

  SimpleSelectStatement<$SyncedTransactionsTable, SyncedTransactionRow>
  _select() => _database.select(_database.syncedTransactions)
    ..where(
      (_) =>
          CustomExpression<bool>('NOT (${unsafeTransaction('transactions')})'),
    );

  /// Newest first by date, then by creation (the local store's order).
  @override
  Stream<List<Transaction>> watchAll({
    String? accountId,
    CalendarDate? from,
    CalendarDate? to,
  }) {
    final query = _select()
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.createdAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
    if (accountId != null) {
      query.where(
        (t) =>
            t.sourceAccountId.equals(accountId) |
            t.destinationAccountId.equals(accountId),
      );
    }
    if (from != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(from.toIsoString()));
    }
    if (to != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(to.toIsoString()));
    }
    return query.watch().map((rows) => rows.map(syncedTransaction).toList());
  }

  @override
  Stream<Transaction?> watchById(String id) {
    final query = _select()..where((t) => t.id.equals(id));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : syncedTransaction(row),
    );
  }

  /// Every write is unavailable until sync uploads arrive (S5.3), which
  /// replace this with real operations.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw const ReadOnlyStoreException();
}

Transaction syncedTransaction(SyncedTransactionRow row) => Transaction(
  id: row.id,
  type: TransactionType.values.byName(row.type),
  amount: Money(minorUnits: row.amountMinor, currencyCode: row.currencyCode),
  date: parseSyncedDate(row.date),
  payee: row.payee,
  categoryId: row.categoryId,
  sourceAccountId: row.sourceAccountId,
  destinationAccountId: row.destinationAccountId,
  note: row.note,
  createdAt: parseSyncedTimestamp(row.createdAt),
  updatedAt: parseSyncedTimestamp(row.updatedAt),
);
