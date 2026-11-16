import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../accounts/data/account_row_mapping.dart';
import '../../categories/data/category_row_mapping.dart';
import '../domain/transaction.dart';
import '../domain/transaction_rules.dart';
import '../domain/transaction_validation_exception.dart';

/// Reads and writes transactions. Every write runs [validateTransaction]
/// first (rule 12), inside a database transaction so the accounts and
/// categories it checks cannot change underneath it.
class TransactionRepository {
  TransactionRepository(this._database, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _now;

  $TransactionsTable get _transactions => _database.transactions;

  /// Transactions newest first (by date, then by id).
  ///
  /// [accountId] keeps transactions where that account is the source or the
  /// destination. [from] and [to] are inclusive date bounds.
  Stream<List<Transaction>> watchAll({
    int? accountId,
    CalendarDate? from,
    CalendarDate? to,
  }) {
    final query = _database.select(_transactions)
      ..where((t) {
        final conditions = <Expression<bool>>[
          if (accountId != null)
            t.sourceAccountId.equals(accountId) |
                t.destinationAccountId.equals(accountId),
          if (from != null) t.date.isBiggerOrEqualValue(from.toIsoString()),
          if (to != null) t.date.isSmallerOrEqualValue(to.toIsoString()),
        ];
        return conditions.isEmpty
            ? const Constant(true)
            : conditions.reduce((a, b) => a & b);
      })
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  /// Emits `null` if the transaction does not exist.
  Stream<Transaction?> watchById(int id) {
    final query = _database.select(_transactions)
      ..where((t) => t.id.equals(id));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toDomain(row),
    );
  }

  /// Validates and saves a new transaction.
  ///
  /// Throws [TransactionValidationException] listing every broken rule.
  Future<Transaction> create(TransactionDraft draft) {
    return _database.transaction(() async {
      final normalized = _normalize(draft);
      await _validate(normalized);
      final now = _now().toUtc();
      final row = await _database
          .into(_transactions)
          .insertReturning(
            TransactionsCompanion.insert(
              type: normalized.type,
              amountMinor: normalized.amount.minorUnits,
              currencyCode: normalized.amount.currencyCode,
              date: normalized.date,
              payee: Value(normalized.payee),
              categoryId: Value(normalized.categoryId),
              sourceAccountId: Value(normalized.sourceAccountId),
              destinationAccountId: Value(normalized.destinationAccountId),
              note: Value(normalized.note),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return _toDomain(row);
    });
  }

  /// Validates and saves changes to transaction [id]. The type cannot change
  /// (G8), and an archived account it already uses may be kept (G7).
  ///
  /// Throws [TransactionValidationException], or [StateError] if the
  /// transaction does not exist.
  Future<Transaction> update(int id, TransactionDraft draft) {
    return _database.transaction(() async {
      final existing = await _find(id);
      final normalized = _normalize(draft);
      await _validate(normalized, existing: existing);
      final rows =
          await (_database.update(
            _transactions,
          )..where((t) => t.id.equals(id))).writeReturning(
            TransactionsCompanion(
              amountMinor: Value(normalized.amount.minorUnits),
              currencyCode: Value(normalized.amount.currencyCode),
              date: Value(normalized.date),
              payee: Value(normalized.payee),
              categoryId: Value(normalized.categoryId),
              sourceAccountId: Value(normalized.sourceAccountId),
              destinationAccountId: Value(normalized.destinationAccountId),
              note: Value(normalized.note),
              updatedAt: Value(_now().toUtc()),
            ),
          );
      return _toDomain(rows.single);
    });
  }

  /// Permanently deletes transaction [id]. Balances are derived, so they
  /// recalculate automatically (rule 11).
  ///
  /// Throws [StateError] if the transaction does not exist.
  Future<void> delete(int id) async {
    final deleted = await (_database.delete(
      _transactions,
    )..where((t) => t.id.equals(id))).go();
    if (deleted == 0) throw StateError('Transaction $id does not exist.');
  }

  Future<Transaction> _find(int id) async {
    final row = await (_database.select(
      _transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw StateError('Transaction $id does not exist.');
    return _toDomain(row);
  }

  Future<void> _validate(
    TransactionDraft draft, {
    Transaction? existing,
  }) async {
    final accountRows = await _database.select(_database.accounts).get();
    final categoryRows = await _database.select(_database.categories).get();
    final errors = validateTransaction(
      draft,
      accounts: {for (final row in accountRows) row.id: row.toDomain()},
      categories: {for (final row in categoryRows) row.id: row.toDomain()},
      existing: existing,
    );
    if (errors.isNotEmpty) throw TransactionValidationException(errors);
  }

  /// Trims free text so stored values match what validation measured.
  static TransactionDraft _normalize(TransactionDraft draft) =>
      TransactionDraft(
        type: draft.type,
        amount: draft.amount,
        date: draft.date,
        payee: draft.payee.trim(),
        categoryId: draft.categoryId,
        sourceAccountId: draft.sourceAccountId,
        destinationAccountId: draft.destinationAccountId,
        note: draft.note.trim(),
      );

  static Transaction _toDomain(TransactionRow row) => Transaction(
    id: row.id,
    type: row.type,
    amount: Money(minorUnits: row.amountMinor, currencyCode: row.currencyCode),
    date: row.date,
    payee: row.payee,
    categoryId: row.categoryId,
    sourceAccountId: row.sourceAccountId,
    destinationAccountId: row.destinationAccountId,
    note: row.note,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );
}

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(appDatabaseProvider)),
);
