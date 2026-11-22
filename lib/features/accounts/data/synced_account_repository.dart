import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../core/sync/synced_database.dart';
import '../../../core/sync/synced_store.dart';
import '../domain/account.dart';
import '../domain/account_type.dart';
import '../domain/custom_account_type.dart';
import 'account_repository.dart';
import 'custom_account_type_repository.dart';

/// Accounts from the signed-in user's synchronized store. Read-only until
/// sync uploads arrive (S5.3).
class SyncedAccountRepository implements AccountRepository {
  SyncedAccountRepository(this._database);

  final SyncedDatabase _database;

  SimpleSelectStatement<$SyncedAccountsTable, SyncedAccountRow> _select() =>
      _database.select(_database.syncedAccounts)..where(
        (_) => CustomExpression<bool>('NOT (${unsafeAccount('accounts')})'),
      );

  @override
  Stream<List<Account>> watchAll({bool includeArchived = false}) {
    final query = _select();
    if (!includeArchived) {
      query.where((account) => account.isArchived.equals(false));
    }
    return query.watch().map(
      (rows) =>
          rows.map(syncedAccount).toList()
            ..sort(AccountRepository.byTypeThenName),
    );
  }

  @override
  Stream<Account?> watchById(String id) {
    final query = _select()..where((account) => account.id.equals(id));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : syncedAccount(row),
    );
  }

  /// Every write is unavailable until sync uploads arrive (S5.3), which
  /// replace this with real operations.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw const ReadOnlyStoreException();
}

/// Custom account types from the synchronized store. Read-only until S5.3.
class SyncedCustomAccountTypeRepository implements CustomAccountTypeRepository {
  SyncedCustomAccountTypeRepository(this._database);

  final SyncedDatabase _database;

  @override
  Stream<List<CustomAccountType>> watchAll() =>
      (_database.select(_database.syncedCustomAccountTypes)..where(
            (_) => CustomExpression<bool>(
              'NOT (${unsafe('custom_account_types.revision')})',
            ),
          ))
          .watch()
          .map(
            (rows) =>
                [
                  for (final row in rows)
                    CustomAccountType(
                      id: row.id,
                      name: row.name,
                      baseType: AccountType.values.byName(row.baseType),
                      createdAt: parseSyncedTimestamp(row.createdAt),
                    ),
                ]..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                ),
          );

  /// Every write is unavailable until sync uploads arrive (S5.3), which
  /// replace this with real operations.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw const ReadOnlyStoreException();
}

Account syncedAccount(SyncedAccountRow row) => Account(
  id: row.id,
  name: row.name,
  type: AccountType.values.byName(row.type),
  openingBalance: Money(
    minorUnits: row.openingBalanceMinor,
    currencyCode: row.currencyCode,
  ),
  createdAt: parseSyncedTimestamp(row.createdAt),
  isArchived: row.isArchived,
  customTypeId: row.customTypeId,
  isBudgetAccount: row.isBudgetAccount,
);
