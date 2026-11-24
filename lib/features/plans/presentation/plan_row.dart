import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../accounts/domain/account.dart';
import '../domain/plan_summary.dart';
import 'assign_draft.dart';

/// Width of the Assigned and Available columns, shared by the rows and their
/// group header so the amounts line up. Narrower on small phones, where
/// amounts shrink to fit.
double planAmountColumnWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 360 ? 80 : 104;

/// Groups the Assigned panel with the row being edited, so a tap on either
/// is not a tap outside (which saves and closes the panel).
const Object assignEditTapGroup = #assignEdit;

/// Width of the Activity button at the end of each row; the group header
/// leaves the same space so the totals line up.
const double planActivityButtonWidth = 40;

/// One category's month in the compact Plans layout: its name, Assigned,
/// Available in a pill coloured by its status, and an Activity button.
///
/// Tapping the row ([onTap]) edits Assigned in place; while [draft] is set,
/// the row is highlighted and shows what is being typed. [onActivityTap]
/// shows the transactions behind the row's Activity.
class PlanRow extends StatelessWidget {
  const PlanRow({
    super.key,
    required this.summary,
    required this.onTap,
    required this.onActivityTap,
    this.draft,
  });

  final CategoryPlanSummary summary;
  final VoidCallback onTap;
  final VoidCallback onActivityTap;
  final AssignDraft? draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = summary.category;
    final draft = this.draft;
    final row = Material(
      // Rows sit on the plain surface, below their group's tinted band.
      color: draft == null
          ? theme.colorScheme.surface
          : Color.alphaBlend(
              theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              theme.colorScheme.surface,
            ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(
            left: Spacing.md,
            right: Spacing.xs,
            top: Spacing.sm + Spacing.xs,
            bottom: Spacing.sm + Spacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category.isArchivedInPlans
                      ? '${category.name} (archived)'
                      : category.name,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              SizedBox(
                width: planAmountColumnWidth(context),
                child: draft == null
                    ? _RightAligned(
                        Text(
                          MoneyFormatter.format(summary.assigned),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : _DraftText(draft),
              ),
              const SizedBox(width: Spacing.sm),
              SizedBox(
                width: planAmountColumnWidth(context),
                child: _RightAligned(AvailablePill(summary: summary)),
              ),
              SizedBox(
                width: planActivityButtonWidth,
                child: IconButton(
                  tooltip: '${category.name} activity',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: onActivityTap,
                  icon: const Icon(Icons.receipt_long_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // While editing, the whole row belongs with the panel: tapping it again
    // keeps editing instead of saving.
    return draft == null
        ? row
        : TapRegion(groupId: assignEditTapGroup, child: row);
  }
}

/// The amount being typed, with a cursor. A draft that the next key will
/// replace is shown selected.
class _DraftText extends StatelessWidget {
  const _DraftText(this.draft);

  final AssignDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final empty = draft.text.isEmpty;
    final style = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: empty ? colors.onSurfaceVariant : colors.primary,
    );
    final symbol = MoneyFormatter.symbolFor(Account.defaultCurrency);
    return Semantics(
      liveRegion: true,
      label: 'Assigned, editing',
      value: empty ? '0.00' : draft.text,
      excludeSemantics: true,
      child: _RightAligned(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: draft.replaceOnType && !empty
                    ? colors.primary.withValues(alpha: 0.2)
                    : null,
                borderRadius: BorderRadius.circular(Spacing.xs),
              ),
              child: Text(
                '$symbol${empty ? '0.00' : draft.text.replaceAll('-', '−')}',
                style: style,
              ),
            ),
            Container(
              width: 2,
              height: (style?.fontSize ?? 16) * 1.2,
              margin: const EdgeInsets.only(left: 1),
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Available in a pill: green when the Target is funded, yellow when it is
/// underfunded, red when overspent, and grey without a Target.
class AvailablePill extends StatelessWidget {
  const AvailablePill({super.key, required this.summary});

  final CategoryPlanSummary summary;

  /// The pill colour for [status], from the theme so every palette works.
  static Color? colorFor(BuildContext context, PlanStatus? status) {
    final colors = AppColors.of(context);
    return switch (status) {
      PlanStatus.funded => colors.positive,
      PlanStatus.underfunded => colors.warning,
      PlanStatus.overspent => colors.expense,
      null => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorFor(context, summary.status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            color?.withValues(alpha: 0.2) ??
            theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacing.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm + Spacing.xs,
          vertical: Spacing.xs,
        ),
        child: Text(
          MoneyFormatter.format(summary.available),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// A Plans group's name with its Assigned and Available totals, lined up
/// with the rows' columns.
class PlanGroupHeader extends StatelessWidget {
  const PlanGroupHeader({
    super.key,
    required this.label,
    required this.assigned,
    required this.available,
  });

  final String label;
  final Money assigned;
  final Money available;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget total(String name, Money amount) => SizedBox(
      width: planAmountColumnWidth(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            name,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          _RightAligned(
            Text(
              MoneyFormatter.format(amount),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: amount.isNegative ? AppColors.of(context).expense : null,
              ),
            ),
          ),
        ],
      ),
    );
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        total('Assigned', assigned),
        const SizedBox(width: Spacing.sm),
        total('Available', available),
        const SizedBox(width: planActivityButtonWidth),
      ],
    );
  }
}

/// Right-aligns [child], shrinking it rather than overflowing on narrow
/// phones or with large amounts.
class _RightAligned extends StatelessWidget {
  const _RightAligned(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: child,
    ),
  );
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
