import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/date_range.dart';
import '../../../core/widgets/centered_message.dart';
import '../domain/transaction_filter.dart';
import 'transaction_filter_bar.dart';
import 'transaction_tile.dart';
import 'transactions_providers.dart';

/// Every transaction, newest first, with date, account and category filters.
class AllTransactionsScreen extends ConsumerWidget {
  const AllTransactionsScreen({super.key, this.initialDateRange});

  /// Pre-sets the date filter when the list opens. The user can clear it.
  final DateRange? initialDateRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = TransactionFilter(dateRange: initialDateRange);
    final transactions = ref.watch(filteredTransactionsProvider(initial));
    final filtered = !ref.watch(transactionFilterProvider(initial)).isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('All transactions')),
      body: Column(
        children: [
          TransactionFilterBar(initialFilter: initial),
          Expanded(
            child: switch (transactions) {
              AsyncData(value: final list) when list.isEmpty => CenteredMessage(
                filtered
                    ? 'No transactions match these filters.'
                    : 'No transactions yet.',
              ),
              AsyncData(value: final list) => ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, index) =>
                    TransactionTile(transaction: list[index]),
              ),
              AsyncError() => const CenteredMessage(
                'Transactions could not be loaded.',
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}
