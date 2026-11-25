import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';
import '../../spaces/presentation/screen_title.dart';
import '../../transactions/presentation/add_transaction_button.dart';
import '../../transactions/presentation/all_transactions_screen.dart';
import 'recent_transactions.dart';
import 'summary_cards.dart';

/// The Spending tab: balance summary, totals for the selected period, recent
/// transactions, and the entry point for adding transactions.
class SpendingScreen extends StatelessWidget {
  const SpendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ScreenTitle('Spending'),
        actions: [
          IconButton(
            tooltip: 'All transactions',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AllTransactionsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        // Bottom padding keeps content clear of the floating button.
        padding: const EdgeInsets.fromLTRB(
          Spacing.md,
          Spacing.md,
          Spacing.md,
          88,
        ),
        children: const [
          BalanceSummaryCards(),
          SizedBox(height: Spacing.lg),
          PeriodTotalsCards(),
          SizedBox(height: Spacing.lg),
          RecentTransactions(),
        ],
      ),
      floatingActionButton: const AddTransactionButton(),
    );
  }
}
