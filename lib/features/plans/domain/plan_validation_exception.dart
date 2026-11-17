import '../../../core/money/money.dart';
import '../../../core/time/calendar_month.dart';

/// Why a monthly plan could not be saved.
enum PlanValidationError {
  /// Target and assigned amounts are zero or positive.
  amountNegative,

  categoryNotFound,

  /// Plans compare against spending, so only spending categories have them.
  categoryNotSpending,

  /// A new plan cannot use an archived category; existing plans are kept.
  categoryArchived,

  /// Unarchive the Plans row before editing it.
  planArchived,

  /// Current or future months still reserve money in the budget account.
  hasAllocation,
}

class PlanValidationException implements Exception {
  const PlanValidationException(this.error);

  final PlanValidationError error;

  @override
  String toString() => 'PlanValidationException(${error.name})';
}

/// Every month that prevents a row being archived, checked inside the write
/// transaction against the actual current month rather than the displayed one.
class PlanArchiveBlocked extends PlanValidationException {
  PlanArchiveBlocked(Map<CalendarMonth, Money> remaining)
    : remainingByMonth = Map.unmodifiable(remaining),
      super(PlanValidationError.hasAllocation);

  final Map<CalendarMonth, Money> remainingByMonth;
}
