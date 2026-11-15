import '../../../core/money/money.dart';
import 'account.dart';
import 'account_type.dart';

/// Longest allowed account name, after trimming.
const int maxAccountNameLength = 40;

/// Why an account name is not acceptable.
enum AccountNameError {
  /// Empty, or only whitespace.
  empty,

  /// Longer than [maxAccountNameLength] characters after trimming.
  tooLong,
}

/// Checks a user-entered account name. Returns `null` when it is valid.
///
/// Callers must store `name.trim()`. Uniqueness is checked by the data layer,
/// which can see the other accounts.
AccountNameError? validateAccountName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return AccountNameError.empty;
  if (trimmed.length > maxAccountNameLength) return AccountNameError.tooLong;
  return null;
}

/// Converts the amount the user enters as an opening balance into the signed
/// value stored on the account (CLAUDE.md §11, D1).
///
/// The user always enters a zero or positive amount: money held for asset
/// accounts, money owed for liabilities. Liabilities are stored negated.
///
/// Throws [ArgumentError] if [enteredAmount] is negative.
Money openingBalanceFor(AccountType type, Money enteredAmount) {
  if (enteredAmount.isNegative) {
    throw ArgumentError.value(
      enteredAmount,
      'enteredAmount',
      'Opening balance must be entered as zero or a positive amount.',
    );
  }
  return type.isLiability ? -enteredAmount : enteredAmount;
}

/// The opening balance as the user would enter it: the reverse of
/// [openingBalanceFor]. Used to pre-fill the edit form.
Money enteredAmountFor(Account account) =>
    account.type.isLiability ? -account.openingBalance : account.openingBalance;
