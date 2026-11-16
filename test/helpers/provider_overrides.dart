import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_balance.dart';
import 'package:fundly/features/accounts/presentation/accounts_providers.dart';
import 'package:fundly/features/categories/data/category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/categories/presentation/categories_providers.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/presentation/transactions_providers.dart';

import 'fake_account_repository.dart';
import 'fake_category_repository.dart';
import 'fake_transaction_repository.dart';

/// Overrides that keep widget tests off the real on-device database.
///
/// Account lookups by id search both [accounts] and [archived]. Balances come
/// from [balancesFor] over [transactions], exactly as in the app. Pass
/// [repository], [categoryRepository] or [transactionRepository] to inspect
/// what screens asked them to do.
List<Override> fakeAccounts(
  List<Account> accounts, {
  List<Account> archived = const [],
  List<Transaction> transactions = const [],
  List<Category> categories = const [],
  FakeAccountRepository? repository,
  FakeCategoryRepository? categoryRepository,
  FakeTransactionRepository? transactionRepository,
}) {
  final everyAccount = [...accounts, ...archived];
  Account? accountById(int id) {
    for (final account in everyAccount) {
      if (account.id == id) return account;
    }
    return null;
  }

  Transaction? transactionById(int id) {
    for (final transaction in transactions) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  return [
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
    allCategoriesProvider.overrideWith((ref) => Stream.value(categories)),
    categoryRepositoryProvider.overrideWithValue(
      categoryRepository ?? FakeCategoryRepository(),
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
