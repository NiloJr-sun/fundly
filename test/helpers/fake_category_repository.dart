import 'package:fundly/features/categories/data/category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/categories/domain/category_validation_exception.dart';

/// Records calls for widget tests, which cannot await a real drift database
/// under the fake test clock. Repository behaviour itself is covered by
/// `category_repository_test.dart` against an in-memory database.
class FakeCategoryRepository implements CategoryRepository {
  final List<({String name, CategoryKind kind, PlanGroup planGroup})> created =
      [];
  final List<({int id, PlanGroup planGroup})> groupChanges = [];
  final List<({int id, String name})> renamed = [];
  final List<({int id, bool archived})> archivedChanges = [];
  final List<int> deleted = [];

  /// When set, the next write throws this instead of saving.
  CategoryValidationError? failWith;

  @override
  Stream<List<Category>> watchAll({CategoryKind? kind}) =>
      Stream.value(const []);

  @override
  Future<Category> create({
    required String name,
    required CategoryKind kind,
    PlanGroup planGroup = PlanGroup.spending,
  }) async {
    _maybeFail();
    created.add((name: name, kind: kind, planGroup: planGroup));
    return Category(
      id: 100 + created.length,
      name: name.trim(),
      kind: kind,
      planGroup: planGroup,
    );
  }

  @override
  Future<Category> setPlanGroup(int id, PlanGroup planGroup) async {
    _maybeFail();
    groupChanges.add((id: id, planGroup: planGroup));
    return Category(
      id: id,
      name: '',
      kind: CategoryKind.spending,
      planGroup: planGroup,
    );
  }

  @override
  Future<Category> rename(int id, String name) async {
    _maybeFail();
    renamed.add((id: id, name: name));
    return Category(id: id, name: name.trim(), kind: CategoryKind.spending);
  }

  @override
  Future<void> setArchived(int id, {required bool archived}) async {
    _maybeFail();
    archivedChanges.add((id: id, archived: archived));
  }

  @override
  Future<void> delete(int id) async {
    _maybeFail();
    deleted.add(id);
  }

  void _maybeFail() {
    final error = failWith;
    if (error == null) return;
    failWith = null;
    throw CategoryValidationException(error);
  }
}
