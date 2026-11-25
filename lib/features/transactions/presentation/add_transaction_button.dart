import 'package:flutter/material.dart';

import '../../sync/presentation/edit_guard.dart';
import 'transaction_form_screen.dart';
import 'transaction_type_picker.dart';

/// The "Add transaction" floating button on the Spending and Plans tabs: picks
/// a transaction type, then opens the form for it.
class AddTransactionButton extends StatelessWidget {
  const AddTransactionButton({super.key});

  Future<void> _addTransaction(BuildContext context) async {
    if (!canEditOrExplain(context)) return;
    final kind = await showTransactionTypePicker(context);
    if (kind == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionFormScreen(kind: kind),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    onPressed: () => _addTransaction(context),
    icon: const Icon(Icons.add),
    label: const Text('Add transaction'),
  );
}
