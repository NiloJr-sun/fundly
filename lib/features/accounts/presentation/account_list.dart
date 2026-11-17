import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/money/money.dart';
import '../domain/account.dart';
import '../domain/account_balance.dart';
import '../domain/account_groups.dart';
import '../domain/account_type.dart';
import 'account_detail_screen.dart';
import 'account_display.dart';
import 'accounts_providers.dart';

const double _floatingButtonClearance = 88;

/// Accounts under an Assets and a Liabilities heading, with one collapsible
/// section per account type (built-in or custom) that has accounts. Sections
/// start expanded. Headings have no totals.
///
/// With [showTotals], each section header shows the total balance of its
/// accounts. Archived lists pass `false`: archived accounts are left out of
/// totals (G7).
///
/// Expects [accounts] already ordered by name within each type.
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
    final customTypes = ref.watch(customAccountTypesProvider);
    // Wait for custom types so accounts do not jump between sections. If
    // they fail to load, accounts show under their built-in types.
    if (customTypes is AsyncLoading && !customTypes.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final groups = groupAccounts(accounts, customTypes.value ?? const []);
    final balances = showTotals
        ? ref.watch(accountBalancesProvider).value
        : null;
    return ListView(
      // Keep the last row clear of the floating "Add account" button.
      padding: const EdgeInsets.only(bottom: _floatingButtonClearance),
      children: [
        for (final accountClass in AccountClass.values)
          if (groups.any((group) => group.accountClass == accountClass)) ...[
            _ClassHeading(accountClass),
            for (final group in groups)
              if (group.accountClass == accountClass)
                _AccountSection(
                  // Keeps each section's expanded state when others appear.
                  key: ValueKey((group.type, group.customType?.id)),
                  title: group.customType?.name ?? accountTypeLabel(group.type),
                  total: balances == null
                      ? null
                      : totalBalance(group.accounts, balances),
                  accounts: group.accounts,
                ),
          ],
      ],
    );
  }
}

/// "Assets" or "Liabilities", above that class's type sections.
class _ClassHeading extends StatelessWidget {
  const _ClassHeading(this.accountClass);

  final AccountClass accountClass;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        Spacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          accountClassLabel(accountClass),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// A collapsible header for one account type, with its total on the right.
class _AccountSection extends StatelessWidget {
  const _AccountSection({
    super.key,
    required this.title,
    required this.total,
    required this.accounts,
  });

  final String title;

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
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        controlAffinity: ListTileControlAffinity.leading,
        // The section is a header, not a card: no borders when expanded.
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        title: Text(title, style: headerStyle),
        trailing: total == null
            ? const SizedBox.shrink()
            // Green when positive, default colour otherwise, like the rows.
            : BalanceText(total, style: theme.textTheme.titleSmall),
        children: [
          for (final account in accounts) AccountTile(account: account),
        ],
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
      subtitle: account.isBudgetAccount ? const Text('Budget account') : null,
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
