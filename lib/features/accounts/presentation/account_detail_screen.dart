import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/centered_message.dart';
import '../../transactions/presentation/transaction_tile.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../data/account_repository.dart';
import '../domain/account.dart';
import '../domain/account_balance.dart';
import 'account_display.dart';
import 'account_form_screen.dart';
import 'accounts_providers.dart';

/// Shows one account: balance, details, and archive / unarchive.
class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final int accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountByIdProvider(accountId));
    final loaded = account.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(loaded?.name ?? 'Account'),
        actions: [
          if (loaded != null)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AccountFormScreen(account: loaded),
                ),
              ),
            ),
        ],
      ),
      body: switch (account) {
        AsyncData(value: final Account found) => _AccountDetails(
          account: found,
          balance: ref.watch(accountBalancesProvider).value?[found.id],
        ),
        AsyncData() => const CenteredMessage('This account no longer exists.'),
        AsyncError() => const CenteredMessage(
          'This account could not be loaded.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _AccountDetails extends ConsumerWidget {
  const _AccountDetails({required this.account, required this.balance});

  final Account account;

  /// `null` while balances are loading.
  final Money? balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        Text('Current balance', style: textTheme.labelLarge),
        const SizedBox(height: Spacing.xs),
        if (balance case final balance?)
          BalanceText(balance, style: textTheme.headlineMedium)
        else
          Text('…', style: textTheme.headlineMedium),
        if (account.isArchived) ...[
          const SizedBox(height: Spacing.sm),
          const Align(
            alignment: Alignment.centerLeft,
            child: Chip(label: Text('Archived')),
          ),
        ],
        const SizedBox(height: Spacing.md),
        _DetailRow(
          label: 'Type',
          value: accountTypeName(
            account,
            ref.watch(customAccountTypesByIdProvider),
          ),
        ),
        _DetailRow(label: 'Currency', value: account.currencyCode),
        _DetailRow(
          label: 'Created',
          value: DateFormatter.localDate(account.createdAt),
        ),
        const SizedBox(height: Spacing.md),
        // Archiving needs the balance to decide whether to confirm.
        if (balance case final known?)
          _ArchiveButton(account: account, balance: known),
        const Divider(height: Spacing.xl),
        Text('Transactions', style: textTheme.titleMedium),
        const SizedBox(height: Spacing.sm),
        _AccountTransactions(accountId: account.id),
      ],
    );
  }
}

class _AccountTransactions extends ConsumerWidget {
  const _AccountTransactions({required this.accountId});

  final int accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(transactionsForAccountProvider(accountId))) {
      AsyncData(value: final list) when list.isEmpty => const Text(
        'No transactions yet.',
      ),
      AsyncData(value: final list) => Column(
        children: [
          for (final transaction in list)
            TransactionTile(transaction: transaction, accountId: accountId),
        ],
      ),
      AsyncError() => const Text('Transactions could not be loaded.'),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
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
      trailing: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _ArchiveButton extends ConsumerWidget {
  const _ArchiveButton({required this.account, required this.balance});

  final Account account;
  final Money balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      icon: Icon(
        account.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
      ),
      label: Text(account.isArchived ? 'Unarchive account' : 'Archive account'),
      onPressed: () => account.isArchived
          ? _setArchived(context, ref, archived: false)
          : _archive(context, ref),
    );
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    if (needsArchiveConfirmation(balance)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) =>
            _ConfirmArchiveDialog(account: account, balance: balance),
      );
      if (confirmed != true || !context.mounted) return;
    }
    await _setArchived(context, ref, archived: true);
  }

  Future<void> _setArchived(
    BuildContext context,
    WidgetRef ref, {
    required bool archived,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(accountRepositoryProvider)
          .setArchived(account.id, archived: archived);
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('The account could not be updated.')),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          archived ? '${account.name} archived' : '${account.name} restored',
        ),
      ),
    );
    navigator.pop();
  }
}

class _ConfirmArchiveDialog extends StatelessWidget {
  const _ConfirmArchiveDialog({required this.account, required this.balance});

  final Account account;
  final Money balance;

  @override
  Widget build(BuildContext context) {
    final formatted = formatBalance(balance);
    return AlertDialog(
      title: const Text('Archive this account?'),
      content: Text(
        '${account.name} still has a balance: $formatted. Archived accounts '
        "are hidden from your account list and totals, and you can't add "
        'transactions to them. You can unarchive it later.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Archive'),
        ),
      ],
    );
  }
}
