import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fundly/core/sync/synced_store.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/data/custom_account_type_repository.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_balance.dart';
import 'package:fundly/features/accounts/domain/custom_account_type.dart';
import 'package:fundly/features/accounts/presentation/accounts_providers.dart';
import 'package:fundly/features/categories/data/category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/categories/presentation/categories_providers.dart';
import 'package:fundly/features/plans/data/plan_repository.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/presentation/plans_providers.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/presentation/transactions_providers.dart';

import 'fake_account_repository.dart';
import 'fake_category_repository.dart';
import 'fake_custom_account_type_repository.dart';
import 'fake_plan_repository.dart';
import 'fake_synced_store.dart';
import 'fake_transaction_repository.dart';

/// Overrides that keep widget tests off the real on-device database.
///
/// Account lookups by id search both [accounts] and [archived]. Balances come
/// from [balancesFor] over [transactions], exactly as in the app. Pass
/// [plans] are returned for whichever month they belong to. Pass
/// [repository], [categoryRepository], [planRepository],
/// [transactionRepository] or [customTypeRepository] to inspect what screens
/// asked them to do.
List<Override> fakeAccounts(
  List<Account> accounts, {
  List<Account> archived = const [],
  List<Transaction> transactions = const [],
  List<Category> categories = const [],
  Stream<List<Category>>? categoryStream,
  FakeAccountRepository? repository,
  FakeCategoryRepository? categoryRepository,
  List<MonthlyPlan> plans = const [],
  FakePlanRepository? planRepository,
  FakeTransactionRepository? transactionRepository,
  List<CustomAccountType> customTypes = const [],
  FakeCustomAccountTypeRepository? customTypeRepository,
}) {
  final everyAccount = [...accounts, ...archived];
  Account? accountById(String id) {
    for (final account in everyAccount) {
      if (account.id == id) return account;
    }
    return null;
  }

  Transaction? transactionById(String id) {
    for (final transaction in transactions) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  return [
    // Signed-in widget tests get an empty in-memory synchronized store.
    syncedStoreOpenerProvider.overrideWithValue(
      (identity, spaceId) => FakeSyncedStore(identity, spaceId: spaceId),
    ),
    unsafeSyncedRowCountProvider.overrideWith((ref) => Stream.value(0)),
    refusedChangesProvider.overrideWith((ref) => Stream.value(const [])),
    activeAccountsProvider.overrideWith((ref) => Stream.value(accounts)),
    archivedAccountsProvider.overrideWith((ref) => Stream.value(archived)),
    allAccountsProvider.overrideWith((ref) => Stream.value(everyAccount)),
    accountByIdProvider.overrideWith(
      (ref, id) => Stream.value(accountById(id)),
    ),
    accountBalancesProvider.overrideWithValue(
      AsyncData(balancesFor(everyAccount, transactions)),
    ),
    accountRepositoryProvider.overrideWithValue(
      repository ?? FakeAccountRepository(),
    ),
    ...fakeCustomAccountTypes(customTypes, repository: customTypeRepository),
    allCategoriesProvider.overrideWith(
      (ref) => categoryStream ?? Stream.value(categories),
    ),
    categoryRepositoryProvider.overrideWithValue(
      categoryRepository ?? FakeCategoryRepository(),
    ),
    monthPlansProvider.overrideWith(
      (ref, month) => Stream.value([
        for (final plan in plans)
          if (plan.month == month) plan,
      ]),
    ),
    planRepositoryProvider.overrideWithValue(
      planRepository ?? FakePlanRepository(),
    ),
    allTransactionsProvider.overrideWith((ref) => Stream.value(transactions)),
    transactionsForAccountProvider.overrideWith(
      (ref, accountId) => Stream.value([
        for (final transaction in transactions)
          if (transaction.sourceAccountId == accountId ||
              transaction.destinationAccountId == accountId)
            transaction,
      ]),
    ),
    transactionByIdProvider.overrideWith(
      (ref, id) => Stream.value(transactionById(id)),
    ),
    transactionRepositoryProvider.overrideWithValue(
      transactionRepository ?? FakeTransactionRepository(),
    ),
  ];
}

/// No accounts or transactions at all.
List<Override> noAccounts() => fakeAccounts(const []);

/// Custom account types for widget tests that do not need [fakeAccounts].
List<Override> fakeCustomAccountTypes(
  List<CustomAccountType> types, {
  FakeCustomAccountTypeRepository? repository,
}) => [
  customAccountTypesProvider.overrideWith((ref) => Stream.value(types)),
  customAccountTypeRepositoryProvider.overrideWithValue(
    repository ?? FakeCustomAccountTypeRepository(),
  ),
];
