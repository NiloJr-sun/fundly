/// Why a monthly plan could not be saved.
enum PlanValidationError {
  /// Target and assigned amounts are zero or positive.
  amountNegative,

  categoryNotFound,

  /// Plans compare against spending, so only spending categories have them.
  categoryNotSpending,

  /// A new plan cannot use an archived category; existing plans are kept.
  categoryArchived,
}

class PlanValidationException implements Exception {
  const PlanValidationException(this.error);

  final PlanValidationError error;

  @override
  String toString() => 'PlanValidationException(${error.name})';
}
