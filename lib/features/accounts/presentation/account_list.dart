import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';
import '../domain/account.dart';
import '../domain/account_balance.dart';
import '../domain/account_type.dart';
import 'account_display.dart';

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
    return ListView(children: children);
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

/// One account row: name and formatted current balance.
class AccountTile extends StatelessWidget {
  const AccountTile({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(account.name),
      trailing: Text(
        formatBalance(account.type, currentBalance(account)),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
