import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/date_formatter.dart';
import '../../../core/time/calendar_month.dart';
import '../../../core/widgets/centered_message.dart';
import '../../accounts/domain/account.dart';
import '../../categories/presentation/categories_screen.dart';
import '../data/plan_repository.dart';
import '../domain/plan_summary.dart';
import 'plan_month_bar.dart';
import 'plan_row.dart';
import 'planned_amount_dialog.dart';
import 'plans_providers.dart';

/// The Plans tab: planned vs actual spending per category for one month.
/// Tap a row to set or clear its planned amount.
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
  ) async {
    final choice = await showPlannedAmountDialog(
      context,
      categoryName: summary.category.name,
      monthLabel: DateFormatter.monthYear(month.year, month.month),
      current: summary.planned,
      currencyCode: Account.defaultCurrency,
    );
    if (choice == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(planRepositoryProvider);
    final categoryId = summary.category.id;
    try {
      switch (choice) {
        case SetPlannedAmount(:final amount):
          // Until the screen shows assigned amounts, the planned amount is
          // also what is assigned, as v6 did for existing plans.
          await repository.save(
            month: month,
            categoryId: categoryId,
            target: amount,
            assigned: amount,
          );
        case ClearPlannedAmount():
          await repository.clear(month: month, categoryId: categoryId);
      }
    } on Object {
      // The dialog already rejects invalid amounts; anything else (such as
      // the category being archived meanwhile) is reported generically.
      messenger.showSnackBar(
        const SnackBar(content: Text('This plan could not be saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        for (final summary in rows)
          PlanRow(
            summary: summary,
            // A new plan cannot use an archived category; an existing one
            // can still be changed or cleared.
            onTap: summary.category.isArchived && summary.planned == null
                ? null
                : () => _edit(context, ref, summary),
          ),
      ],
    );
  }
}
