import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';
import '../../transactions/presentation/all_transactions_screen.dart';
import '../../transactions/presentation/transaction_form_screen.dart';
import '../../transactions/presentation/transaction_type_picker.dart';
import 'summary_cards.dart';

/// The Spending tab: balance summary, totals for the current period, and the
/// entry point for adding transactions.
class SpendingScreen extends StatelessWidget {
  const SpendingScreen({super.key});

  Future<void> _addTransaction(BuildContext context) async {
    final type = await showTransactionTypePicker(context);
    if (type == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionFormScreen(type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending'),
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTransaction(context),
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
    );
  }
}
