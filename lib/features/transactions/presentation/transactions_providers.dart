import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/presentation/accounts_providers.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';
import '../domain/transaction_filter.dart';

/// Every transaction, newest first. Updates on create, edit and delete.
final allTransactionsProvider = StreamProvider<List<Transaction>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchAll(),
);

/// Transactions that touch one account (as source or destination), newest
/// first.
final transactionsForAccountProvider =
    StreamProvider.family<List<Transaction>, String>(
      (ref, accountId) => ref
          .watch(transactionRepositoryProvider)
          .watchAll(accountId: accountId),
    );

/// One transaction by id, or `null` if it does not exist.
final transactionByIdProvider = StreamProvider.family<Transaction?, String>(
  (ref, id) => ref.watch(transactionRepositoryProvider).watchById(id),
);

/// Filters for the all-transactions list. Each time the list is opened, the
/// filters reset to the filter the list was opened with (the family key).
class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  TransactionFilterNotifier(this.initial);

  final TransactionFilter initial;

  @override
  TransactionFilter build() => initial;

  void set(TransactionFilter filter) => state = filter;
}

/// Keyed by the filter the list was opened with; usually
/// [TransactionFilter.none].
final transactionFilterProvider = NotifierProvider.autoDispose
    .family<TransactionFilterNotifier, TransactionFilter, TransactionFilter>(
      TransactionFilterNotifier.new,
    );

/// Every transaction matching [transactionFilterProvider] for the same key,
/// newest first.
final filteredTransactionsProvider = Provider.autoDispose
    .family<AsyncValue<List<Transaction>>, TransactionFilter>((ref, initial) {
      final filter = ref.watch(transactionFilterProvider(initial));
      // Archived accounts included: their history can be filtered too.
      final accountTypes = {
        for (final account in ref.watch(accountsByIdProvider).values)
          account.id: account.type,
      };
      return ref
          .watch(allTransactionsProvider)
          .whenData(
            (transactions) =>
                filter.apply(transactions, accountTypes: accountTypes),
          );
    });
