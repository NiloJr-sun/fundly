import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import 'plans_providers.dart';

/// Previous / next month arrows around the selected month, with a shortcut
/// back to the current month.
class PlanMonthBar extends ConsumerWidget {
  const PlanMonthBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedPlanMonthProvider);
    final isCurrent = ref.watch(isCurrentPlanMonthProvider);
    final notifier = ref.read(selectedPlanMonthProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            icon: const Icon(Icons.chevron_left),
            onPressed: notifier.previous,
          ),
          Expanded(
            child: Text(
              DateFormatter.monthYear(month.year, month.month),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            icon: const Icon(Icons.chevron_right),
            onPressed: notifier.next,
          ),
          if (!isCurrent)
            TextButton(
              onPressed: notifier.thisMonth,
              child: const Text('This month'),
            ),
        ],
      ),
    );
  }
}
