import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/centered_message.dart';
import 'account_list.dart';
import 'accounts_providers.dart';

/// Lists archived accounts so they can be viewed or unarchived.
class ArchivedAccountsScreen extends ConsumerWidget {
  const ArchivedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(archivedAccountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Archived accounts')),
      body: switch (accounts) {
        AsyncData(value: final list) when list.isEmpty => const CenteredMessage(
          'No archived accounts.',
        ),
        AsyncData(value: final list) => AccountList(accounts: list),
        AsyncError() => const CenteredMessage(
          'Archived accounts could not be loaded.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
