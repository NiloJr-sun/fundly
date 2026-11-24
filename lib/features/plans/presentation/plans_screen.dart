import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_parser.dart';
import '../../../core/time/calendar_month.dart';
import '../../../core/time/clock_provider.dart';
import '../../../core/widgets/centered_message.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/account_form_messages.dart';
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
import 'assign_draft.dart';
import 'assign_panel.dart';
import 'plan_activity.dart';
import 'plan_details.dart';
import 'plan_editor_dialog.dart';
import 'plan_month_bar.dart';
import 'plan_row.dart';
import 'plans_providers.dart';
import 'ready_to_assign_card.dart';

/// The Plans tab: one month's Ready to assign, then a compact row per spending
/// category (Assigned, and Available in a pill coloured by status) in
/// collapsible Spending, Savings and Liability sections with their totals.
/// Tap a row for its details: Target, Activity and status, editing, its
/// transactions and archiving.
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

  // Editing a row's Assigned in place: the plan as it was when editing
  // started (its month, Target and saved amount), and what is typed.
  CategoryPlanSummary? _editing;
  CalendarMonth? _editingMonth;
  AssignDraft? _draft;
  String? _assignError;
  final _editingRowKey = GlobalKey();

  void _startAssign(CalendarMonth month, CategoryPlanSummary summary) {
    if (_editing?.category.id == summary.category.id) return;
    // Moving to another row saves this one first, unless it cannot be saved.
    if (_editing != null && !_commitAssign()) return;
    if (!canEditOrExplain(context)) return;
    setState(() {
      _editing = summary;
      _editingMonth = month;
      _draft = AssignDraft.start(summary.assigned);
      _assignError = null;
    });
    // The panel takes space from the list: keep the row in view above it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _editingRowKey.currentContext;
      if (row == null || !row.mounted) return;
      Scrollable.ensureVisible(
        row,
        duration: const Duration(milliseconds: 200),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void _pressKey(AssignKey key) => setState(() {
    _draft = _draft?.press(key, currencyCode: Account.defaultCurrency);
    _assignError = null;
  });

  void _closeAssign() => setState(() {
    _editing = null;
    _editingMonth = null;
    _draft = null;
    _assignError = null;
  });

  /// Saves what is typed, if it changed, and closes the panel. Returns
  /// `false`, keeping the panel open with the reason, when the sum cannot be
  /// saved.
  bool _commitAssign() {
    final summary = _editing;
    final month = _editingMonth;
    final draft = _draft;
    if (summary == null || month == null || draft == null) return true;
    final Money amount;
    try {
      amount = draft.evaluate(currencyCode: Account.defaultCurrency);
    } on AssignBelowZeroException {
      setState(() => _assignError = "Assigned can't be below zero.");
      return false;
    } on MoneyParseException catch (exception) {
      setState(
        () => _assignError = exception.error == MoneyParseError.invalid
            ? 'Finish the sum, for example 1,000+500.'
            : moneyParseErrorText(exception.error, Account.defaultCurrency),
      );
      return false;
    }
    _closeAssign();
    if (amount != summary.assigned) {
      unawaited(_saveAssigned(month, summary, amount));
    }
    return true;
  }

  /// Saves [assigned], keeping the Target the month showed (its own, or the
  /// category's default), as the plan editor does.
  Future<void> _saveAssigned(
    CalendarMonth month,
    CategoryPlanSummary summary,
    Money assigned,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(planRepositoryProvider)
          .save(
            month: month,
            categoryId: summary.category.id,
            target: summary.target,
            assigned: assigned,
          );
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('This plan could not be saved.')),
      );
    }
  }

  /// Saves first, then opens the transactions or the details.
  void _assignActivity() {
    final summary = _editing;
    final month = _editingMonth;
    if (summary == null || month == null || !_commitAssign()) return;
    showPlanActivity(context, month, summary.category);
  }

  void _assignDetails(List<CategoryPlanSummary> rows) {
    final summary = _editing;
    final month = _editingMonth;
    if (summary == null || month == null || !_commitAssign()) return;
    // The details show the plan as saved, which may have just changed.
    final current = rows.firstWhere(
      (row) => row.category.id == summary.category.id,
      orElse: () => summary,
    );
    unawaited(_openPlanDetails(context, ref, month, current));
  }

  Widget _assignPanel(List<CategoryPlanSummary> rows) {
    final editing = _editing!;
    final current = rows.firstWhere(
      (row) => row.category.id == editing.category.id,
      orElse: () => editing,
    );
    final target = current.target;
    final missing = target == null ? null : target - current.assigned;
    final reachesTarget = missing != null && missing.minorUnits > 0;
    return TapRegion(
      groupId: assignEditTapGroup,
      onTapOutside: (_) => _commitAssign(),
      child: AssignPanel(
        onKey: _pressKey,
        onDone: _commitAssign,
        onCancel: _closeAssign,
        onActivity: _assignActivity,
        onDetails: () => _assignDetails(rows),
        error: _assignError,
        hint: reachesTarget
            ? 'Assign ${MoneyFormatter.format(missing)} more to reach your '
                  'target'
            : null,
        onHintTap: reachesTarget
            ? () => setState(() {
                _draft = _draft?.fill(target!);
                _assignError = null;
              })
            : null,
      ),
    );
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
                onAssignedTap: (summary) => _startAssign(month, summary),
                editingId: _editing?.category.id,
                draft: _draft,
                editingRowKey: _editingRowKey,
              ),
              AsyncError() => const CenteredMessage(
                'Your plans could not be loaded.',
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          if (_editing != null)
            if (summaries case AsyncData(value: final rows)) _assignPanel(rows),
        ],
      ),
    );
  }
}

