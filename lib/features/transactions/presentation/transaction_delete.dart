import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/money_formatter.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../sync/presentation/edit_guard.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';
import '../domain/transaction_kind.dart';
import 'transaction_display.dart';

/// The kind of [transaction], e.g. a loan payment for a Transfer into a Loan
/// account.
TransactionKind transactionKindFor(WidgetRef ref, Transaction transaction) =>
    TransactionKind.of(
      transaction,
      destinationType: ref
          .read(accountsByIdProvider)[transaction.destinationAccountId]
          ?.type,
    );

/// Deletes [transaction] after confirmation, from the detail screen's Delete
/// button or a swipe on its row. Balances recalculate on their own because
/// they are derived from the remaining transactions (rule 11). Returns
/// whether it was deleted.
Future<bool> confirmAndDeleteTransaction(
  BuildContext context,
  WidgetRef ref,
  Transaction transaction,
) async {
  if (!canEditOrExplain(context)) return false;
  final title = transactionTitle(
    transaction,
    kind: transactionKindFor(ref, transaction),
    destinationName: ref
        .read(accountsByIdProvider)[transaction.destinationAccountId]
        ?.name,
    categoryName: ref
        .read(categoriesByIdProvider)[transaction.categoryId]
        ?.name,
  );
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete this transaction?'),
      content: Text(
        '$title · ${MoneyFormatter.format(transaction.amount)}\n\n'
        "Account balances will be recalculated. This can't be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(transactionRepositoryProvider).delete(transaction.id);
  } on Object {
    messenger.showSnackBar(
      const SnackBar(content: Text('The transaction could not be deleted.')),
    );
    return false;
  }
  messenger.showSnackBar(const SnackBar(content: Text('Transaction deleted')));
  return true;
}
