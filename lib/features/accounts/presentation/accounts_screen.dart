import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import 'account_form_screen.dart';
import 'account_list.dart';
import 'accounts_providers.dart';

/// The Account tab: lists the user's active accounts.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(activeAccountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: switch (accounts) {
        AsyncData(value: final list) when list.isEmpty => const _Message(
          'No accounts yet.\nAdd your savings, credit cards and loans to '
          'start tracking your balances.',
        ),
        AsyncData(value: final list) => AccountList(accounts: list),
        AsyncError() => const _Message(
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

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
