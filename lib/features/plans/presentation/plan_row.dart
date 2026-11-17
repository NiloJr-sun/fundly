import 'package:flutter/material.dart';

import '../../../core/formatting/money_formatter.dart';
import '../domain/plan_summary.dart';

/// One category's planned vs actual spending. [onTap] is `null` when the plan
/// cannot be edited (an archived category without a plan).
class PlanRow extends StatelessWidget {
  const PlanRow({super.key, required this.summary, required this.onTap});

  final CategoryPlanSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Until the row shows every column, the target reads as "planned" and
    // available as "left".
    final planned = summary.target;
    final remaining = planned == null ? null : summary.available;
    final spent = MoneyFormatter.format(summary.activity);
    final category = summary.category;

    return ListTile(
      title: Text(
        category.isArchived ? '${category.name} (archived)' : category.name,
      ),
      subtitle: Text(
        planned == null
            ? 'Spent $spent · No plan'
            : 'Spent $spent of ${MoneyFormatter.format(planned)}',
      ),
      trailing: remaining == null
          ? (onTap == null ? null : const Text('Set plan'))
          : Text(
              summary.isOverspent
                  ? '${MoneyFormatter.format(-remaining)} over'
                  : '${MoneyFormatter.format(remaining)} left',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: summary.isOverspent ? theme.colorScheme.error : null,
              ),
            ),
      onTap: onTap,
    );
  }
}
