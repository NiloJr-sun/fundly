import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/time/calendar_month.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/presentation/all_transactions_screen.dart';
import 'plans_providers.dart';

/// Live budget-account balance minus the selected month's remaining allocations.
/// Negative amounts warn of overallocation without preventing plan edits.
class ReadyToAssignCard extends ConsumerWidget {
  const ReadyToAssignCard({super.key, required this.month});

  final CalendarMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final budgetAccount = ref.watch(budgetAccountProvider);
    final ready = ref.watch(readyToAssignProvider(month));
    final Widget? amount;
    final Widget? details;
    switch (ready) {
      case AsyncData(value: final value?) when budgetAccount != null:
        final money = value.amount;
        amount = Text(
          MoneyFormatter.format(money),
          style: theme.textTheme.titleLarge?.copyWith(
            color: money.isNegative
                ? theme.colorScheme.error
                : money.minorUnits > 0
                ? AppColors.of(context).positive
                : null,
          ),
        );
        details = Text(
          '${budgetAccount.name} balance: ${MoneyFormatter.format(value.balance)}'
          '\nAssigned: ${MoneyFormatter.format(value.assigned)}'
          '\nRemaining: ${MoneyFormatter.format(value.remaining)}'
          '${money.isNegative ? '\nOverallocated by: ${MoneyFormatter.format(value.remaining - value.balance)}' : ''}',
        );
      case AsyncData():
        amount = null;
        details = const Text(
          "Choose a budget account in the Account tab to see what's ready "
          'to assign.',
        );
      case AsyncError():
        amount = const Text('—');
        details = const Text('Could not be calculated.');
      default:
        amount = const Text('…');
        details = null;
    }
    return Card(
      margin: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.sm,
        Spacing.md,
        Spacing.xs,
      ),
      child: ListTile(
        title: const Text('Ready to assign'),
        subtitle: details,
        trailing: amount,
        onTap: budgetAccount == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AllTransactionsScreen(
                    initialFilter: TransactionFilter(
                      dateRange: month.dateRange,
                      accountId: budgetAccount.id,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
