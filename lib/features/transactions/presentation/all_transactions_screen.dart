import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/centered_message.dart';
import 'transaction_tile.dart';
import 'transactions_providers.dart';

/// Every transaction, newest first.
class AllTransactionsScreen extends ConsumerWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(allTransactionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('All transactions')),
      body: switch (transactions) {
        AsyncData(value: final list) when list.isEmpty => const CenteredMessage(
          'No transactions yet.',
        ),
        AsyncData(value: final list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, index) => TransactionTile(transaction: list[index]),
        ),
        AsyncError() => const CenteredMessage(
          'Transactions could not be loaded.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
