import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_month.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../domain/monthly_plan.dart';
import '../domain/plan_validation_exception.dart';

/// Reads and writes [MonthlyPlan]s, enforcing the plan rules before anything
/// reaches the database.
class PlanRepository {
  PlanRepository(this._database, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _now;

  $MonthlyPlansTable get _plans => _database.monthlyPlans;

  /// The plans for [month], ordered by category id (creation order).
  Stream<List<MonthlyPlan>> watchForMonth(CalendarMonth month) {
    final query = _database.select(_plans)
      ..where((plan) => plan.month.equalsValue(month))
      ..orderBy([(plan) => OrderingTerm(expression: plan.categoryId)]);
    return query.watch().map(
      (rows) => [for (final row in rows) _toDomain(row)],
    );
  }

  /// Sets the planned [amount] for [categoryId] in [month], creating the plan
  /// or replacing its amount.
  ///
  /// Throws [PlanValidationException] when a rule is broken. An archived
  /// category's existing plan may still be changed; a new one is rejected.
  Future<MonthlyPlan> setPlannedAmount({
    required CalendarMonth month,
    required int categoryId,
    required Money amount,
  }) async {
    _requireSupportedCurrency(amount);
    if (amount.isNegative) {
      throw const PlanValidationException(PlanValidationError.amountNegative);
    }
    return _database.transaction(() async {
      final category = await (_database.select(
        _database.categories,
      )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
      if (category == null) {
        throw const PlanValidationException(
          PlanValidationError.categoryNotFound,
        );
      }
      if (category.kind != CategoryKind.spending) {
        throw const PlanValidationException(
          PlanValidationError.categoryNotSpending,
        );
      }

      final existing = await _find(month, categoryId);
      final now = _now().toUtc();
      if (existing != null) {
        final rows =
            await (_database.update(
              _plans,
            )..where((plan) => plan.id.equals(existing.id))).writeReturning(
              MonthlyPlansCompanion(
                plannedAmountMinor: Value(amount.minorUnits),
                updatedAt: Value(now),
              ),
            );
        return _toDomain(rows.single);
      }

      if (category.isArchived) {
        throw const PlanValidationException(
          PlanValidationError.categoryArchived,
        );
      }
      final row = await _database
          .into(_plans)
          .insertReturning(
            MonthlyPlansCompanion.insert(
              month: month,
              categoryId: categoryId,
              plannedAmountMinor: amount.minorUnits,
              currencyCode: amount.currencyCode,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return _toDomain(row);
    });
  }

  /// Removes the plan for [categoryId] in [month], leaving it unplanned.
  /// Does nothing if there is no such plan.
  Future<void> clear({
    required CalendarMonth month,
    required int categoryId,
  }) async {
    await (_database.delete(_plans)..where(
          (plan) =>
              plan.month.equalsValue(month) &
              plan.categoryId.equals(categoryId),
        ))
        .go();
  }

  Future<MonthlyPlanRow?> _find(CalendarMonth month, int categoryId) =>
      (_database.select(_plans)..where(
            (plan) =>
                plan.month.equalsValue(month) &
                plan.categoryId.equals(categoryId),
          ))
          .getSingleOrNull();

  /// All amounts are PHP in the MVP (G6); anything else is a programming
  /// error rather than user input.
  void _requireSupportedCurrency(Money amount) {
    if (amount.currencyCode != Account.defaultCurrency) {
      throw ArgumentError.value(
        amount.currencyCode,
        'currencyCode',
        'Only ${Account.defaultCurrency} plans are supported.',
      );
    }
  }

  static MonthlyPlan _toDomain(MonthlyPlanRow row) => MonthlyPlan(
    id: row.id,
    month: row.month,
    categoryId: row.categoryId,
    plannedAmount: Money(
      minorUnits: row.plannedAmountMinor,
      currencyCode: row.currencyCode,
    ),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => PlanRepository(ref.watch(appDatabaseProvider)),
);
