import 'package:flutter/material.dart';

import '../domain/transaction_type.dart';
import 'transaction_display.dart';

/// Types offered when adding a transaction, in display order.
const List<TransactionType> addableTransactionTypes = TransactionType.values;

/// Asks which kind of transaction to add. Returns `null` if dismissed.
Future<TransactionType?> showTransactionTypePicker(BuildContext context) {
  return showModalBottomSheet<TransactionType>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      // Scrolls if the sheet's height limit is smaller than its content,
      // e.g. on short screens or in landscape.
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final type in addableTransactionTypes)
            ListTile(
              leading: Icon(transactionTypeIcon(type)),
              title: Text(transactionTypeLabel(type)),
              subtitle: Text(transactionTypeDescription(type)),
              onTap: () => Navigator.of(context).pop(type),
            ),
        ],
      ),
    ),
  );
}

IconData transactionTypeIcon(TransactionType type) => switch (type) {
  TransactionType.spending => Icons.shopping_bag_outlined,
  TransactionType.inflow => Icons.savings_outlined,
  TransactionType.transfer => Icons.swap_horiz,
  TransactionType.creditCardPayment => Icons.credit_score_outlined,
};
