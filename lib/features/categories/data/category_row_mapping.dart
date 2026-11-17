import '../../../core/database/app_database.dart';
import '../domain/category.dart';

extension CategoryRowMapping on CategoryRow {
  Category toDomain() => Category(
    id: id,
    name: name,
    kind: kind,
    isArchived: isArchived,
    planGroup: planGroup,
  );
}
