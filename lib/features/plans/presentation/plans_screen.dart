import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
/// category (Assigned, Available in a pill coloured by status, and an
/// Activity button) in collapsible Spending, Savings and Liability sections
/// with their totals. Tap a row to edit its Assigned on the docked keypad,
/// whose Details button opens Target, status, editing and archiving.
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

  // The panel is docked over the bottom of the screen, covering the tab bar
  // like the phone's keyboard; the list gets room below to scroll past it.
  final _panelPortal = OverlayPortalController();
  double _panelHeight = 0;

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
    _panelPortal.show();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealEditingRow());
  }

  /// Scrolls the row being edited up out from under the panel.
  void _revealEditingRow() {
    final row = _editingRowKey.currentContext;
    if (row == null || !row.mounted || !mounted || _panelHeight == 0) return;
    final box = row.findRenderObject();
    final position = Scrollable.maybeOf(row)?.position;
    if (box is! RenderBox || !box.attached || position == null) return;
    final visibleBottom = MediaQuery.sizeOf(context).height - _panelHeight;
    final rowBottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    final overlap = rowBottom - visibleBottom + Spacing.sm;
    if (overlap <= 0) return;
    position.animateTo(
      (position.pixels + overlap).clamp(0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _panelResized(Size size) {
    if (!mounted || _editing == null || size.height == _panelHeight) return;
    setState(() => _panelHeight = size.height);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealEditingRow());
  }

  void _pressKey(AssignKey key) => setState(() {
    _draft = _draft?.press(key, currencyCode: Account.defaultCurrency);
    _assignError = null;
  });

  void _closeAssign() {
    _panelPortal.hide();
    setState(() {
      _editing = null;
      _editingMonth = null;
      _draft = null;
      _assignError = null;
      _panelHeight = 0;
    });
  }

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

  /// A row's Activity button. On the row being edited it saves first, as
  /// the panel's Activity does; another row's button was a tap outside,
  /// which has already saved.
  void _rowActivity(CalendarMonth month, CategoryPlanSummary summary) {
    if (_editing?.category.id == summary.category.id) {
      _assignActivity();
      return;
    }
    if (_editing != null && !_commitAssign()) return;
    showPlanActivity(context, month, summary.category);
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
    return OverlayPortal(
      controller: _panelPortal,
      overlayChildBuilder: (context) {
        if (_editing == null) return const SizedBox.shrink();
        if (summaries case AsyncData(value: final rows)) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: _SizeReporter(
              onSize: _panelResized,
              child: _assignPanel(rows),
            ),
          );
        }
        return const SizedBox.shrink();
      },
      child: Scaffold(
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
                MaterialPageRoute<void>(
                  builder: (_) => const CategoriesScreen(),
                ),
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
                  onActivityTap: (summary) => _rowActivity(month, summary),
                  editingId: _editing?.category.id,
                  draft: _draft,
                  editingRowKey: _editingRowKey,
                  // A little extra so the last row clears the panel's edge.
                  bottomPadding: _panelHeight == 0
                      ? 0
                      : _panelHeight + Spacing.md,
                ),
                AsyncError() => const CenteredMessage(
                  'Your plans could not be loaded.',
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Reports its child's size after each layout that changes it.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) => renderObject.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reported) return;
    _reported = size;
    final reported = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(reported));
  }
}

class _PlanList extends ConsumerWidget {
  const _PlanList({
    required this.month,
    required this.rows,
    required this.onAssignedTap,
    required this.onActivityTap,
    this.editingId,
    this.draft,
    this.editingRowKey,
    this.bottomPadding = 0,
  });

  final CalendarMonth month;
  final List<CategoryPlanSummary> rows;
  final ValueChanged<CategoryPlanSummary> onAssignedTap;
  final ValueChanged<CategoryPlanSummary> onActivityTap;

  /// The category whose Assigned is being edited, with what is typed.
  final String? editingId;
  final AssignDraft? draft;
  final Key? editingRowKey;

  /// Room below the last row, so it can scroll above the docked panel.
  final double bottomPadding;

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
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        ReadyToAssignCard(month: month),
        if (rows.isEmpty)
          const CenteredMessage(
            'No active plans.\nAdd a category or unarchive a plan.',
          ),
        // One section per group that has rows, in [PlanGroup] order.
        for (final group in PlanGroup.values)
          if (rows.any((row) => row.category.planGroup == group))
            // Nearly edge to edge with rounded corners: a tinted band for the
            // group, then its rows on the plain surface, with hairlines
            // between them.
            Padding(
              key: ValueKey(group),
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Spacing.md),
                child: ExpansionTile(
                  key: PageStorageKey('plans-group-${group.name}'),
                  initiallyExpanded: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainer,
                  collapsedBackgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainer,
                  // The right edge matches the rows, so the totals line up.
                  tilePadding: const EdgeInsets.only(
                    left: Spacing.sm,
                    right: Spacing.xs,
                  ),
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  title: _groupHeader(group),
                  children: [
                    for (final summary in _rowsIn(group)) ...[
                      const Divider(height: 1),
                      PlanRow(
                        key: summary.category.id == editingId
                            ? editingRowKey
                            : null,
                        summary: summary,
                        onTap: () => onAssignedTap(summary),
                        onActivityTap: () => onActivityTap(summary),
                        draft: summary.category.id == editingId ? draft : null,
                      ),
                    ],
                  ],
                ),
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
