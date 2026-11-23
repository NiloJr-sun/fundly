import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../domain/plan_summary.dart';
import 'plan_editor_dialog.dart';

/// One category's target, assigned, activity and available amounts, with its
/// status.
///
/// [onEdit] edits the whole plan (`field` null) or one amount, and is `null`
/// when showing read-only archived history.
/// [onActivityTap] shows the transactions behind the activity amount.
/// Available is derived, so it is not editable.
class PlanRow extends StatelessWidget {
  const PlanRow({
    super.key,
    required this.summary,
    required this.onEdit,
    required this.onActivityTap,
    this.onArchive,
  });

  final CategoryPlanSummary summary;
  final void Function(PlanAmountField? field)? onEdit;
  final VoidCallback onActivityTap;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = summary.category;
    final target = summary.target;
    final status = summary.status;
    final onEdit = this.onEdit;

    return InkWell(
      onTap: onEdit == null ? null : () => onEdit(null),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category.isArchivedInPlans
                        ? '${category.name} (archived)'
                        : category.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (status != null) PlanStatusChip(status: status),
                if (onArchive != null)
                  PopupMenuButton<String>(
                    tooltip: '${category.name} plan actions',
                    onSelected: (_) => onArchive!(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'archive',
                        child: Text('Archive plan'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Row(
              children: [
                _Amount(
                  label: 'Target',
                  value: MoneyFormatter.format(
                    target ?? Money.zero(summary.assigned.currencyCode),
                  ),
                  onTap: onEdit == null
                      ? null
                      : () => onEdit(PlanAmountField.target),
                  tooltip: 'Edit ${category.name} target',
                ),
                _Amount(
                  label: 'Assigned',
                  value: MoneyFormatter.format(summary.assigned),
                  color: summary.assigned.isZero
                      ? theme.colorScheme.error
                      : switch (summary.isFunded) {
                          false => AppColors.of(context).warning,
                          true => AppColors.of(context).positive,
                          null => theme.colorScheme.onSurface,
                        },
                  onTap: onEdit == null
                      ? null
                      : () => onEdit(PlanAmountField.assigned),
                  tooltip: 'Edit ${category.name} assigned',
                ),
                _Amount(
                  label: 'Activity',
                  value: MoneyFormatter.format(summary.activity),
                  onTap: onActivityTap,
                  tooltip: 'Show ${category.name} transactions',
                  underline: true,
                ),
                _Amount(
                  label: 'Available',
                  value: MoneyFormatter.format(summary.available),
                  color: _availableColor(theme.colorScheme, summary.available),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color? _availableColor(ColorScheme colors, Money available) =>
      available.isNegative ? colors.error : null;
}

/// "Funded", "Underfunded" or "Overspent".
class PlanStatusChip extends StatelessWidget {
  const PlanStatusChip({super.key, required this.status});

  final PlanStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (label, background, foreground) = switch (status) {
      PlanStatus.funded => (
        'Funded',
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      PlanStatus.underfunded => (
        'Underfunded',
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      PlanStatus.overspent => (
        'Overspent',
        colors.errorContainer,
        colors.onErrorContainer,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Spacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs / 2,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(color: foreground),
        ),
      ),
    );
  }
}

/// A small label above an amount, sharing the row's width equally.
class _Amount extends StatelessWidget {
  const _Amount({
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

  /// Underlines a value that opens another screen; editable values are only
  /// tinted.
  final bool underline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linked = onTap != null;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        // Large amounts shrink rather than overflow on narrow phones.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color ?? (linked ? theme.colorScheme.primary : null),
              decoration: underline ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );
    return Expanded(
      child: linked
          ? Tooltip(
              message: tooltip ?? label,
              child: InkWell(onTap: onTap, child: content),
            )
          : content,
    );
  }
}
