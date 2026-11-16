import 'package:flutter/material.dart';

import '../../../core/widgets/centered_message.dart';
import '../../transactions/presentation/all_transactions_screen.dart';
import '../../transactions/presentation/transaction_form_screen.dart';
import '../../transactions/presentation/transaction_type_picker.dart';

/// The Spending tab. The overview arrives in roadmap Phase 3; for now it is
/// the entry point for adding transactions.
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
      body: const CenteredMessage(
        'Your balances and recent activity will appear here.',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTransaction(context),
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
    );
  }
}
