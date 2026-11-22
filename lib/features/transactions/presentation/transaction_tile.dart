import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/date_formatter.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/presentation/categories_providers.dart';
import '../domain/transaction.dart';
import '../domain/transaction_type.dart';
import 'transaction_detail_screen.dart';
import 'transaction_display.dart';

/// One transaction row. Tap for details.
///
/// When shown inside an account, pass [accountId] so the amount's sign shows
/// the effect on that account.
class TransactionTile extends ConsumerWidget {
  const TransactionTile({super.key, required this.transaction, this.accountId});

  final Transaction transaction;
  final String? accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsByIdProvider);
    final categories = ref.watch(categoriesByIdProvider);
    String accountName(String? id) => accounts[id]?.name ?? '…';

    final details = switch (transaction.type) {
      TransactionType.spending => [
        categories[transaction.categoryId]?.name,
        accountName(transaction.sourceAccountId),
      ],
      TransactionType.inflow => [
        categories[transaction.categoryId]?.name,
        accountName(transaction.destinationAccountId),
      ],
      TransactionType.transfer || TransactionType.creditCardPayment => [
        '${accountName(transaction.sourceAccountId)} → '
            '${accountName(transaction.destinationAccountId)}',
      ],
    };
    final subtitle = [
      DateFormatter.localDate(transaction.date.toLocalDateTime()),
      ...details.nonNulls,
    ].join(' · ');

    return ListTile(
      leading: Icon(transactionTypeIcon(transaction.type)),
      title: Text(transactionTitle(transaction)),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(
        transactionAmountText(transaction, accountId: accountId),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              TransactionDetailScreen(transactionId: transaction.id),
        ),
      ),
    );
  }
}
