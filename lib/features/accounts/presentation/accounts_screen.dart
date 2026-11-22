import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/centered_message.dart';
import 'account_form_screen.dart';
import 'account_list.dart';
import 'account_types_screen.dart';
import 'accounts_providers.dart';
import 'archived_accounts_screen.dart';

/// The Accounts tab: lists the user's active accounts.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(activeAccountsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            tooltip: 'Account types',
            icon: const Icon(Icons.label_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AccountTypesScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Archived accounts',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ArchivedAccountsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: switch (accounts) {
        AsyncData(value: final list) when list.isEmpty => const CenteredMessage(
          'No accounts yet.\nAdd your savings, credit cards and loans '
          'to start tracking your balances.',
        ),
        AsyncData(value: final list) => AccountList(accounts: list),
        AsyncError() => const CenteredMessage(
          'Your accounts could not be loaded. Please restart the app.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AccountFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add account'),
      ),
    );
  }
}
