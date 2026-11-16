import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transactions/presentation/transactions_providers.dart';
import '../data/category_repository.dart';
import '../domain/category.dart';

/// Categories of one [CategoryKind] in creation order, archived included.
final categoriesByKindProvider =
    StreamProvider.family<List<Category>, CategoryKind>(
      (ref, kind) => ref.watch(categoryRepositoryProvider).watchAll(kind: kind),
    );

/// Every category, keyed by id, for showing names. Empty while loading.
final categoriesByIdProvider = Provider<Map<int, Category>>((ref) {
  final categories = ref.watch(allCategoriesProvider).value ?? const [];
  return {for (final category in categories) category.id: category};
});

/// Every category in creation order, archived included.
final allCategoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// Ids of categories used by at least one transaction. These cannot be
/// deleted, only archived. Empty while loading.
final usedCategoryIdsProvider = Provider<Set<int>>((ref) {
  final transactions = ref.watch(allTransactionsProvider).value ?? const [];
  return {for (final transaction in transactions) ?transaction.categoryId};
});
