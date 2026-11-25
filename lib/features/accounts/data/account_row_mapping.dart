import '../../../core/database/app_database.dart';
import '../../../core/database/record_id.dart';
import '../../../core/money/money.dart';
import '../domain/account.dart';
import '../domain/custom_account_type.dart';
import '../domain/custom_bank.dart';

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
    bankKey: bankKey,
    customBankId: recordIdOrNull(customBankId),
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

extension CustomBankRowMapping on CustomBankRow {
  CustomBank toDomain() =>
      CustomBank(id: recordIdOf(id), name: name, createdAt: createdAt.toUtc());
}
