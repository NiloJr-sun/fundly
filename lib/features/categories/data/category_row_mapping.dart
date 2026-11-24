import '../../../core/database/app_database.dart';
import '../../../core/database/record_id.dart';
import '../../../core/money/money.dart';
import '../../accounts/domain/account.dart';
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
    defaultTarget: defaultTargetOf(defaultTargetMinor),
  );
}

/// Categories hold no currency; every amount is PHP for now (G6).
Money? defaultTargetOf(int? minorUnits) => minorUnits == null
    ? null
    : Money(minorUnits: minorUnits, currencyCode: Account.defaultCurrency);
