import '../../../core/database/app_database.dart';
import '../../../core/database/record_id.dart';
import '../domain/category.dart';

extension CategoryRowMapping on CategoryRow {
  Category toDomain() => Category(
    id: recordIdOf(id),
    name: name,
    kind: kind,
    isArchived: isArchived,
    isPlanArchived: isPlanArchived,
    isPlanDeleted: isPlanDeleted,
    planGroup: planGroup,
    linkedAccountId: recordIdOrNull(linkedAccountId),
  );
}
