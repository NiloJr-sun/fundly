import '../../../core/money/money.dart';
import '../../../core/money/money_parser.dart';
import '../domain/account_rules.dart';
import '../domain/account_type.dart';
import '../domain/account_validation_exception.dart';
import '../domain/custom_account_type_validation_exception.dart';

/// User-facing text for account form validation errors.

String accountNameErrorText(AccountNameError error) => switch (error) {
  AccountNameError.empty => 'Enter a name.',
  AccountNameError.tooLong => 'Use $maxAccountNameLength characters or fewer.',
};

String moneyParseErrorText(MoneyParseError error, String currencyCode) =>
    switch (error) {
      MoneyParseError.empty => 'Enter an amount.',
      MoneyParseError.invalid => 'Enter an amount like 1,234.50.',
      MoneyParseError.negative => 'Enter the amount without a minus sign.',
      MoneyParseError.tooManyDecimals =>
        'Use at most ${Money.decimalDigitsFor(currencyCode)} decimal places.',
      MoneyParseError.tooLarge => 'That amount is too large.',
    };

/// Message for an error reported by the repository on save.
String accountValidationErrorText(AccountValidationError error) =>
    switch (error) {
      AccountValidationError.nameEmpty => 'Enter a name.',
      AccountValidationError.nameTooLong =>
        'Use $maxAccountNameLength characters or fewer.',
      AccountValidationError.nameTaken =>
        'You already have an account with this name.',
      AccountValidationError.negativeOpeningBalance =>
        'Enter the amount without a minus sign.',
    };

/// Label for the opening balance field, which means "money owed" for
/// liabilities (D1).
String openingBalanceLabel(AccountType type) =>
    type.isLiability ? 'Amount owed' : 'Opening balance';

/// Message for an error reported when saving or deleting a custom type.
String customAccountTypeErrorText(CustomAccountTypeValidationError error) =>
    switch (error) {
      CustomAccountTypeValidationError.nameEmpty => 'Enter a name.',
      CustomAccountTypeValidationError.nameTooLong =>
        'Use $maxAccountNameLength characters or fewer.',
      CustomAccountTypeValidationError.nameTaken =>
        'An account type with this name already exists.',
      CustomAccountTypeValidationError.inUse =>
        'Accounts use this type, so it cannot be deleted.',
      CustomAccountTypeValidationError.baseTypeInUse =>
        "Accounts use this type, so its class can't change.",
    };
