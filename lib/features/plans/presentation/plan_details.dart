import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../domain/plan_summary.dart';
import 'plan_row.dart';

/// What the person chose in [showPlanDetailsSheet]. The caller acts on it
/// with its own context, after the sheet has closed.
enum PlanDetailsAction {
  editPlan,
  editTarget,
  editAssigned,
  showActivity,
  archive,
}

/// A plan's full picture for one month: its status in words, then Target,
/// Assigned, Activity and Available. The Plans rows show only Assigned and
/// Available; this is where the rest lives.
///
/// [onAction] makes Target and Assigned editable and Activity a link; `null`
/// shows read-only history, where only [onActivityTap] links anywhere.
class PlanDetails extends StatelessWidget {
  const PlanDetails({
    super.key,
    required this.summary,
    this.onAction,
    this.onActivityTap,
  });

  final CategoryPlanSummary summary;
  final ValueChanged<PlanDetailsAction>? onAction;
  final VoidCallback? onActivityTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final category = summary.category;
    final status = summary.status;
    final onAction = this.onAction;
    final onActivity =
        onActivityTap ??
        (onAction == null
            ? null
            : () => onAction(PlanDetailsAction.showActivity));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category.isArchivedInPlans
                      ? '${category.name} (archived)'
                      : category.name,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              if (status != null) PlanStatusChip(status: status),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        _DetailLine(
          label: 'Target',
          value: MoneyFormatter.format(
            summary.target ?? Money.zero(summary.assigned.currencyCode),
          ),
          onTap: onAction == null
              ? null
              : () => onAction(PlanDetailsAction.editTarget),
          tooltip: 'Edit ${category.name} target',
        ),
        _DetailLine(
          label: 'Assigned',
          value: MoneyFormatter.format(summary.assigned),
          // Shows how well the Target is funded, as the pill does on the row.
          color: summary.assigned.isZero
              ? colors.expense
              : switch (summary.isFunded) {
                  false => colors.warning,
                  true => colors.positive,
                  null => null,
                },
          onTap: onAction == null
              ? null
              : () => onAction(PlanDetailsAction.editAssigned),
          tooltip: 'Edit ${category.name} assigned',
        ),
        _DetailLine(
          label: 'Activity',
          value: MoneyFormatter.format(summary.activity),
          onTap: onActivity,
          tooltip: 'Show ${category.name} transactions',
          underline: true,
        ),
        _DetailLine(
          label: 'Available',
          value: MoneyFormatter.format(summary.available),
          color: summary.available.isNegative ? colors.expense : null,
        ),
      ],
    );
  }
}

/// Opens [summary]'s details for [monthLabel] in a bottom sheet. With
/// [editable], Target and Assigned can be edited and the plan archived; the
/// chosen action is returned, or `null` when the sheet is dismissed.
Future<PlanDetailsAction?> showPlanDetailsSheet(
  BuildContext context, {
  required CategoryPlanSummary summary,
  required String monthLabel,
  bool editable = true,
}) => showModalBottomSheet<PlanDetailsAction>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) {
    void choose(PlanDetailsAction action) => Navigator.of(context).pop(action);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Text(
                monthLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            PlanDetails(
              summary: summary,
              onAction: editable ? choose : null,
              onActivityTap: editable
                  ? null
                  : () => choose(PlanDetailsAction.showActivity),
            ),
            const SizedBox(height: Spacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (editable) ...[
                    FilledButton.icon(
                      onPressed: () => choose(PlanDetailsAction.editPlan),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit plan'),
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                  OutlinedButton.icon(
                    onPressed: () => choose(PlanDetailsAction.showActivity),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('See transactions'),
                  ),
                  if (editable)
                    TextButton.icon(
                      onPressed: () => choose(PlanDetailsAction.archive),
                      icon: const Icon(Icons.archive_outlined),
                      label: const Text('Archive plan'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);

/// A label on the left and its amount on the right. Tappable amounts are
/// tinted (or underlined when they open another screen).
class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
    this.color,
    this.onTap,
    this.tooltip,
    this.underline = false,
  });

  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linked = onTap != null;
    final line = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            // Large amounts shrink rather than overflow on narrow phones.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color ?? (linked ? theme.colorScheme.primary : null),
                  decoration: underline && linked
                      ? TextDecoration.underline
                      : null,
                ),
              ),
            ),
          ),
          if (linked) ...[
            const SizedBox(width: Spacing.xs),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
    return linked
        ? Tooltip(
            message: tooltip ?? label,
            child: InkWell(onTap: onTap, child: line),
          )
        : line;
  }
}
