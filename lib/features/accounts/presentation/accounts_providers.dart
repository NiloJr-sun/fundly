import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../transactions/presentation/transactions_providers.dart';

import '../data/account_repository.dart';
import '../data/custom_account_type_repository.dart';
import '../domain/account.dart';
import '../domain/account_balance.dart';
import '../domain/custom_account_type.dart';

/// Active accounts, ordered by type then name. Updates when accounts change.
final activeAccountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountRepositoryProvider).watchAll(),
);

/// Archived accounts, ordered by type then name.
final archivedAccountsProvider = StreamProvider<List<Account>>(
  (ref) => ref
      .watch(accountRepositoryProvider)
      .watchAll(includeArchived: true)
      .map(
        (accounts) => accounts.where((account) => account.isArchived).toList(),
      ),
);

/// One account by id, or `null` if it does not exist.
final accountByIdProvider = StreamProvider.family<Account?, String>(
  (ref, id) => ref.watch(accountRepositoryProvider).watchById(id),
);

/// Every account, active and archived. Balances need archived accounts too.
final allAccountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountRepositoryProvider).watchAll(includeArchived: true),
);

/// Current balance of every account, keyed by id, from [balancesFor].
///
/// Recomputes whenever an account or a transaction changes (rule 11).
final accountBalancesProvider = Provider<AsyncValue<Map<String, Money>>>((ref) {
  final accounts = ref.watch(allAccountsProvider);
  final transactions = ref.watch(allTransactionsProvider);
  return switch ((accounts, transactions)) {
    (AsyncData(value: final a), AsyncData(value: final t)) => AsyncData(
      balancesFor(a, t),
    ),
    (AsyncError(:final error, :final stackTrace), _) ||
    (
      _,
      AsyncError(:final error, :final stackTrace),
    ) => AsyncError(error, stackTrace),
    _ => const AsyncLoading(),
  };
});

/// Every account (including archived), keyed by id, for showing names.
/// Empty while loading.
final accountsByIdProvider = Provider<Map<String, Account>>((ref) {
  final accounts = ref.watch(allAccountsProvider).value ?? const [];
  return {for (final account in accounts) account.id: account};
});

/// Every custom account type, ordered by name.
final customAccountTypesProvider = StreamProvider<List<CustomAccountType>>(
  (ref) => ref.watch(customAccountTypeRepositoryProvider).watchAll(),
);

/// Every custom account type keyed by id, for showing names. Empty while
/// loading.
final customAccountTypesByIdProvider = Provider<Map<String, CustomAccountType>>(
  (ref) {
    final types = ref.watch(customAccountTypesProvider).value ?? const [];
    return {for (final type in types) type.id: type};
  },
);

/// How many accounts, active or archived, use each custom type, keyed by
/// custom type id. Types without accounts are absent. Empty while loading.
final customTypeAccountCountsProvider = Provider<Map<String, int>>((ref) {
  final accounts = ref.watch(allAccountsProvider).value ?? const [];
  final counts = <String, int>{};
  for (final account in accounts) {
    final id = account.customTypeId;
    if (id != null) counts[id] = (counts[id] ?? 0) + 1;
  }
  return counts;
});

/// The budget account, whose money in funds Ready to assign, or `null`
/// when none is chosen. `null` while loading.
final budgetAccountProvider = Provider<Account?>((ref) {
  final accounts = ref.watch(allAccountsProvider).value ?? const [];
  for (final account in accounts) {
    if (account.isBudgetAccount) return account;
  }
  return null;
});
