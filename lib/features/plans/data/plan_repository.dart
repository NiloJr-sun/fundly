import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/record_id.dart';
import '../../../core/money/money.dart';
import '../../../core/sync/synced_store.dart';
import '../../../core/time/calendar_month.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/monthly_plan.dart';
import '../domain/plan_deletion.dart';
import '../domain/plan_summary.dart';
import '../domain/plan_validation_exception.dart';
import 'synced_plan_repository.dart';

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

  /// Saves the [target] and [assigned] amount for [categoryId] in [month],
  /// creating the plan or replacing both amounts. A `null` [target] means no
  /// target. With no target and nothing assigned the plan is removed, since
  /// it would say nothing.
  ///
  /// Returns the saved plan, or `null` when it was removed. Throws
  /// [PlanValidationException] when a rule is broken. An archived category's
  /// existing plan may still be changed; a new one is rejected.
  Future<MonthlyPlan?> save({
    required CalendarMonth month,
    required String categoryId,
    required Money? target,
    required Money assigned,
  }) async {
    if (target != null) _requireSupportedCurrency(target);
    _requireSupportedCurrency(assigned);
    if ((target?.isNegative ?? false) || assigned.isNegative) {
      throw const PlanValidationException(PlanValidationError.amountNegative);
    }
    return _database.transaction(() async {
      final category = await (_database.select(
        _database.categories,
      )..where((c) => c.id.equals(rowIdOf(categoryId)))).getSingleOrNull();
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

      if (category.isPlanDeleted) {
        throw const PlanValidationException(PlanValidationError.planDeleted);
      }
      if (category.isPlanArchived) {
        throw const PlanValidationException(PlanValidationError.planArchived);
      }
      if (target == null && assigned.isZero) {
        await clear(month: month, categoryId: categoryId);
        return null;
      }

      final existing = await _find(month, categoryId);
      final now = _now().toUtc();
      if (existing != null) {
        final rows =
            await (_database.update(
              _plans,
            )..where((plan) => plan.id.equals(existing.id))).writeReturning(
              MonthlyPlansCompanion(
                targetAmountMinor: Value(target?.minorUnits),
                assignedAmountMinor: Value(assigned.minorUnits),
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
              categoryId: rowIdOf(categoryId),
              targetAmountMinor: Value(target?.minorUnits),
              assignedAmountMinor: assigned.minorUnits,
              currencyCode: assigned.currencyCode,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return _toDomain(row);
    });
  }

  /// Archives the row across months, independently of its category/account.
  /// Current/future remaining allocations must be zero. Historical assignments
  /// remain intact. Transaction edits after archiving still count in Ready to
  /// assign, so archiving never silently releases money.
  Future<void> setArchived(
    String categoryId, {
    required bool archived,
  }) => _database.transaction(() async {
    final category = await (_database.select(
      _database.categories,
    )..where((c) => c.id.equals(rowIdOf(categoryId)))).getSingleOrNull();
    if (category == null) {
      throw const PlanValidationException(PlanValidationError.categoryNotFound);
    }
    if (category.kind != CategoryKind.spending) {
      throw const PlanValidationException(
        PlanValidationError.categoryNotSpending,
      );
    }
    if (category.isPlanDeleted) {
      throw const PlanValidationException(PlanValidationError.planDeleted);
    }
    if (!archived && category.isArchived) {
      throw const PlanValidationException(PlanValidationError.categoryArchived);
    }
    if (archived && !category.isPlanArchived) {
      final today = _now().toLocal();
      final currentMonth = CalendarMonth(today.year, today.month);
      final plans =
          await (_database.select(_plans)
                ..where(
                  (p) =>
                      p.categoryId.equals(rowIdOf(categoryId)) &
                      p.month.isBiggerOrEqualValue(currentMonth.toIsoString()),
                )
                ..orderBy([(p) => OrderingTerm(expression: p.month)]))
              .get();
      final budget = await (_database.select(
        _database.accounts,
      )..where((a) => a.isBudgetAccount.equals(true))).getSingleOrNull();
      final entries = budget == null
          ? <TransactionDraft>[]
          : [
              for (final row
                  in await (_database.select(_database.transactions)..where(
                        (t) =>
                            t.sourceAccountId.equals(budget.id) &
                            t.date.isBiggerOrEqualValue(
                              currentMonth.dateRange.start.toIsoString(),
                            ),
                      ))
                      .get())
                TransactionDraft(
                  type: row.type,
                  date: row.date,
                  amount: Money(
                    minorUnits: row.amountMinor,
                    currencyCode: row.currencyCode,
                  ),
                  categoryId: recordIdOrNull(row.categoryId),
                  sourceAccountId: recordIdOrNull(row.sourceAccountId),
                  destinationAccountId: recordIdOrNull(
                    row.destinationAccountId,
                  ),
                ),
            ];
      final remaining = <CalendarMonth, Money>{};
      for (final row in plans) {
        final plan = _toDomain(row);
        final allocation = remainingPlanAllocation(
          plan: plan,
          budgetAccountId: recordIdOrNull(budget?.id),
          linkedAccountId: recordIdOrNull(category.linkedAccountId),
          transactions: entries,
        );
        if (!allocation.isZero) remaining[plan.month] = allocation;
      }
      if (remaining.isNotEmpty) throw PlanArchiveBlocked(remaining);
    }
    await (_database.update(_database.categories)
          ..where((c) => c.id.equals(rowIdOf(categoryId))))
        .write(CategoriesCompanion(isPlanArchived: Value(archived)));
  });

  /// Eligibility watches all months and all activity, including backdated or
  /// future transactions. Read errors never enable the destructive action.
  Stream<PlanDeletionStatus> watchDeletionStatus(String categoryId) =>
      _deletionQuery(categoryId).watchSingleOrNull().map(deletionStatusOf);

  /// Removes every monthly plan while preserving the category/account. The
  /// deletion flag prevents automatic liability sync or unarchive from reviving
  /// the row. Eligibility is rechecked atomically even if the UI was enabled.
  Future<void> deletePermanently(String categoryId) =>
      _database.transaction(() async {
        final status = deletionStatusOf(
          await _deletionQuery(categoryId).getSingleOrNull(),
        );
        if (status != PlanDeletionStatus.allowed) {
          throw PlanDeletionException(status);
        }
        await (_database.delete(
          _plans,
        )..where((p) => p.categoryId.equals(rowIdOf(categoryId)))).go();
        await (_database.update(
          _database.categories,
        )..where((c) => c.id.equals(rowIdOf(categoryId)))).write(
          const CategoriesCompanion(
            isPlanArchived: Value(true),
            isPlanDeleted: Value(true),
          ),
        );
      });

  /// One query shared by the preview stream and the guarded write. Liability
  /// rows count payments into their account; ordinary rows count spending in
  /// their category, matching their Plans Activity definition.
  Selectable<QueryRow> _deletionQuery(String categoryId) =>
      _database.customSelect(
        deletionStatusSql,
        variables: [Variable.withInt(rowIdOf(categoryId))],
        readsFrom: {_database.categories, _plans, _database.transactions},
      );

  /// The deletion-status query, shared with the synchronized store, whose
  /// tables and columns have the same names.
  static const deletionStatusSql = """
    SELECT c.kind, c.is_archived, c.is_plan_archived, c.is_plan_deleted,
      EXISTS(SELECT 1 FROM monthly_plans p
        WHERE p.category_id = c.id AND p.assigned_amount_minor != 0) AS has_assigned,
      EXISTS(SELECT 1 FROM transactions t WHERE
        (c.linked_account_id IS NULL AND t.type = 'spending' AND t.category_id = c.id)
        OR (c.linked_account_id IS NOT NULL
          AND t.destination_account_id = c.linked_account_id
          AND t.type IN ('transfer', 'creditCardPayment'))) AS has_activity
    FROM categories c WHERE c.id = ?
    """;

  static PlanDeletionStatus deletionStatusOf(QueryRow? row) {
    if (row == null) return PlanDeletionStatus.categoryNotFound;
    if (row.read<String>('kind') != 'spending') {
      return PlanDeletionStatus.categoryNotSpending;
    }
    if (row.read<bool>('is_plan_deleted')) {
      return PlanDeletionStatus.alreadyDeleted;
    }
    if (!row.read<bool>('is_archived') && !row.read<bool>('is_plan_archived')) {
      return PlanDeletionStatus.notArchived;
    }
    if (row.read<bool>('has_assigned')) {
      return PlanDeletionStatus.hasAssignedMoney;
    }
    if (row.read<bool>('has_activity')) return PlanDeletionStatus.hasActivity;
    return PlanDeletionStatus.allowed;
  }

  /// Removes the plan for [categoryId] in [month]: no target and nothing
  /// assigned.
  /// Does nothing if there is no such plan.
  Future<void> clear({
    required CalendarMonth month,
    required String categoryId,
  }) async {
    await (_database.delete(_plans)..where(
          (plan) =>
              plan.month.equalsValue(month) &
              plan.categoryId.equals(rowIdOf(categoryId)),
        ))
        .go();
  }

  Future<MonthlyPlanRow?> _find(CalendarMonth month, String categoryId) =>
      (_database.select(_plans)..where(
            (plan) =>
                plan.month.equalsValue(month) &
                plan.categoryId.equals(rowIdOf(categoryId)),
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
    id: recordIdOf(row.id),
    month: row.month,
    categoryId: recordIdOf(row.categoryId),
    target: switch (row.targetAmountMinor) {
      final minor? => Money(minorUnits: minor, currencyCode: row.currencyCode),
      null => null,
    },
    assigned: Money(
      minorUnits: row.assignedAmountMinor,
      currencyCode: row.currencyCode,
    ),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  final synced = ref.watch(syncedStoreProvider);
  return synced == null
      ? PlanRepository(ref.watch(appDatabaseProvider))
      : SyncedPlanRepository(synced.database);
});
