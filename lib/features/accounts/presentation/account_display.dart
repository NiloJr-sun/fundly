import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../domain/account_type.dart';

/// User-facing name for an [AccountType].
String accountTypeLabel(AccountType type) => switch (type) {
  AccountType.savingsCash => 'Savings / Cash',
  AccountType.credit => 'Credit',
  AccountType.loan => 'Loan',
};

/// Formats a signed balance (D1) as is: money owed on Credit and Loan
/// accounts shows with a minus sign, e.g. `-₱3,000.00`.
String formatBalance(Money balance) => MoneyFormatter.format(balance);

/// A balance in [style], green when positive and the default text colour
/// otherwise.
class BalanceText extends StatelessWidget {
  const BalanceText(this.balance, {super.key, this.style});

  final Money balance;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final positive = balance.minorUnits > 0;
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text(
      formatBalance(balance),
      style: positive
          ? base.copyWith(color: AppColors.of(context).positive)
          : base,
    );
  }
}
