import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/category.dart';
import 'category_row_mapping.dart';

/// Reads [Category]s. The list is fixed in Phase 2 (G1), so there are no
/// write methods yet.
class CategoryRepository {
  CategoryRepository(this._database);

  final AppDatabase _database;

  /// Categories in their seeded order, optionally only those of [kind].
  Stream<List<Category>> watchAll({CategoryKind? kind}) {
    final query = _database.select(_database.categories)
      ..orderBy([(category) => OrderingTerm(expression: category.id)]);
    if (kind != null) {
      query.where((category) => category.kind.equalsValue(kind));
    }
    return query.watch().map(
      (rows) => [for (final row in rows) row.toDomain()],
    );
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(appDatabaseProvider)),
);
