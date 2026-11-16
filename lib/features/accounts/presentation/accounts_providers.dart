import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_repository.dart';
import '../domain/account.dart';

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
