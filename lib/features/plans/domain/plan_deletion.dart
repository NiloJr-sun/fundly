/// Why permanent deletion is allowed or blocked. Checked across all months,
/// independently of whichever month is displayed in the archived list.
enum PlanDeletionStatus {
  allowed,
  categoryNotFound,
  categoryNotSpending,
  alreadyDeleted,
  notArchived,
  hasAssignedMoney,
  hasActivity,
}

class PlanDeletionException implements Exception {
  const PlanDeletionException(this.status);

  final PlanDeletionStatus status;

  @override
  String toString() => 'PlanDeletionException(${status.name})';
}
