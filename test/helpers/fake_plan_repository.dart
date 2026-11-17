import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/plans/data/plan_repository.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/domain/plan_deletion.dart';
import 'package:fundly/features/plans/domain/plan_validation_exception.dart';

/// Records calls for widget tests, which cannot await a real drift database
/// under the fake test clock. Repository behaviour itself is covered by
/// `plan_repository_test.dart` against an in-memory database.
class FakePlanRepository implements PlanRepository {
  final List<
    ({CalendarMonth month, int categoryId, Money? target, Money assigned})
  >
  saved = [];
  final List<({CalendarMonth month, int categoryId})> cleared = [];

  final List<({int categoryId, bool archived})> archivedChanges = [];
  PlanArchiveBlocked? archiveBlocked;
  bool failArchive = false;
  void Function(int categoryId, bool archived)? onArchive;

  final List<int> deleted = [];
  PlanDeletionStatus deletionStatus = PlanDeletionStatus.allowed;
  PlanDeletionStatus? deleteBlocked;
  bool failDeletionCheck = false;
  Stream<PlanDeletionStatus>? deletionStatusStream;
  bool failDelete = false;
  void Function(int categoryId)? onDelete;

  @override
  Stream<PlanDeletionStatus> watchDeletionStatus(int categoryId) =>
      deletionStatusStream ??
      (failDeletionCheck
          ? Stream.error(StateError('Deletion check failed'))
          : Stream.value(deletionStatus));

  @override
  Future<void> deletePermanently(int categoryId) async {
    if (deleteBlocked case final status?) throw PlanDeletionException(status);
    if (failDelete) throw StateError('Delete failed');
    deleted.add(categoryId);
    onDelete?.call(categoryId);
  }

  @override
  Future<void> setArchived(int categoryId, {required bool archived}) async {
    if (archiveBlocked case final failure?) throw failure;
    if (failArchive) throw StateError('Archive failed');
    archivedChanges.add((categoryId: categoryId, archived: archived));
    onArchive?.call(categoryId, archived);
  }

  @override
  Stream<List<MonthlyPlan>> watchForMonth(CalendarMonth month) =>
      Stream.value(const []);

  @override
  Future<MonthlyPlan?> save({
    required CalendarMonth month,
    required int categoryId,
    required Money? target,
    required Money assigned,
  }) async {
    saved.add((
      month: month,
      categoryId: categoryId,
      target: target,
      assigned: assigned,
    ));
    return MonthlyPlan(
      id: saved.length,
      month: month,
      categoryId: categoryId,
      target: target,
      assigned: assigned,
      createdAt: DateTime.utc(2026, 11, 16),
      updatedAt: DateTime.utc(2026, 11, 16),
    );
  }

  @override
  Future<void> clear({
    required CalendarMonth month,
    required int categoryId,
  }) async {
    cleared.add((month: month, categoryId: categoryId));
  }
}
