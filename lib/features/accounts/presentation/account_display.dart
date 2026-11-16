import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../domain/account_type.dart';

/// User-facing name for an [AccountType].
String accountTypeLabel(AccountType type) => switch (type) {
  AccountType.savingsCash => 'Savings / Cash',
  AccountType.credit => 'Credit',
  AccountType.loan => 'Loan',
};

/// Formats a signed balance (D1) the way the user thinks about it.
///
/// Asset accounts show the signed amount. Liabilities show money owed as a
/// positive "Owed" amount, and an overpaid liability as "Credit".
String formatBalance(AccountType type, Money balance) {
  if (!type.isLiability || balance.isZero) {
    return MoneyFormatter.format(balance);
  }
  return balance.isNegative
      ? 'Owed ${MoneyFormatter.format(-balance)}'
      : 'Credit ${MoneyFormatter.format(balance)}';
}
