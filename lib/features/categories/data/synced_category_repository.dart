import 'package:drift/drift.dart';

import '../../../core/sync/synced_database.dart';
import '../../../core/sync/synced_store.dart';
import '../domain/category.dart';
import 'category_repository.dart';

/// Categories from the signed-in user's synchronized store. Read-only until
/// sync uploads arrive (S5.3).
class SyncedCategoryRepository implements CategoryRepository {
  SyncedCategoryRepository(this._database);

  final SyncedDatabase _database;

  /// Creation order, like the local store; UUIDs only break ties.
  @override
  Stream<List<Category>> watchAll({CategoryKind? kind}) {
    final query = _database.select(_database.syncedCategories)
      ..where(
        (_) => CustomExpression<bool>('NOT (${unsafe('categories.revision')})'),
      )
      ..orderBy([
        (category) => OrderingTerm(expression: category.createdAt),
        (category) => OrderingTerm(expression: category.id),
      ]);
    if (kind != null) {
      query.where((category) => category.kind.equals(kind.name));
    }
    return query.watch().map(
      (rows) => [for (final row in rows) syncedCategory(row)],
    );
  }

  /// Every write is unavailable until sync uploads arrive (S5.3), which
  /// replace this with real operations.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw const ReadOnlyStoreException();
}

Category syncedCategory(SyncedCategoryRow row) => Category(
  id: row.id,
  name: row.name,
  kind: CategoryKind.values.byName(row.kind),
  isArchived: row.isArchived,
  isPlanArchived: row.isPlanArchived,
  isPlanDeleted: row.isPlanDeleted,
  planGroup: PlanGroup.values.byName(row.planGroup),
  linkedAccountId: row.linkedAccountId,
);
