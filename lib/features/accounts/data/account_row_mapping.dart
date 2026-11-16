import '../../../core/database/app_database.dart';
import '../../../core/money/money.dart';
import '../domain/account.dart';

extension AccountRowMapping on AccountRow {
  Account toDomain() => Account(
    id: id,
    name: name,
    type: type,
    openingBalance: Money(
      minorUnits: openingBalanceMinor,
      currencyCode: currencyCode,
    ),
    createdAt: createdAt.toUtc(),
    isArchived: isArchived,
  );
}
