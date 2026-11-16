import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../transactions/presentation/all_transactions_screen.dart';
import '../../transactions/presentation/transaction_tile.dart';
import '../../transactions/presentation/transactions_providers.dart';

/// How many transactions the Spending tab shows before "See all".
const int recentTransactionCount = 10;

/// The newest transactions overall (not limited to the selected period),
/// with a link to the full list.
class RecentTransactions extends ConsumerWidget {
  const RecentTransactions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(allTransactionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent transactions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AllTransactionsScreen(),
                ),
              ),
              child: const Text('See all'),
            ),
          ],
        ),
        switch (transactions) {
          AsyncData(value: final list) when list.isEmpty => const Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Text(
              'No transactions yet. Tap "Add transaction" to record one.',
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
