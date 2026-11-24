import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/time/calendar_month.dart';
import '../../../core/time/clock_provider.dart';
import '../../../core/widgets/centered_message.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../categories/presentation/category_display.dart';
import '../../spaces/presentation/screen_title.dart';
import '../../spending/presentation/spending_providers.dart';
import '../../sync/presentation/edit_guard.dart';
import '../data/plan_repository.dart';
import '../domain/plan_summary.dart';
import 'archive_plan.dart';
import 'archived_plans_screen.dart';
import 'plan_activity.dart';
import 'plan_editor_dialog.dart';
import 'plan_month_bar.dart';
import 'plan_row.dart';
import 'plans_providers.dart';
import 'ready_to_assign_card.dart';

/// The Plans tab: target, assigned, activity, available and status per
/// spending category for one month, in Spending, Savings and Liability
/// sections, below the month's Ready to assign. Tap a row to edit its target and assigned amount, or tap either
/// amount to edit just that one; tap Activity to see its transactions.
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = ref.read(clockProvider)().toLocal();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(midnight.difference(now), _refreshDate);
  }

  void _refreshDate() {
    if (!mounted) return;
    ref.invalidate(todayProvider);
    ref.read(selectedPlanMonthProvider.notifier).refreshCurrentMonth();
    _scheduleMidnight();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDate();
    } else {
      _midnightTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedPlanMonthProvider);
    final summaries = ref.watch(planSummariesProvider(month));
    return Scaffold(
      appBar: AppBar(
        title: const ScreenTitle('Plans'),
        actions: [
          IconButton(
            tooltip: 'Archived plans',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ArchivedPlansScreen(),
              ),
            ),
          ),
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
    if (!canEditOrExplain(context)) return;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        ReadyToAssignCard(month: month),
        if (rows.isEmpty)
          const CenteredMessage(
            'No active plans.\nAdd a category or unarchive a plan.',
          ),
        // One section per group that has rows, in [PlanGroup] order.
        for (final group in PlanGroup.values)
          if (rows.any((row) => row.category.planGroup == group))
            Card(
              key: ValueKey(group),
              margin: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.xs,
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                key: PageStorageKey('plans-group-${group.name}'),
                initiallyExpanded: true,
                controlAffinity: ListTileControlAffinity.leading,
                shape: const Border(),
                collapsedShape: const Border(),
                tilePadding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                title: Semantics(
                  header: true,
                  child: Text(
                    planGroupLabel(group),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                children: [
                  for (final summary in rows)
                    if (summary.category.planGroup == group)
                      PlanRow(
                        summary: summary,
                        onEdit: (field) => _edit(context, ref, summary, field),
                        onActivityTap: () =>
                            showPlanActivity(context, month, summary.category),
                        onArchive: () =>
                            archivePlan(context, ref, summary.category),
                      ),
                ],
              ),
            ),
      ],
    );
  }
}
