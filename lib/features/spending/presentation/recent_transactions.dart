import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../transactions/presentation/all_transactions_screen.dart';
import '../../transactions/presentation/transaction_tile.dart';
import 'spending_providers.dart';

/// How many transactions the Spending tab shows before "See all".
const int recentTransactionCount = 10;

/// The newest transactions with a link to the full list. For This month it
/// shows the newest overall; for Last month or a custom range, only that
/// period.
class RecentTransactions extends ConsumerWidget {
  const RecentTransactions({super.key});

  static String _title(PeriodSelection selection) => switch (selection.preset) {
    PeriodPreset.thisMonth => 'Recent transactions',
    PeriodPreset.lastMonth =>
      'Transactions in ${DateFormatter.monthYear(selection.range.start.year, selection.range.start.month)}',
    PeriodPreset.custom =>
      'Transactions: ${DateFormatter.dateRange(selection.range)}',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectedPeriodProvider);
    final range = ref.watch(transactionListRangeProvider);
    final transactions = ref.watch(spendingTabTransactionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _title(selection),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AllTransactionsScreen(initialDateRange: range),
                ),
              ),
              child: const Text('See all'),
            ),
          ],
        ),
        switch (transactions) {
          AsyncData(value: final list) when list.isEmpty => Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Text(
              range == null
                  ? 'No transactions yet. Tap "Add transaction" to record one.'
                  : 'No transactions in this period.',
            ),
          ),
          // The repository returns newest first.
          AsyncData(value: final list) => Column(
            children: [
              for (final transaction in list.take(recentTransactionCount))
                TransactionTile(transaction: transaction),
            ],
          ),
          AsyncError() => const Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Text('Transactions could not be loaded.'),
          ),
          _ => const Padding(
            padding: EdgeInsets.all(Spacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}
