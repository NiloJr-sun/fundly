import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/time/calendar_month.dart';
import '../../../core/widgets/centered_message.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../categories/presentation/category_display.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/presentation/all_transactions_screen.dart';
import '../data/plan_repository.dart';
import '../domain/plan_summary.dart';
import 'plan_editor_dialog.dart';
import 'plan_month_bar.dart';
import 'plan_row.dart';
import 'plans_providers.dart';
import 'ready_to_assign_card.dart';

/// The Plans tab: target, assigned, activity, available and status per
/// spending category for one month, in Spending, Savings and Liability
/// sections, below the month's Ready to assign. Tap a row to edit its target and assigned amount, or tap either
/// amount to edit just that one; tap Activity to see its transactions.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedPlanMonthProvider);
    final summaries = ref.watch(planSummariesProvider(month));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans'),
        actions: [
          IconButton(
            tooltip: 'Categories',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const PlanMonthBar(),
          Expanded(
            child: switch (summaries) {
              AsyncData(value: final rows) when rows.isEmpty =>
                const CenteredMessage(
                  'No spending categories yet.\nAdd one from Categories '
                  '(top right).',
                ),
              AsyncData(value: final rows) => _PlanList(
                month: month,
                rows: rows,
              ),
              AsyncError() => const CenteredMessage(
                'Your plans could not be loaded.',
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _PlanList extends ConsumerWidget {
  const _PlanList({required this.month, required this.rows});

  final CalendarMonth month;
  final List<CategoryPlanSummary> rows;

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    CategoryPlanSummary summary,
    PlanAmountField? field,
  ) async {
    final amounts = await showPlanEditorDialog(
      context,
      categoryName: summary.category.name,
      monthLabel: DateFormatter.monthYear(month.year, month.month),
      target: summary.target,
      assigned: summary.assigned,
      hasPlan: summary.hasPlan,
      currencyCode: Account.defaultCurrency,
      only: field,
    );
    if (amounts == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(planRepositoryProvider)
          .save(
            month: month,
            categoryId: summary.category.id,
            target: amounts.target,
            assigned: amounts.assigned,
          );
    } on Object {
      // The dialog already rejects invalid amounts; anything else (such as
      // the category being archived meanwhile) is reported generically.
      messenger.showSnackBar(
        const SnackBar(content: Text('This plan could not be saved.')),
      );
    }
  }

  /// Opens All transactions filtered to this category and month.
  void _showActivity(BuildContext context, CategoryPlanSummary summary) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AllTransactionsScreen(
            initialFilter: TransactionFilter(
              dateRange: month.dateRange,
              categoryId: summary.category.linkedAccountId == null
                  ? summary.category.id
                  : null,
              accountId: summary.category.linkedAccountId,
              paymentAccountId: summary.category.linkedAccountId,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        ReadyToAssignCard(month: month),
        // One section per group that has rows, in [PlanGroup] order.
        for (final group in PlanGroup.values)
          if (rows.any((row) => row.category.planGroup == group)) ...[
            _GroupHeading(planGroupLabel(group)),
            for (final summary in rows)
              if (summary.category.planGroup == group)
                PlanRow(
                  summary: summary,
                  // A new plan cannot use an archived category; an existing
                  // one can still be changed or cleared.
                  onEdit: summary.category.isArchived && !summary.hasPlan
                      ? null
                      : (field) => _edit(context, ref, summary, field),
                  onActivityTap: () => _showActivity(context, summary),
                ),
          ],
      ],
    );
  }
}

/// "Spending", "Savings" or "Liability", above that group's categories.
class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.title);

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
