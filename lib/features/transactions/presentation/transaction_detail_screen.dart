import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/widgets/centered_message.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../sync/presentation/edit_guard.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';
import '../domain/transaction_kind.dart';
import 'transaction_display.dart';
import 'transaction_form_screen.dart';
import 'transactions_providers.dart';

/// Shows one transaction's trail: where the money came from and went, which
/// accounts, which category, and when (CLAUDE.md §3).
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaction = ref.watch(transactionByIdProvider(transactionId));
    final loaded = transaction.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          if (loaded != null) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                if (!canEditOrExplain(context)) return;
                final kind = _kindOf(ref, loaded);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TransactionFormScreen.edit(
                      transaction: loaded,
                      kind: kind,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, loaded),
            ),
          ],
        ],
      ),
      body: switch (transaction) {
        AsyncData(value: final Transaction found) => _TransactionDetails(
          transaction: found,
        ),
        AsyncData() => const CenteredMessage(
          'This transaction no longer exists.',
        ),
        AsyncError() => const CenteredMessage(
          'This transaction could not be loaded.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// The kind of [transaction], e.g. a loan payment for a Transfer into a Loan
/// account.
TransactionKind _kindOf(WidgetRef ref, Transaction transaction) =>
    TransactionKind.of(
      transaction,
      destinationType: ref
          .read(accountsByIdProvider)[transaction.destinationAccountId]
          ?.type,
    );

/// Deletes [transaction] after confirmation. Balances recalculate on their
/// own because they are derived from the remaining transactions (rule 11).
Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  Transaction transaction,
) async {
  if (!canEditOrExplain(context)) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete this transaction?'),
      content: Text(
        '${transactionTitle(transaction, kind: _kindOf(ref, transaction))} · '
        '${MoneyFormatter.format(transaction.amount)}\n\n'
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
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  try {
    await ref.read(transactionRepositoryProvider).delete(transaction.id);
  } on Object {
    messenger.showSnackBar(
      const SnackBar(content: Text('The transaction could not be deleted.')),
    );
    return;
  }
  messenger.showSnackBar(const SnackBar(content: Text('Transaction deleted')));
  navigator.pop();
}

class _TransactionDetails extends ConsumerWidget {
  const _TransactionDetails({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsByIdProvider);
    final category = ref.watch(categoriesByIdProvider)[transaction.categoryId];
    final textTheme = Theme.of(context).textTheme;
    final payee = transaction.payee.trim();
    final note = transaction.note.trim();
    final kind = TransactionKind.of(
      transaction,
      destinationType: accounts[transaction.destinationAccountId]?.type,
    );

    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        Row(
          children: [
            Icon(transactionKindIcon(kind)),
            const SizedBox(width: Spacing.sm),
            Text(transactionKindLabel(kind), style: textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          MoneyFormatter.format(transaction.amount),
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: Spacing.md),
        _DetailRow(
          label: 'Date',
          value: DateFormatter.localDate(transaction.date.toLocalDateTime()),
        ),
        if (transaction.type.hasSourceAccount)
          _DetailRow(
            label: 'From',
            value: _accountText(accounts[transaction.sourceAccountId]),
          ),
        if (transaction.type.hasDestinationAccount)
          _DetailRow(
            label: 'To',
            value: _accountText(accounts[transaction.destinationAccountId]),
          ),
        if (category != null)
          _DetailRow(label: 'Category', value: category.name),
        if (payee.isNotEmpty)
          _DetailRow(label: payeeLabel(transaction.type), value: payee),
        if (note.isNotEmpty) _DetailRow(label: 'Note', value: note),
        const Divider(height: Spacing.xl),
        _DetailRow(
          label: 'Recorded',
          value: DateFormatter.localDate(transaction.createdAt),
        ),
        if (transaction.updatedAt != transaction.createdAt)
          _DetailRow(
            label: 'Last edited',
            value: DateFormatter.localDate(transaction.updatedAt),
          ),
      ],
    );
  }

  static String _accountText(Account? account) => switch (account) {
    null => '…',
    Account(isArchived: true) => '${account.name} (archived)',
    _ => account.name,
  };
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      trailing: ConstrainedBox(
        // Long payees and notes wrap instead of pushing the label away.
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.6,
        ),
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
