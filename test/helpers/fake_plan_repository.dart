import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/plans/data/plan_repository.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';

/// Records calls for widget tests, which cannot await a real drift database
/// under the fake test clock. Repository behaviour itself is covered by
/// `plan_repository_test.dart` against an in-memory database.
class FakePlanRepository implements PlanRepository {
  final List<
    ({CalendarMonth month, int categoryId, Money? target, Money assigned})
  >
  saved = [];
  final List<({CalendarMonth month, int categoryId})> cleared = [];

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
