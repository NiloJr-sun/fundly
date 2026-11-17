import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/calendar_month.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../spending/presentation/spending_providers.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../data/plan_repository.dart';
import '../domain/monthly_plan.dart';
import '../domain/plan_deletion.dart';
import '../domain/plan_summary.dart';

/// The month the Plans tab shows. Starts at the current month each time the
/// app starts.
class SelectedPlanMonthNotifier extends Notifier<CalendarMonth> {
  late CalendarMonth _lastCurrentMonth;

  @override
  CalendarMonth build() => _lastCurrentMonth = _currentMonth();

  void previous() => state = state.previous;

  void next() => state = state.next;

  void thisMonth() {
    _lastCurrentMonth = _currentMonth();
    state = _lastCurrentMonth;
  }

  /// Follow the current month across midnight or missed months, while keeping
  /// a month the user explicitly browsed to selected.
  void refreshCurrentMonth() {
    final current = _currentMonth();
    if (state == _lastCurrentMonth) state = current;
    _lastCurrentMonth = current;
  }

  CalendarMonth _currentMonth() => CalendarMonth.of(ref.read(todayProvider));
}

final selectedPlanMonthProvider =
    NotifierProvider<SelectedPlanMonthNotifier, CalendarMonth>(
      SelectedPlanMonthNotifier.new,
    );

/// Whether [selectedPlanMonthProvider] is the current month.
final isCurrentPlanMonthProvider = Provider<bool>(
  (ref) =>
      ref.watch(selectedPlanMonthProvider) ==
      CalendarMonth.of(ref.watch(todayProvider)),
);

/// The plans saved for one month.
final monthPlansProvider =
    StreamProvider.family<List<MonthlyPlan>, CalendarMonth>(
      (ref, month) => ref.watch(planRepositoryProvider).watchForMonth(month),
    );

/// Target, assigned, activity, available and status per spending category
/// for one month.
final planSummariesProvider =
    Provider.family<AsyncValue<List<CategoryPlanSummary>>, CalendarMonth>(
      (ref, month) => _summaries(ref, month, archived: false),
    );

/// All archived rows, even those without a saved plan in the selected month.
final archivedPlanSummariesProvider =
    Provider.family<AsyncValue<List<CategoryPlanSummary>>, CalendarMonth>(
      (ref, month) => _summaries(ref, month, archived: true),
    );

AsyncValue<List<CategoryPlanSummary>> _summaries(
  Ref ref,
  CalendarMonth month, {
  required bool archived,
}) {
  final categories = ref.watch(allCategoriesProvider);
  final plans = ref.watch(monthPlansProvider(month));
  final transactions = ref.watch(allTransactionsProvider);
  return switch ((categories, plans, transactions)) {
    (
      AsyncData(value: final c),
      AsyncData(value: final p),
      AsyncData(value: final t),
    ) =>
      AsyncData(
        planSummaries(
          month: month,
          categories: c,
          plans: p,
          transactions: t,
          archived: archived,
        ),
      ),
    (AsyncError(:final error, :final stackTrace), _, _) ||
    (_, AsyncError(:final error, :final stackTrace), _) ||
    (
      _,
      _,
      AsyncError(:final error, :final stackTrace),
    ) => AsyncError(error, stackTrace),
    _ => const AsyncLoading(),
  };
}

/// Current budget-account balance minus remaining allocations in [month]; see
/// [readyToAssign]. `null` (as data) when no budget account is chosen.
final readyToAssignProvider =
    Provider.family<AsyncValue<ReadyToAssign?>, CalendarMonth>((ref, month) {
      final categories = ref.watch(allCategoriesProvider);
      final accounts = ref.watch(allAccountsProvider);
      final plans = ref.watch(monthPlansProvider(month));
      final transactions = ref.watch(allTransactionsProvider);
      return switch ((accounts, plans, transactions, categories)) {
        (
          AsyncData(value: final a),
          AsyncData(value: final p),
          AsyncData(value: final t),
          AsyncData(value: final c),
        ) =>
          AsyncData(switch (a.where((account) => account.isBudgetAccount)) {
            final budget when budget.isEmpty => null,
            final budget => readyToAssign(
              month: month,
              budgetAccount: budget.first,
              plans: p,
              transactions: t,
              categories: c,
            ),
          }),
        (AsyncError(:final error, :final stackTrace), _, _, _) ||
        (_, AsyncError(:final error, :final stackTrace), _, _) ||
        (_, _, AsyncError(:final error, :final stackTrace), _) ||
        (
          _,
          _,
          _,
          AsyncError(:final error, :final stackTrace),
        ) => AsyncError(error, stackTrace),
        _ => const AsyncLoading(),
      };
    });

/// Live eligibility for permanently deleting an archived Plans row.
final planDeletionStatusProvider = StreamProvider.autoDispose
    .family<PlanDeletionStatus, int>(
      (ref, categoryId) =>
          ref.watch(planRepositoryProvider).watchDeletionStatus(categoryId),
    );
