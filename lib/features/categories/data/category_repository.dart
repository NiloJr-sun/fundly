import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/record_id.dart';
import '../../../core/sync/synced_store.dart';
import '../domain/category.dart';
import '../domain/category_rules.dart';
import '../domain/category_validation_exception.dart';
import 'category_row_mapping.dart';
import 'synced_category_repository.dart';

/// Reads and writes [Category]s, enforcing the category rules before anything
/// reaches the database.
class CategoryRepository {
  CategoryRepository(this._database);

  final AppDatabase _database;

  $CategoriesTable get _categories => _database.categories;

  /// Categories in creation order (seeded ones first), optionally only those
  /// of [kind]. Archived categories are included: callers decide whether to
  /// show them, and transaction validation must see them.
  Stream<List<Category>> watchAll({CategoryKind? kind}) {
    final query = _database.select(_categories)
      ..orderBy([(category) => OrderingTerm(expression: category.id)]);
    if (kind != null) {
      query.where((category) => category.kind.equalsValue(kind));
    }
    return query.watch().map(
      (rows) => [for (final row in rows) row.toDomain()],
    );
  }

  /// Creates a category. Spending categories go into [planGroup] on the
  /// Plans page; inflow categories are not planned and must keep the default.
  ///
  /// Throws [CategoryValidationException] when a rule is broken, or
  /// [ArgumentError] for a non-default group on an inflow category.
  Future<Category> create({
    required String name,
    required CategoryKind kind,
    PlanGroup planGroup = PlanGroup.spending,
  }) async {
    _requireGroupAllowed(kind, planGroup);
    final trimmedName = await _validName(name);
    final row = await _database
        .into(_categories)
        .insertReturning(
          CategoriesCompanion.insert(
            name: trimmedName,
            kind: kind,
            planGroup: Value(planGroup),
          ),
        );
    return row.toDomain();
  }

  /// Moves spending category [id] to [planGroup] on the Plans page. Only
  /// organises the page; plans and activity are unchanged.
  ///
  /// Throws [ArgumentError] for an inflow category, or [StateError] if the
  /// category does not exist.
  Future<Category> setPlanGroup(
    String id,
    PlanGroup planGroup,
  ) => _database.transaction(() async {
    final existing = await (_database.select(
      _categories,
    )..where((category) => category.id.equals(rowIdOf(id)))).getSingleOrNull();
    if (existing == null) throw StateError('Category $id does not exist.');
    if (existing.linkedAccountId != null) {
      throw StateError('Manage this Plans row through its account.');
    }
    _requireGroupAllowed(existing.kind, planGroup);
    final rows =
        await (_database.update(_categories)
              ..where((category) => category.id.equals(rowIdOf(id))))
            .writeReturning(CategoriesCompanion(planGroup: Value(planGroup)));
    return rows.single.toDomain();
  });

  /// Inflow categories are never planned, so they stay in the default group.
  /// The UI only offers groups for spending, so this is a programming error.
  static void _requireGroupAllowed(CategoryKind kind, PlanGroup planGroup) {
    if (kind == CategoryKind.inflow && planGroup != PlanGroup.spending) {
      throw ArgumentError.value(
        planGroup,
        'planGroup',
        'Inflow categories are not planned and have no group.',
      );
    }
  }

  /// Renames category [id]. The kind cannot change.
  ///
  /// Throws [CategoryValidationException] when a rule is broken, or
  /// [StateError] if the category does not exist.
  Future<Category> rename(String id, String name) async {
    await _requireUnlinked(id);
    final trimmedName = await _validName(name, excludingId: id);
    final rows =
        await (_database.update(_categories)
              ..where((category) => category.id.equals(rowIdOf(id))))
            .writeReturning(CategoriesCompanion(name: Value(trimmedName)));
    if (rows.isEmpty) throw StateError('Category $id does not exist.');
    return rows.single.toDomain();
  }

  /// Archives or restores category [id]. Archived categories keep their
  /// history but cannot be used by new transactions.
  ///
  /// Throws [StateError] if the category does not exist.
  Future<void> setArchived(String id, {required bool archived}) async {
    await _requireUnlinked(id);
    final changed =
        await (_database.update(_categories)
              ..where((category) => category.id.equals(rowIdOf(id))))
            .write(CategoriesCompanion(isArchived: Value(archived)));
    if (changed == 0) throw StateError('Category $id does not exist.');
  }

  /// Deletes category [id] if no transaction uses it. Its monthly plans are
  /// deleted with it (the foreign key cascades).
  ///
  /// Throws [CategoryValidationException] with
  /// [CategoryValidationError.inUse] if a transaction uses it, or
  /// [StateError] if the category does not exist.
  Future<void> delete(String id) => _database.transaction(() async {
    await _requireUnlinked(id);
    final transactions = _database.transactions;
    final usage = transactions.id.count();
    final count =
        await (_database.selectOnly(transactions)
              ..addColumns([usage])
              ..where(transactions.categoryId.equals(rowIdOf(id))))
            .map((row) => row.read(usage)!)
            .getSingle();
    if (count > 0) {
      throw const CategoryValidationException(CategoryValidationError.inUse);
    }
    final deleted = await (_database.delete(
      _categories,
    )..where((category) => category.id.equals(rowIdOf(id)))).go();
    if (deleted == 0) throw StateError('Category $id does not exist.');
  });

  Future<void> _requireUnlinked(String id) async {
    final row = await (_database.select(
      _categories,
    )..where((category) => category.id.equals(rowIdOf(id)))).getSingleOrNull();
    if (row?.linkedAccountId != null) {
      throw StateError('Manage this Plans row through its account.');
    }
  }

  /// Returns the trimmed name, or throws if it is invalid or already used.
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
    // The column is COLLATE NOCASE, so this comparison ignores case.
    final query = _database.select(_categories)
      ..where((category) {
        final sameName = category.name.equals(trimmed);
        return excludingId == null
            ? sameName
            : sameName & category.id.equals(rowIdOf(excludingId)).not();
      });
    if (await query.getSingleOrNull() != null) {
      throw const CategoryValidationException(
        CategoryValidationError.nameTaken,
      );
    }
    return trimmed;
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final synced = ref.watch(syncedStoreProvider);
  return synced == null
      ? CategoryRepository(ref.watch(appDatabaseProvider))
      : SyncedCategoryRepository(synced.database);
});
