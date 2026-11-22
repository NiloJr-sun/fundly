import 'package:drift/drift.dart';

import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/synced_database.dart';
import '../domain/category.dart';
import '../domain/category_rules.dart';
import '../domain/category_validation_exception.dart';
import 'category_repository.dart';

/// Categories in the signed-in user's synchronized store. Writes apply
/// locally at once and queue the matching operation for upload (S5.3), with
/// the same rules as the local store.
class SyncedCategoryRepository implements CategoryRepository {
  SyncedCategoryRepository(this._database, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final SyncedDatabase _database;
  final DateTime Function() _now;

  $SyncedCategoriesTable get _categories => _database.syncedCategories;

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

  @override
  Future<Category> create({
    required String name,
    required CategoryKind kind,
    PlanGroup planGroup = PlanGroup.spending,
  }) => _database.writeAndQueue(() async {
    _requireGroupAllowed(kind, planGroup);
    final trimmedName = await _validName(name);
    final id = newRecordId();
    final now = syncedTimestamp(_now());
    final row = await _database
        .into(_categories)
        .insertReturning(
          SyncedCategoriesCompanion.insert(
            id: id,
            name: trimmedName,
            kind: kind.name,
            isArchived: false,
            isPlanArchived: false,
            isPlanDeleted: false,
            planGroup: planGroup.name,
            createdAt: now,
            updatedAt: now,
            revision: 1,
          ),
        );
    return (
      syncedCategory(row),
      [
        SyncOperation(
          'category.create',
          id,
          data: {
            'name': trimmedName,
            'kind': kind.name,
            'plan_group': planGroup.name,
          },
        ),
      ],
    );
  });

  @override
  Future<Category> setPlanGroup(String id, PlanGroup planGroup) =>
      _database.writeAndQueue(() async {
        final existing = await _findUnlinked(id);
        _requireGroupAllowed(
          CategoryKind.values.byName(existing.kind),
          planGroup,
        );
        final row = await _update(
          existing,
          SyncedCategoriesCompanion(planGroup: Value(planGroup.name)),
        );
        return (
          syncedCategory(row),
          [
            SyncOperation(
              'category.update',
              id,
              expectedRevision: existing.revision,
              data: {'plan_group': planGroup.name},
            ),
          ],
        );
      });

  @override
  Future<Category> rename(String id, String name) =>
      _database.writeAndQueue(() async {
        final existing = await _findUnlinked(id);
        final trimmedName = await _validName(name, excludingId: id);
        final row = await _update(
          existing,
          SyncedCategoriesCompanion(name: Value(trimmedName)),
        );
        return (
          syncedCategory(row),
          [
            SyncOperation(
              'category.update',
              id,
              expectedRevision: existing.revision,
              data: {'name': trimmedName},
            ),
          ],
        );
      });

  @override
  Future<void> setArchived(String id, {required bool archived}) =>
      _database.writeAndQueue(() async {
        final existing = await _findUnlinked(id);
        await _update(
          existing,
          SyncedCategoriesCompanion(isArchived: Value(archived)),
        );
        return (
          null,
          [
            SyncOperation(
              'category.set_archived',
              id,
              expectedRevision: existing.revision,
              data: {'archived': archived},
            ),
          ],
        );
      });

  /// Deletes the category and its monthly plans, as the server does.
  @override
  Future<void> delete(String id) => _database.writeAndQueue(() async {
    final existing = await _findUnlinked(id);
    final transactions = _database.syncedTransactions;
    final usage = transactions.id.count();
    final count =
        await (_database.selectOnly(transactions)
              ..addColumns([usage])
              ..where(transactions.categoryId.equals(id)))
            .map((row) => row.read(usage)!)
            .getSingle();
    if (count > 0) {
      throw const CategoryValidationException(CategoryValidationError.inUse);
    }
    await (_database.delete(
      _database.syncedMonthlyPlans,
    )..where((plan) => plan.categoryId.equals(id))).go();
    await (_database.delete(
      _categories,
    )..where((category) => category.id.equals(id))).go();
    return (
      null,
      [
        SyncOperation(
          'category.delete',
          id,
          expectedRevision: existing.revision,
        ),
      ],
    );
  });

  /// Linked liability rows are managed through their account.
  Future<SyncedCategoryRow> _findUnlinked(String id) async {
    final row = await (_database.select(
      _categories,
    )..where((category) => category.id.equals(id))).getSingleOrNull();
    if (row == null) throw StateError('Category $id does not exist.');
    if (row.linkedAccountId != null) {
      throw StateError('Manage this Plans row through its account.');
    }
    return row;
  }

  Future<SyncedCategoryRow> _update(
    SyncedCategoryRow existing,
    SyncedCategoriesCompanion changes,
  ) async {
    final rows =
        await (_database.update(
          _categories,
        )..where((category) => category.id.equals(existing.id))).writeReturning(
          changes.copyWith(
            updatedAt: Value(syncedTimestamp(_now())),
            revision: Value(nextRevision(existing.revision)),
          ),
        );
    return rows.single;
  }

  static void _requireGroupAllowed(CategoryKind kind, PlanGroup planGroup) {
    if (kind == CategoryKind.inflow && planGroup != PlanGroup.spending) {
      throw ArgumentError.value(
        planGroup,
        'planGroup',
        'Inflow categories are not planned and have no group.',
      );
    }
  }

  Future<String> _validName(String name, {String? excludingId}) async {
    switch (validateCategoryName(name)) {
      case CategoryNameError.empty:
        throw const CategoryValidationException(
          CategoryValidationError.nameEmpty,
        );
      case CategoryNameError.tooLong:
        throw const CategoryValidationException(
          CategoryValidationError.nameTooLong,
        );
      case null:
        break;
    }
    final trimmed = name.trim();
    final query = _database.select(_categories)
      ..where((category) {
        final sameName = sameNameAs(category.name, trimmed);
        return excludingId == null
            ? sameName
            : sameName & category.id.equals(excludingId).not();
      });
    if ((await query.get()).isNotEmpty) {
      throw const CategoryValidationException(
        CategoryValidationError.nameTaken,
      );
    }
    return trimmed;
  }
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
