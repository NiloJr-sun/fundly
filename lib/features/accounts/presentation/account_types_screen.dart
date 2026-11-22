import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/widgets/centered_message.dart';
import '../domain/account_type.dart';
import '../domain/custom_account_type.dart';
import 'account_display.dart';
import 'account_type_dialog.dart';
import 'accounts_providers.dart';

const double _floatingButtonClearance = 88;

/// Lists custom account types under Assets and Liabilities. Tap one to
/// rename it, change its class while unused, or delete it when unused.
class AccountTypesScreen extends ConsumerWidget {
  const AccountTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(customAccountTypesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account types')),
      body: switch (types) {
        AsyncData(value: final list) when list.isEmpty => const CenteredMessage(
          'No custom account types yet.\nAdd one to group accounts your '
          'way, such as E-wallet or Pay later.',
        ),
        AsyncData(value: final list) => _TypeList(types: list),
        AsyncError() => const CenteredMessage(
          'Your account types could not be loaded.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNewAccountTypeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add type'),
      ),
    );
  }
}

class _TypeList extends ConsumerWidget {
  const _TypeList({required this.types});

  /// Ordered by name.
  final List<CustomAccountType> types;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(customTypeAccountCountsProvider);
    return ListView(
      // Keep the last row clear of the floating "Add type" button.
      padding: const EdgeInsets.only(bottom: _floatingButtonClearance),
      children: [
        for (final accountClass in AccountClass.values)
          if (types.any((t) => t.baseType.accountClass == accountClass)) ...[
            _Heading(accountClassLabel(accountClass)),
            for (final type in types)
              if (type.baseType.accountClass == accountClass)
                _TypeTile(type: type, accountCount: counts[type.id] ?? 0),
          ],
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
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
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.type, required this.accountCount});

  final CustomAccountType type;
  final int accountCount;

  @override
  Widget build(BuildContext context) {
    final works = switch (type.baseType) {
      AccountType.savingsCash => 'Works like Savings / Cash',
      AccountType.credit => 'Works like a credit card',
      AccountType.loan => 'Works like a loan',
    };
    final usage = switch (accountCount) {
      0 => 'no accounts',
      1 => '1 account',
      _ => '$accountCount accounts',
    };
    return ListTile(
      title: Text(type.name),
      subtitle: Text('$works · $usage'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showEditAccountTypeDialog(
        context,
        type: type,
        accountCount: accountCount,
      ),
    );
  }
}
