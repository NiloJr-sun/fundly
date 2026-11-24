import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
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
///
/// The amount is coloured by the sign it shows: "+" in the palette's money-in
/// colour, "-" in its money-out colour, and unsigned amounts (transfers and
/// card payments outside an account) neutral, since they are neither
/// spending nor income (rule 5). Inside an account, transfers show their
/// effect on that account, so they are signed and coloured too.
///
/// With [boxedIcon], the type icon sits in a tinted rounded square (the
/// Spending tab's recent list).
class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.accountId,
    this.boxedIcon = false,
  });

  final Transaction transaction;
  final String? accountId;
  final bool boxedIcon;

  /// The colour for an amount shown as [text], or null for the default.
  static Color? amountColor(BuildContext context, String text) =>
      text.startsWith('+')
      ? AppColors.of(context).positive
      : text.startsWith('-')
      ? AppColors.of(context).expense
      : null;

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

    final icon = Icon(transactionTypeIcon(transaction.type));
    final amount = transactionAmountText(transaction, accountId: accountId);
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: boxedIcon
          ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: colors.onSurfaceVariant, size: 20),
                child: icon,
              ),
            )
          : icon,
      title: Text(transactionTitle(transaction)),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(
        amount,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: amountColor(context, amount),
          fontWeight: FontWeight.w600,
        ),
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
