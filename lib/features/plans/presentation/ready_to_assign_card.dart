import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/time/calendar_month.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/presentation/all_transactions_screen.dart';
import 'plans_providers.dart';

/// The month's income minus everything assigned, at the top of Plans.
/// Green when money is left to assign, red when more was assigned than
/// received. Tap to see the month's transactions.
class ReadyToAssignCard extends ConsumerWidget {
  const ReadyToAssignCard({super.key, required this.month});

  final CalendarMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ready = ref.watch(readyToAssignProvider(month));
    final Widget amount;
    final Widget? details;
    switch (ready) {
      case AsyncData(:final value):
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
          'Income ${MoneyFormatter.format(value.income)} − '
          'Assigned ${MoneyFormatter.format(value.assigned)}',
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
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AllTransactionsScreen(
              initialFilter: TransactionFilter(dateRange: month.dateRange),
            ),
          ),
        ),
      ),
    );
  }
}
