import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/money/money.dart';
import '../domain/account.dart';
import '../domain/account_balance.dart';
import '../domain/account_type.dart';
import 'account_detail_screen.dart';
import 'account_display.dart';
import 'accounts_providers.dart';

const double _floatingButtonClearance = 88;

/// Accounts grouped into one collapsible section per [AccountType] that has
/// accounts. Sections start expanded.
///
/// With [showTotals], each section header shows the total balance of its
/// accounts. Archived lists pass `false`: archived accounts are left out of
/// totals (G7).
///
/// Expects [accounts] already ordered by type then name.
class AccountList extends ConsumerWidget {
  const AccountList({
    super.key,
    required this.accounts,
    this.showTotals = true,
  });

  final List<Account> accounts;
  final bool showTotals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = showTotals
        ? ref.watch(accountBalancesProvider).value
        : null;
    final totals = balances == null ? null : totalsByType(accounts, balances);
    return ListView(
      // Keep the last row clear of the floating "Add account" button.
      padding: const EdgeInsets.only(bottom: _floatingButtonClearance),
      children: [
        for (final type in AccountType.values)
          if (accounts.any((account) => account.type == type))
            _AccountSection(
              // Keeps each section's expanded state when others appear.
              key: ValueKey(type),
              type: type,
              total: totals?[type],
              accounts: [
                for (final account in accounts)
                  if (account.type == type) account,
              ],
            ),
      ],
    );
  }
}

/// A collapsible header for one account type, with its total on the right.
class _AccountSection extends StatelessWidget {
  const _AccountSection({
    super.key,
    required this.type,
    required this.total,
    required this.accounts,
  });

  final AccountType type;

  /// `null` when totals are hidden or balances are still loading.
  final Money? total;
  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = this.total;
    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.primary,
    );
    return ExpansionTile(
      initiallyExpanded: true,
      controlAffinity: ListTileControlAffinity.leading,
      // The section is a header, not a card: no borders when expanded.
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      title: Text(accountTypeLabel(type), style: headerStyle),
      trailing: total == null
          ? const SizedBox.shrink()
          // Green when positive, default colour otherwise, like the rows.
          : BalanceText(total, style: theme.textTheme.titleSmall),
      children: [for (final account in accounts) AccountTile(account: account)],
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
      trailing: balance == null
          ? const Text('…')
          : BalanceText(balance, style: Theme.of(context).textTheme.bodyLarge),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AccountDetailScreen(accountId: account.id),
        ),
      ),
    );
  }
}
