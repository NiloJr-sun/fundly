import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../transactions/presentation/transactions_providers.dart';

import '../data/account_repository.dart';
import '../domain/account.dart';
import '../domain/account_balance.dart';

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
final accountByIdProvider = StreamProvider.family<Account?, int>(
  (ref, id) => ref.watch(accountRepositoryProvider).watchById(id),
);

/// Every account, active and archived. Balances need archived accounts too.
final allAccountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountRepositoryProvider).watchAll(includeArchived: true),
);

/// Current balance of every account, keyed by id, from [balancesFor].
///
/// Recomputes whenever an account or a transaction changes (rule 11).
final accountBalancesProvider = Provider<AsyncValue<Map<int, Money>>>((ref) {
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
final accountsByIdProvider = Provider<Map<int, Account>>((ref) {
  final accounts = ref.watch(allAccountsProvider).value ?? const [];
  return {for (final account in accounts) account.id: account};
});
