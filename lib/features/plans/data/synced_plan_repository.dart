import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../core/sync/synced_database.dart';
import '../../../core/sync/synced_store.dart';
import '../../../core/time/calendar_month.dart';
import '../domain/monthly_plan.dart';
import '../domain/plan_deletion.dart';
import 'plan_repository.dart';

/// Monthly plans from the signed-in user's synchronized store. Read-only until
/// sync uploads arrive (S5.3).
class SyncedPlanRepository implements PlanRepository {
  SyncedPlanRepository(this._database);

  final SyncedDatabase _database;

  @override
  Stream<List<MonthlyPlan>> watchForMonth(CalendarMonth month) {
    final query = _database.select(_database.syncedMonthlyPlans)
      ..where(
        (plan) =>
            plan.month.equals(month.toIsoString()) &
            CustomExpression<bool>('NOT (${unsafePlan('monthly_plans')})'),
      )
      ..orderBy([
        (plan) => OrderingTerm(expression: plan.createdAt),
        (plan) => OrderingTerm(expression: plan.id),
      ]);
    return query.watch().map(
      (rows) => [for (final row in rows) syncedPlan(row)],
    );
  }

  @override
  Stream<PlanDeletionStatus> watchDeletionStatus(String categoryId) => _database
      .customSelect(
        PlanRepository.deletionStatusSql,
        variables: [Variable.withString(categoryId)],
        readsFrom: {
          _database.syncedCategories,
          _database.syncedMonthlyPlans,
          _database.syncedTransactions,
        },
      )
      .watchSingleOrNull()
      .map(PlanRepository.deletionStatusOf);

  /// Every write is unavailable until sync uploads arrive (S5.3), which
  /// replace this with real operations.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw const ReadOnlyStoreException();
}

MonthlyPlan syncedPlan(SyncedMonthlyPlanRow row) => MonthlyPlan(
  id: row.id,
  month: CalendarMonth.parse(row.month),
  categoryId: row.categoryId,
  target: switch (row.targetAmountMinor) {
    final minor? => Money(minorUnits: minor, currencyCode: row.currencyCode),
    null => null,
  },
  assigned: Money(
    minorUnits: row.assignedAmountMinor,
    currencyCode: row.currencyCode,
  ),
  createdAt: parseSyncedTimestamp(row.createdAt),
  updatedAt: parseSyncedTimestamp(row.updatedAt),
);
