import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/transaction_repository.dart';
import '../domain/transaction.dart';

/// Every transaction, newest first. Updates on create, edit and delete.
final allTransactionsProvider = StreamProvider<List<Transaction>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchAll(),
);

/// Transactions that touch one account (as source or destination), newest
/// first.
final transactionsForAccountProvider =
    StreamProvider.family<List<Transaction>, int>(
      (ref, accountId) => ref
          .watch(transactionRepositoryProvider)
          .watchAll(accountId: accountId),
    );

/// One transaction by id, or `null` if it does not exist.
final transactionByIdProvider = StreamProvider.family<Transaction?, int>(
  (ref, id) => ref.watch(transactionRepositoryProvider).watchById(id),
);
