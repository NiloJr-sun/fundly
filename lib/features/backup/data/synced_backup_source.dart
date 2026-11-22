import 'package:drift/drift.dart';

import '../../../core/sync/synced_database.dart';
import 'backup_source.dart';

/// A signed-in user's synchronized store: format 7, UUID string IDs
/// (cloud sync S6 Decision 6).
///
/// It reads every downloaded row, including any the web app hides because a
/// number is too large to read exactly there; callers refuse to export in
/// that case (see `signedInExportBlocker`).
class SyncedBackupSource implements BackupSource {
  SyncedBackupSource(this._database);

  final SyncedDatabase _database;

  @override
  int get formatVersion => 7;

  @override
  int get schemaVersion => _database.schemaVersion;

  @override
  Future<BackupRecords> read() => _database.transaction(() async {
    final customTypes = await _all(_database.syncedCustomAccountTypes);
    final accounts = await _all(_database.syncedAccounts);
    final categories = await _all(_database.syncedCategories);
    final transactions = await _all(_database.syncedTransactions);
    final plans = await _all(_database.syncedMonthlyPlans);
    return (
      customAccountTypes: [
        for (final type in customTypes)
          (
            id: type.id,
            name: type.name,
            baseType: type.baseType,
            createdAt: parseSyncedTimestamp(type.createdAt),
          ),
      ],
      accounts: [
        for (final account in accounts)
          (
            id: account.id,
            name: account.name,
            type: account.type,
            customTypeId: account.customTypeId,
            openingBalanceMinor: account.openingBalanceMinor,
            currencyCode: account.currencyCode,
            createdAt: parseSyncedTimestamp(account.createdAt),
            isArchived: account.isArchived,
            isBudgetAccount: account.isBudgetAccount,
          ),
      ],
      categories: [
        for (final category in categories)
          (
            id: category.id,
            name: category.name,
            kind: category.kind,
            isArchived: category.isArchived,
            isPlanArchived: category.isPlanArchived,
            isPlanDeleted: category.isPlanDeleted,
            planGroup: category.planGroup,
            linkedAccountId: category.linkedAccountId,
          ),
      ],
      transactions: [
        for (final transaction in transactions)
          (
            id: transaction.id,
            type: transaction.type,
            amountMinor: transaction.amountMinor,
            currencyCode: transaction.currencyCode,
            // The server's 1 BC is the app's year 0000.
            date: parseSyncedDate(transaction.date).toIsoString(),
            payee: transaction.payee,
            categoryId: transaction.categoryId,
            sourceAccountId: transaction.sourceAccountId,
            destinationAccountId: transaction.destinationAccountId,
            note: transaction.note,
            createdAt: parseSyncedTimestamp(transaction.createdAt),
            updatedAt: parseSyncedTimestamp(transaction.updatedAt),
          ),
      ],
      monthlyPlans: [
        for (final plan in plans)
          (
            id: plan.id,
            month: plan.month,
            categoryId: plan.categoryId,
            targetAmountMinor: plan.targetAmountMinor,
            assignedAmountMinor: plan.assignedAmountMinor,
            currencyCode: plan.currencyCode,
            createdAt: parseSyncedTimestamp(plan.createdAt),
            updatedAt: parseSyncedTimestamp(plan.updatedAt),
          ),
      ],
    );
  });

  /// Every row of [table], in id order.
  Future<List<Row>> _all<T extends HasResultSet, Row>(
    ResultSetImplementation<T, Row> table,
  ) {
    final query = _database.select(
      table,
    )..orderBy([(_) => OrderingTerm(expression: const CustomExpression('id'))]);
    return query.get();
  }
}
