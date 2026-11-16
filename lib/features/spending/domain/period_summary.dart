import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import '../../../core/time/date_range.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_type.dart';
import '../../transactions/domain/transaction.dart';

/// Inflow and spending totals for a period. Both are zero or positive.
typedef PeriodTotals = ({Money inflow, Money spending});

/// Totals for transactions dated within [range].
///
/// Only Spending and Inflow count; transfers and credit-card payments move
/// money between the user's own accounts and are excluded (rule 5). A card
/// purchase is Spending, so it is counted once; paying the card later is not
/// counted again (rule 6). Transactions on archived accounts still count:
/// they are real history.
PeriodTotals periodTotals(
  Iterable<TransactionDraft> transactions,
  DateRange range, {
  String currencyCode = Account.defaultCurrency,
}) {
  var inflow = Money.zero(currencyCode);
  var spending = Money.zero(currencyCode);
  for (final transaction in transactions) {
    if (!range.contains(transaction.date)) continue;
    if (transaction.type.countsAsSpending) {
      spending += transaction.amount;
    } else if (transaction.type.countsAsInflow) {
      inflow += transaction.amount;
    }
  }
  return (inflow: inflow, spending: spending);
}

/// The headline balance figures on the Spending tab (CLAUDE.md §11, D2).
@immutable
final class BalanceSummary {
  const BalanceSummary({
    required this.availableMoney,
    required this.creditOwed,
    required this.loansOwed,
  });

  /// Total of active Savings/Cash balances. Can be negative if an account is
  /// overdrawn.
  final Money availableMoney;

  /// Amount owed across active credit accounts, as a positive number. Negative
  /// only if the cards are overpaid overall.
  final Money creditOwed;

  /// Amount owed across active loans, as a positive number.
  final Money loansOwed;

  @override
  bool operator ==(Object other) =>
      other is BalanceSummary &&
      other.availableMoney == availableMoney &&
      other.creditOwed == creditOwed &&
      other.loansOwed == loansOwed;

  @override
  int get hashCode => Object.hash(availableMoney, creditOwed, loansOwed);

  @override
  String toString() =>
      'BalanceSummary(available: $availableMoney, credit: $creditOwed, '
      'loans: $loansOwed)';
}

/// Summarises [balances] (from `balancesFor`) for active [accounts] only;
/// archived accounts are hidden from summaries (G7). Accounts missing from
/// [balances] are skipped.
BalanceSummary summarizeBalances(
  Iterable<Account> accounts,
  Map<int, Money> balances, {
  String currencyCode = Account.defaultCurrency,
}) {
  final totals = {
    for (final type in AccountType.values) type: Money.zero(currencyCode),
  };
  for (final account in accounts) {
    final balance = balances[account.id];
    if (account.isArchived || balance == null) continue;
    totals[account.type] = totals[account.type]! + balance;
  }
  // Liability balances are negative when money is owed (D1); show owed
  // amounts as positive.
  return BalanceSummary(
    availableMoney: totals[AccountType.savingsCash]!,
    creditOwed: -totals[AccountType.credit]!,
    loansOwed: -totals[AccountType.loan]!,
  );
}
