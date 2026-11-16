import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/date_range.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../domain/period_summary.dart';

/// The period the Spending tab totals cover. Defaults to the current
/// calendar month (CLAUDE.md §11). Roadmap task 3.3 makes it selectable.
final currentPeriodProvider = Provider<DateRange>(
  (ref) => DateRange.monthOf(CalendarDate.today()),
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
