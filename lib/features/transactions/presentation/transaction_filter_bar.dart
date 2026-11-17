import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/date_range.dart';
import '../../accounts/presentation/account_display.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/presentation/categories_providers.dart';
import '../domain/transaction_filter.dart';
import 'transactions_providers.dart';

/// Date, account and category filter chips for the all-transactions list.
class TransactionFilterBar extends ConsumerWidget {
  const TransactionFilterBar({
    super.key,
    this.initialFilter = TransactionFilter.none,
  });

  /// The key of [transactionFilterProvider] this bar edits.
  final TransactionFilter initialFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider(initialFilter));
    final notifier = ref.read(
      transactionFilterProvider(initialFilter).notifier,
    );
    final accounts = ref.watch(accountsByIdProvider);
    final categories = ref.watch(categoriesByIdProvider);
    final range = filter.dateRange;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, 0),
      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FilterChip(
            label: range == null ? 'Any date' : DateFormatter.dateRange(range),
            icon: Icons.date_range_outlined,
            active: range != null,
            onPressed: () => _pickDateRange(context, ref),
            onClear: () => notifier.set(filter.withDateRange(null)),
          ),
          _FilterChip(
            label: accounts[filter.accountId]?.name ?? 'All accounts',
            icon: Icons.account_balance_wallet_outlined,
            active: filter.accountId != null,
            onPressed: () => _pickAccount(context, ref),
            onClear: () => notifier.set(filter.withAccount(null)),
          ),
          _FilterChip(
            label: categories[filter.categoryId]?.name ?? 'All categories',
            icon: Icons.label_outline,
            active: filter.categoryId != null,
            onPressed: () => _pickCategory(context, ref),
            onClear: () => notifier.set(filter.withCategory(null)),
          ),
          if (filter.paymentAccountId != null)
            InputChip(
              label: const Text('Debt payments'),
              onDeleted: () => notifier.set(filter.withoutPaymentFilter()),
            ),
          if (!filter.isEmpty)
            TextButton(
              onPressed: () => notifier.set(TransactionFilter.none),
              child: const Text('Clear all'),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final current = ref
        .read(transactionFilterProvider(initialFilter))
        .dateRange;
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: current == null
          ? null
          : DateTimeRange(
              start: current.start.toLocalDateTime(),
              end: current.end.toLocalDateTime(),
            ),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final notifier = ref.read(
      transactionFilterProvider(initialFilter).notifier,
    );
    notifier.set(
      ref
          .read(transactionFilterProvider(initialFilter))
          .withDateRange(
            DateRange(
              CalendarDate.fromDateTime(picked.start),
              CalendarDate.fromDateTime(picked.end),
            ),
          ),
    );
  }

  Future<void> _pickAccount(BuildContext context, WidgetRef ref) async {
    // Archived accounts are included so their history can be found.
    final accounts = ref.read(allAccountsProvider).value ?? const [];
    final customTypes = ref.read(customAccountTypesByIdProvider);
    final picked = await _pickFromSheet<int>(context, 'Account', [
      for (final account in accounts)
        (
          value: account.id,
          label: account.name,
          detail:
              '${accountTypeName(account, customTypes)}'
              '${account.isArchived ? ' · archived' : ''}',
        ),
    ]);
    if (picked == null) return;
    final notifier = ref.read(
      transactionFilterProvider(initialFilter).notifier,
    );
    notifier.set(
      ref.read(transactionFilterProvider(initialFilter)).withAccount(picked),
    );
  }

  Future<void> _pickCategory(BuildContext context, WidgetRef ref) async {
    // Archived categories are included so their history can be found.
    final categories = ref.read(allCategoriesProvider).value ?? const [];
    final picked = await _pickFromSheet<int>(context, 'Category', [
      for (final category in categories)
        if (category.linkedAccountId == null)
          (
            value: category.id,
            label: category.name,
            detail: category.isArchived ? 'Archived' : null,
          ),
    ]);
    if (picked == null) return;
    final notifier = ref.read(
      transactionFilterProvider(initialFilter).notifier,
    );
    notifier.set(
      ref.read(transactionFilterProvider(initialFilter)).withCategory(picked),
    );
  }
}

/// Lets the user pick one option. Returns `null` if dismissed.
Future<T?> _pickFromSheet<T>(
  BuildContext context,
  String title,
  List<({T value, String label, String? detail})> options,
) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (options.isEmpty)
              const ListTile(title: Text('Nothing to choose from yet.')),
            for (final option in options)
              ListTile(
                title: Text(option.label),
                subtitle: option.detail == null ? null : Text(option.detail!),
                onTap: () => Navigator.of(context).pop(option.value),
              ),
          ],
        ),
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onPressed,
    required this.onClear,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: active,
      showCheckmark: false,
      onPressed: onPressed,
      onDeleted: active ? onClear : null,
      deleteButtonTooltipMessage: 'Clear',
    );
  }
}
