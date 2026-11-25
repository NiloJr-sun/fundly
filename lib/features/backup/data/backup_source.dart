import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

// The records a backup holds, independent of the store they come from. IDs
// are `Object`: integers from the signed-out database, UUID strings from a
// signed-in user's synchronized store. Dates are `YYYY-MM-DD` and months
// `YYYY-MM`, as written to the file.

typedef BackupCustomType = ({
  Object id,
  String name,
  String baseType,
  DateTime createdAt,
});

typedef BackupCustomBank = ({Object id, String name, DateTime createdAt});

typedef BackupAccount = ({
  Object id,
  String name,
  String type,
  Object? customTypeId,
  int openingBalanceMinor,
  String currencyCode,
  DateTime createdAt,
  bool isArchived,
  bool isBudgetAccount,
  String? bankKey,
  Object? customBankId,
});

typedef BackupCategory = ({
  Object id,
  String name,
  String kind,
  bool isArchived,
  bool isPlanArchived,
  bool isPlanDeleted,
  String planGroup,
  Object? linkedAccountId,
  int? defaultTargetMinor,
});

typedef BackupTransaction = ({
  Object id,
  String type,
  int amountMinor,
  String currencyCode,
  String date,
  String payee,
  Object? categoryId,
  Object? sourceAccountId,
  Object? destinationAccountId,
  String note,
  DateTime createdAt,
  DateTime updatedAt,
});

typedef BackupPlan = ({
  Object id,
  String month,
  Object categoryId,
  int? targetAmountMinor,
  int assignedAmountMinor,
  String currencyCode,
  DateTime createdAt,
  DateTime updatedAt,
});

/// Every record of one store, each list in ID order.
typedef BackupRecords = ({
  List<BackupCustomType> customAccountTypes,
  List<BackupCustomBank> customBanks,
  List<BackupAccount> accounts,
  List<BackupCategory> categories,
  List<BackupTransaction> transactions,
  List<BackupPlan> monthlyPlans,
});

/// Where a backup's records come from.
abstract interface class BackupSource {
  /// The store's schema version, recorded in the file for reference.
  int get schemaVersion;

  /// Every record, read in one transaction so it is a consistent snapshot.
  Future<BackupRecords> read();
}

/// This device's signed-out database: integer IDs.
class LocalBackupSource implements BackupSource {
  LocalBackupSource(this._database);

  final AppDatabase _database;

  @override
  int get schemaVersion => _database.schemaVersion;

  @override
  Future<BackupRecords> read() => _database.transaction(() async {
    final customTypes = await _all(_database.customAccountTypes);
    final banks = await _all(_database.customBanks);
    final accounts = await _all(_database.accounts);
    final categories = await _all(_database.categories);
    final transactions = await _all(_database.transactions);
    final plans = await _all(_database.monthlyPlans);
    return (
      customAccountTypes: [
        for (final type in customTypes)
          (
            id: type.id,
            name: type.name,
            baseType: type.baseType.name,
            createdAt: type.createdAt,
          ),
      ],
      customBanks: [
        for (final bank in banks)
          (id: bank.id, name: bank.name, createdAt: bank.createdAt),
      ],
      accounts: [
        for (final account in accounts)
          (
            id: account.id,
            name: account.name,
            type: account.type.name,
            customTypeId: account.customTypeId,
            openingBalanceMinor: account.openingBalanceMinor,
            currencyCode: account.currencyCode,
            createdAt: account.createdAt,
            isArchived: account.isArchived,
            isBudgetAccount: account.isBudgetAccount,
            bankKey: account.bankKey,
            customBankId: account.customBankId,
          ),
      ],
      categories: [
        for (final category in categories)
          (
            id: category.id,
            name: category.name,
            kind: category.kind.name,
            isArchived: category.isArchived,
            isPlanArchived: category.isPlanArchived,
            isPlanDeleted: category.isPlanDeleted,
            planGroup: category.planGroup.name,
            linkedAccountId: category.linkedAccountId,
            defaultTargetMinor: category.defaultTargetMinor,
          ),
      ],
      transactions: [
        for (final transaction in transactions)
          (
            id: transaction.id,
            type: transaction.type.name,
            amountMinor: transaction.amountMinor,
            currencyCode: transaction.currencyCode,
            date: transaction.date.toIsoString(),
            payee: transaction.payee,
            categoryId: transaction.categoryId,
            sourceAccountId: transaction.sourceAccountId,
            destinationAccountId: transaction.destinationAccountId,
            note: transaction.note,
            createdAt: transaction.createdAt,
            updatedAt: transaction.updatedAt,
          ),
      ],
      monthlyPlans: [
        for (final plan in plans)
          (
            id: plan.id,
            month: plan.month.toIsoString(),
            categoryId: plan.categoryId,
            targetAmountMinor: plan.targetAmountMinor,
            assignedAmountMinor: plan.assignedAmountMinor,
            currencyCode: plan.currencyCode,
            createdAt: plan.createdAt,
            updatedAt: plan.updatedAt,
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
