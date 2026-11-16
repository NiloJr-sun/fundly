import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/category_repository.dart';
import '../domain/category.dart';

/// Categories of one [CategoryKind], in their seeded order.
final categoriesByKindProvider =
    StreamProvider.family<List<Category>, CategoryKind>(
      (ref, kind) => ref.watch(categoryRepositoryProvider).watchAll(kind: kind),
    );

/// Every category, keyed by id, for showing names. Empty while loading.
final categoriesByIdProvider = Provider<Map<int, Category>>((ref) {
  final categories = ref.watch(allCategoriesProvider).value ?? const [];
  return {for (final category in categories) category.id: category};
});

/// Every category in seeded order.
final allCategoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);
