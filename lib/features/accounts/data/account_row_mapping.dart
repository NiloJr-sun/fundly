import '../../../core/database/app_database.dart';
import '../../../core/database/record_id.dart';
import '../../../core/money/money.dart';
import '../domain/account.dart';
import '../domain/custom_account_type.dart';

extension AccountRowMapping on AccountRow {
  Account toDomain() => Account(
    id: recordIdOf(id),
    name: name,
    type: type,
    openingBalance: Money(
      minorUnits: openingBalanceMinor,
      currencyCode: currencyCode,
    ),
    createdAt: createdAt.toUtc(),
    isArchived: isArchived,
    customTypeId: recordIdOrNull(customTypeId),
    isBudgetAccount: isBudgetAccount,
  );
}

extension CustomAccountTypeRowMapping on CustomAccountTypeRow {
  CustomAccountType toDomain() => CustomAccountType(
    id: recordIdOf(id),
    name: name,
    baseType: baseType,
    createdAt: createdAt.toUtc(),
  );
}
