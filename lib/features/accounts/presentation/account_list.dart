import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../domain/account.dart';
import '../domain/account_type.dart';
import 'account_detail_screen.dart';
import 'account_display.dart';
import 'accounts_providers.dart';

const double _floatingButtonClearance = 88;

/// Accounts grouped into one section per [AccountType] that has accounts.
///
/// Expects [accounts] already ordered by type then name.
class AccountList extends StatelessWidget {
  const AccountList({super.key, required this.accounts});

  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final type in AccountType.values) {
      final ofType = accounts.where((account) => account.type == type);
      if (ofType.isEmpty) continue;
      children
        ..add(_SectionHeader(title: accountTypeLabel(type)))
        ..addAll(ofType.map((account) => AccountTile(account: account)));
    }
    return ListView(
      // Keep the last row clear of the floating "Add account" button.
      padding: const EdgeInsets.only(bottom: _floatingButtonClearance),
      children: children,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.lg,
        Spacing.md,
        Spacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// One account row: name and formatted current balance. Tap for details.
class AccountTile extends ConsumerWidget {
  const AccountTile({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(accountBalancesProvider).value?[account.id];
    return ListTile(
      title: Text(account.name),
      trailing: Text(
        balance == null ? '…' : formatBalance(account.type, balance),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AccountDetailScreen(accountId: account.id),
        ),
      ),
    );
  }
}
