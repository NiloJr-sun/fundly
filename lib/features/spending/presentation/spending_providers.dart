import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock_provider.dart';
import '../../../core/time/date_range.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../domain/period_summary.dart';

/// Today's local date. Override in tests to fix the date.
final todayProvider = Provider<CalendarDate>(
  (ref) => CalendarDate.today(clock: ref.watch(clockProvider)),
);

/// Which kind of period the user picked.
enum PeriodPreset { thisMonth, lastMonth, custom }

@immutable
final class PeriodSelection {
  const PeriodSelection(this.preset, this.range);

  final PeriodPreset preset;
  final DateRange range;

  @override
  bool operator ==(Object other) =>
      other is PeriodSelection &&
      other.preset == preset &&
      other.range == range;

  @override
  int get hashCode => Object.hash(preset, range);
}

/// The period the Spending tab totals cover. Starts at the current calendar
/// month (CLAUDE.md §11) each time the app starts.
class SelectedPeriodNotifier extends Notifier<PeriodSelection> {
  @override
  PeriodSelection build() => _thisMonth();

  void selectThisMonth() => state = _thisMonth();

  void selectLastMonth() => state = PeriodSelection(
    PeriodPreset.lastMonth,
    DateRange.monthBefore(ref.read(todayProvider)),
  );

  void selectCustom(DateRange range) =>
      state = PeriodSelection(PeriodPreset.custom, range);

  PeriodSelection _thisMonth() => PeriodSelection(
    PeriodPreset.thisMonth,
    DateRange.monthOf(ref.read(todayProvider)),
  );
}

final selectedPeriodProvider =
    NotifierProvider<SelectedPeriodNotifier, PeriodSelection>(
      SelectedPeriodNotifier.new,
    );

/// The date range of [selectedPeriodProvider].
final currentPeriodProvider = Provider<DateRange>(
  (ref) => ref.watch(selectedPeriodProvider).range,
);

/// The dates the Spending tab's transaction list is limited to: `null` for
/// This month (the newest transactions overall), otherwise the selected
/// period.
final transactionListRangeProvider = Provider<DateRange?>((ref) {
  final selection = ref.watch(selectedPeriodProvider);
  return selection.preset == PeriodPreset.thisMonth ? null : selection.range;
});

/// Transactions for the Spending tab's list, newest first, limited to
/// [transactionListRangeProvider].
final spendingTabTransactionsProvider = Provider<AsyncValue<List<Transaction>>>(
  (ref) {
    final filter = TransactionFilter(
      dateRange: ref.watch(transactionListRangeProvider),
    );
    return ref.watch(allTransactionsProvider).whenData(filter.apply);
  },
);

/// Available money, Credit owed and Loans owed (D2).
final balanceSummaryProvider = Provider<AsyncValue<BalanceSummary>>((ref) {
  final accounts = ref.watch(allAccountsProvider);
  final balances = ref.watch(accountBalancesProvider);
  return switch ((accounts, balances)) {
    (AsyncData(value: final a), AsyncData(value: final b)) => AsyncData(
      summarizeBalances(a, b),
    ),
    (AsyncError(:final error, :final stackTrace), _) ||
    (
      _,
      AsyncError(:final error, :final stackTrace),
    ) => AsyncError(error, stackTrace),
    _ => const AsyncLoading(),
  };
});

/// Inflow and spending totals for [currentPeriodProvider] (rule 5).
final periodTotalsProvider = Provider<AsyncValue<PeriodTotals>>((ref) {
  final period = ref.watch(currentPeriodProvider);
  return ref
      .watch(allTransactionsProvider)
      .whenData((transactions) => periodTotals(transactions, period));
});
