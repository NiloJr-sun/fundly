import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                value: value == null ? '…' : formatOwed(value.creditOwed),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: _SummaryCard(
                label: 'Loans owed',
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
                  value: value == null
                      ? '…'
                      : '+${MoneyFormatter.format(value.inflow)}',
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: _SummaryCard(
                  label: 'Spending',
                  value: value == null
                      ? '…'
                      : '-${MoneyFormatter.format(value.spending)}',
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    this.caption,
    this.large = false,
  });

  final String label;
  final String value;
  final String? caption;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.labelLarge),
            const SizedBox(height: Spacing.xs),
            FittedBox(
              // Large amounts shrink instead of overflowing a narrow card.
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: large ? textTheme.headlineMedium : textTheme.titleLarge,
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(caption!, style: textTheme.bodySmall),
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
