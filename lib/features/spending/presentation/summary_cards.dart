import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/time/date_range.dart';
import 'period_selector.dart';
import 'spending_providers.dart';

/// Formats an amount owed (positive when money is owed).
String formatOwed(Money owed) => owed.isNegative
    ? 'Overpaid ${MoneyFormatter.format(-owed)}'
    : MoneyFormatter.format(owed);

String formatPeriod(DateRange range) =>
    '${DateFormatter.localDate(range.start.toLocalDateTime())} – '
    '${DateFormatter.localDate(range.end.toLocalDateTime())}';

/// Available money with Credit owed and Loans owed beside it (D2).
class BalanceSummaryCards extends ConsumerWidget {
  const BalanceSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(balanceSummaryProvider);
    if (summary is AsyncError) {
      return const _ErrorCard('Balances could not be loaded.');
    }
    final value = summary.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(
          label: 'Available money',
          icon: Icons.account_balance_wallet_outlined,
          value: value == null
              ? '…'
              : MoneyFormatter.format(value.availableMoney),
          caption: 'Total of your Savings / Cash accounts',
          large: true,
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Credit owed',
                icon: Icons.credit_card_outlined,
                value: value == null ? '…' : formatOwed(value.creditOwed),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: _SummaryCard(
                label: 'Loans owed',
                icon: Icons.account_balance_outlined,
                value: value == null ? '…' : formatOwed(value.loansOwed),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Inflow and spending for the selected period, with the period selector.
/// Transfers and card payments are not included (rule 5).
class PeriodTotalsCards extends ConsumerWidget {
  const PeriodTotalsCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectedPeriodProvider);
    final totals = ref.watch(periodTotalsProvider);
    final value = totals.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          periodPresetLabel(selection.preset),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          formatPeriod(selection.range),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Spacing.sm),
        const PeriodSelector(),
        const SizedBox(height: Spacing.sm),
        if (totals is AsyncError)
          const _ErrorCard('Totals could not be loaded.')
        else
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Inflow',
                  icon: Icons.south_west_rounded,
                  value: value == null
                      ? '…'
                      : '+${MoneyFormatter.format(value.inflow)}',
                  tone: _Tone.inflow,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: _SummaryCard(
                  label: 'Spending',
                  icon: Icons.north_east_rounded,
                  value: value == null
                      ? '…'
                      : '-${MoneyFormatter.format(value.spending)}',
                  tone: _Tone.spending,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// How a summary card is coloured: plain, a soft money-in tint, or a solid
/// money-out fill (the Spending total stands out most).
enum _Tone { plain, inflow, spending }

/// The text colour that reads best on [background]: near-black or white,
/// whichever has the higher contrast. Used on the solid Spending tile, whose
/// fill is each palette's expense colour.
@visibleForTesting
Color readableOn(Color background) {
  const dark = Color(0xFF0B120F);
  const light = Colors.white;
  return contrastRatio(dark, background) >= contrastRatio(light, background)
      ? dark
      : light;
}

/// WCAG contrast ratio between two opaque colours.
@visibleForTesting
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (high, low) = la > lb ? (la, lb) : (lb, la);
  return (high + 0.05) / (low + 0.05);
}

/// The fill and text colours of a [_Tone] in the current theme.
@visibleForTesting
({Color? fill, Color? foreground}) summaryToneColors(
  BuildContext context, {
  required bool inflow,
}) {
  final money = AppColors.of(context);
  if (!inflow) {
    return (fill: money.expense, foreground: readableOn(money.expense));
  }
  final theme = Theme.of(context);
  final panel = theme.cardTheme.color ?? theme.colorScheme.surface;
  final fill = Color.alphaBlend(money.positive.withValues(alpha: 0.18), panel);
  // The money-in colour where it reads at 4.5:1 on its own tint (Midnight
  // Mint); otherwise the palette's main text colour on the green tint.
  final foreground = contrastRatio(money.positive, fill) >= 4.5
      ? money.positive
      : theme.colorScheme.onSurface;
  return (fill: fill, foreground: foreground);
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.large = false,
    this.tone = _Tone.plain,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? caption;
  final bool large;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = switch (tone) {
      _Tone.plain => (fill: null, foreground: null),
      _Tone.inflow => summaryToneColors(context, inflow: true),
      _Tone.spending => summaryToneColors(context, inflow: false),
    };
    final labelColor = colors.foreground ?? theme.colorScheme.onSurfaceVariant;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.fill,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: colors.foreground ?? theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(color: labelColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: large ? Spacing.md : Spacing.sm),
            FittedBox(
              // Large amounts shrink instead of overflowing a narrow card.
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: (large ? textTheme.displaySmall : textTheme.titleLarge)
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.foreground,
                    ),
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                caption!,
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Text(message),
      ),
    );
  }
}
