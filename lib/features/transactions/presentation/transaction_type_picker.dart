import 'package:flutter/material.dart';

import '../domain/transaction_kind.dart';
import 'transaction_display.dart';

/// Kinds offered when adding a transaction, in display order. Loan payment
/// sits next to Credit card payment.
const List<TransactionKind> addableTransactionKinds = [
  TransactionKind.spending,
  TransactionKind.inflow,
  TransactionKind.transfer,
  TransactionKind.loanPayment,
  TransactionKind.creditCardPayment,
];

/// Asks which kind of transaction to add. Returns `null` if dismissed.
Future<TransactionKind?> showTransactionTypePicker(BuildContext context) {
  return showModalBottomSheet<TransactionKind>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      // Scrolls if the sheet's height limit is smaller than its content,
      // e.g. on short screens or in landscape.
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final kind in addableTransactionKinds)
            ListTile(
              leading: Icon(transactionKindIcon(kind)),
              title: Text(transactionKindLabel(kind)),
              subtitle: Text(transactionKindDescription(kind)),
              onTap: () => Navigator.of(context).pop(kind),
            ),
        ],
      ),
    ),
  );
}
