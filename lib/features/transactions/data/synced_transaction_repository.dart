import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/synced_database.dart';
import '../../../core/time/calendar_date.dart';
import '../../accounts/data/synced_account_repository.dart';
import '../../categories/data/synced_category_repository.dart';
import '../domain/transaction.dart';
import '../domain/transaction_rules.dart';
import '../domain/transaction_type.dart';
import '../domain/transaction_validation_exception.dart';
import 'transaction_repository.dart';

/// Transactions in the signed-in user's synchronized store. Writes apply
/// locally at once and queue the matching operation for upload (S5.3); the
/// rules are the same as the local store's.
class SyncedTransactionRepository implements TransactionRepository {
  SyncedTransactionRepository(this._database, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final SyncedDatabase _database;
  final DateTime Function() _now;

  $SyncedTransactionsTable get _transactions => _database.syncedTransactions;

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

  @override
  Future<Transaction> create(TransactionDraft draft) =>
      _database.writeAndQueue(() async {
        final normalized = TransactionRepository.normalize(draft);
        await _validate(normalized);
        final id = newRecordId();
        final now = syncedTimestamp(_now());
        final row = await _database
            .into(_transactions)
            .insertReturning(
              SyncedTransactionsCompanion.insert(
                id: id,
                type: normalized.type.name,
                amountMinor: normalized.amount.minorUnits,
                currencyCode: normalized.amount.currencyCode,
                date: wireDate(normalized.date),
                payee: normalized.payee,
                categoryId: Value(normalized.categoryId),
                sourceAccountId: Value(normalized.sourceAccountId),
                destinationAccountId: Value(normalized.destinationAccountId),
                note: normalized.note,
                createdAt: now,
                updatedAt: now,
                revision: 1,
              ),
            );
        return (
          syncedTransaction(row),
          [
            SyncOperation(
              'transaction.create',
              id,
              data: {
                'type': normalized.type.name,
                ..._wireFields(normalized, includeEmptyReferences: false),
              },
            ),
          ],
        );
      });

  @override
  Future<Transaction> update(String id, TransactionDraft draft) =>
      _database.writeAndQueue(() async {
        final existing = await _find(id);
        final normalized = TransactionRepository.normalize(draft);
        await _validate(normalized, existing: syncedTransaction(existing));
        final rows =
            await (_database.update(
              _transactions,
            )..where((t) => t.id.equals(id))).writeReturning(
              SyncedTransactionsCompanion(
                amountMinor: Value(normalized.amount.minorUnits),
                currencyCode: Value(normalized.amount.currencyCode),
                date: Value(wireDate(normalized.date)),
                payee: Value(normalized.payee),
                categoryId: Value(normalized.categoryId),
                sourceAccountId: Value(normalized.sourceAccountId),
                destinationAccountId: Value(normalized.destinationAccountId),
                note: Value(normalized.note),
                updatedAt: Value(syncedTimestamp(_now())),
                revision: Value(nextRevision(existing.revision)),
              ),
            );
        return (
          syncedTransaction(rows.single),
          [
            // The type cannot change (G8), so it is not sent.
            SyncOperation(
              'transaction.update',
              id,
              expectedRevision: existing.revision,
              data: _wireFields(normalized, includeEmptyReferences: true),
            ),
          ],
        );
      });

  @override
  Future<void> delete(String id) => _database.writeAndQueue(() async {
    final existing = await _find(id);
    await (_database.delete(_transactions)..where((t) => t.id.equals(id))).go();
    return (
      null,
      [
        SyncOperation(
          'transaction.delete',
          id,
          expectedRevision: existing.revision,
        ),
      ],
    );
  });

  Future<SyncedTransactionRow> _find(String id) async {
    final row = await (_database.select(
      _transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw StateError('Transaction $id does not exist.');
    return row;
  }

  Future<void> _validate(
    TransactionDraft draft, {
    Transaction? existing,
  }) async {
    final accounts = await _database.select(_database.syncedAccounts).get();
    final categories = await _database.select(_database.syncedCategories).get();
    final errors = validateTransaction(
      draft,
      accounts: {for (final row in accounts) row.id: syncedAccount(row)},
      categories: {for (final row in categories) row.id: syncedCategory(row)},
      existing: existing,
    );
    if (errors.isNotEmpty) throw TransactionValidationException(errors);
  }

  /// The editable fields on the wire. An update states every reference, so
  /// a cleared one becomes an explicit null; a create leaves them out.
  static Map<String, Object?> _wireFields(
    TransactionDraft draft, {
    required bool includeEmptyReferences,
  }) => {
    'amount_minor': wireMinor(draft.amount.minorUnits),
    'currency_code': draft.amount.currencyCode,
    'date': wireDate(draft.date),
    'payee': draft.payee,
    'note': draft.note,
    for (final (key, value) in [
      ('category_id', draft.categoryId),
      ('source_account_id', draft.sourceAccountId),
      ('destination_account_id', draft.destinationAccountId),
    ])
      if (value != null || includeEmptyReferences) key: value,
  };
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
