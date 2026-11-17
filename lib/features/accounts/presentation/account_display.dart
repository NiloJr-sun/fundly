import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../domain/account.dart';
import '../domain/account_type.dart';
import '../domain/custom_account_type.dart';

/// User-facing name for an [AccountType].
String accountTypeLabel(AccountType type) => switch (type) {
  AccountType.savingsCash => 'Savings / Cash',
  AccountType.credit => 'Credit',
  AccountType.loan => 'Loan',
};

/// User-facing name for an [AccountClass], used as a heading.
String accountClassLabel(AccountClass accountClass) => switch (accountClass) {
  AccountClass.asset => 'Assets',
  AccountClass.liability => 'Liabilities',
};

/// What an account type does, for a built-in type or a custom type based on
/// [type].
String accountTypeDescription(AccountType type) => switch (type) {
  AccountType.savingsCash => 'Asset: money you hold.',
  AccountType.credit => 'Liability: works like a credit card.',
  AccountType.loan => 'Liability: works like a loan.',
};

/// The type name shown for [account]: its custom type's name when it has
/// one in [customTypes], otherwise its built-in type's label.
String accountTypeName(
  Account account,
  Map<int, CustomAccountType> customTypes,
) => customTypes[account.customTypeId]?.name ?? accountTypeLabel(account.type);

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
