import 'package:flutter/material.dart';

import '../domain/transaction_type.dart';
import 'transaction_display.dart';

/// Types offered when adding a transaction. Task 2.6 adds Transfer and Credit
/// Card Payment.
const List<TransactionType> addableTransactionTypes = [
  TransactionType.spending,
  TransactionType.inflow,
];

/// Asks which kind of transaction to add. Returns `null` if dismissed.
Future<TransactionType?> showTransactionTypePicker(BuildContext context) {
  return showModalBottomSheet<TransactionType>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