class _PlanList extends ConsumerWidget {
  const _PlanList({
    required this.month,
    required this.rows,
    required this.onAssignedTap,
    this.editingId,
    this.draft,
    this.editingRowKey,
  });

  final CalendarMonth month;
  final List<CategoryPlanSummary> rows;
  final ValueChanged<CategoryPlanSummary> onAssignedTap;

  /// The category whose Assigned is being edited, with what is typed.
  final String? editingId;
  final AssignDraft? draft;
  final Key? editingRowKey;

  List<CategoryPlanSummary> _rowsIn(PlanGroup group) => [
    for (final row in rows)
      if (row.category.planGroup == group) row,
  ];

  /// The group's name with the sums of its rows' Assigned and Available.
  Widget _groupHeader(PlanGroup group) {
    var assigned = const Money.zero(Account.defaultCurrency);
    var available = const Money.zero(Account.defaultCurrency);
    for (final row in _rowsIn(group)) {
      assigned += row.assigned;
      available += row.available;
    }
    return PlanGroupHeader(
      label: planGroupLabel(group),
      assigned: assigned,
      available: available,
    );
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
                // The right edge matches the rows, so the totals line up.
                tilePadding: const EdgeInsets.only(
                  left: Spacing.sm,
                  right: Spacing.md,
                ),
                expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                title: _groupHeader(group),
                children: [
                  for (final (index, summary) in _rowsIn(group).indexed) ...[
                    if (index > 0) const Divider(height: 1),
                    PlanRow(
                      key: summary.category.id == editingId
                          ? editingRowKey
                          : null,
                      summary: summary,
                      onTap: () =>
                          _openPlanDetails(context, ref, month, summary),
                      onAssignedTap: () => onAssignedTap(summary),
                      draft: summary.category.id == editingId ? draft : null,
                    ),
                  ],
                ],
              ),
            ),
      ],
    );
  }
}

/// Edits the plan in the dialog: both amounts, or only [field].
Future<void> _editPlan(
  BuildContext context,
  WidgetRef ref,
  CalendarMonth month,
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

/// Opens [summary]'s details sheet and carries out what was chosen there.
Future<void> _openPlanDetails(
  BuildContext context,
  WidgetRef ref,
  CalendarMonth month,
  CategoryPlanSummary summary,
) async {
  final action = await showPlanDetailsSheet(
    context,
    summary: summary,
    monthLabel: DateFormatter.monthYear(month.year, month.month),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case PlanDetailsAction.editPlan:
      await _editPlan(context, ref, month, summary, null);
    case PlanDetailsAction.editTarget:
      await _editPlan(context, ref, month, summary, PlanAmountField.target);
    case PlanDetailsAction.editAssigned:
      await _editPlan(context, ref, month, summary, PlanAmountField.assigned);
    case PlanDetailsAction.showActivity:
      showPlanActivity(context, month, summary.category);
    case PlanDetailsAction.archive:
      await archivePlan(context, ref, summary.category);
  }
}
