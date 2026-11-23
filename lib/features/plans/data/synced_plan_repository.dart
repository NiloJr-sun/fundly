import 'package:drift/drift.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../core/money/money.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/synced_database.dart';
import '../../../core/time/calendar_month.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/monthly_plan.dart';
import '../domain/plan_deletion.dart';
import '../domain/plan_summary.dart';
import '../domain/plan_validation_exception.dart';
import 'plan_repository.dart';

/// The device's IANA time zone, for example `Asia/Manila`.
Future<String> deviceTimeZone() async =>
    (await FlutterTimezone.getLocalTimezone()).identifier;

/// Monthly plans in the signed-in user's synchronized store. Writes apply
/// locally at once and queue the matching operation for upload (S5.3), with
/// the same rules as the local store.
class SyncedPlanRepository implements PlanRepository {
  SyncedPlanRepository(
    this._database, {
    DateTime Function()? clock,
    Future<String> Function()? timeZone,
  }) : _now = clock ?? DateTime.now,
       _timeZone = timeZone ?? deviceTimeZone;

  final SyncedDatabase _database;
  final DateTime Function() _now;

  /// Archiving sends it: the server judges "current month" in this zone
  /// when the change uploads (PLANS_API.md).
  final Future<String> Function() _timeZone;

  $SyncedMonthlyPlansTable get _plans => _database.syncedMonthlyPlans;

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
  Stream<PlanDeletionStatus> watchDeletionStatus(String categoryId) =>
      _deletionQuery(categoryId)
          .watchSingleOrNull()
          .map(PlanRepository.deletionStatusOf);

  @override
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
    return _database.writeAndQueue(() async {
      final category = await _category(categoryId);
      if (category.kind != CategoryKind.spending.name) {
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
      final existing = await _find(month, categoryId);
      if (target == null && assigned.isZero) {
        // Nothing to say: the plan is removed (and nothing is sent if there
        // was none, which the server would treat as a no-op).
        if (existing == null) return (null, <SyncOperation>[]);
        await (_database.delete(
          _plans,
        )..where((plan) => plan.id.equals(existing.id))).go();
        return (
          null,
          [
            _saveOperation(
              existing.id,
              existing,
              month,
              categoryId,
              target,
              assigned,
            ),
          ],
        );
      }
      final now = syncedTimestamp(_now());
      if (existing != null) {
        final rows =
            await (_database.update(
              _plans,
            )..where((plan) => plan.id.equals(existing.id))).writeReturning(
              SyncedMonthlyPlansCompanion(
                targetAmountMinor: Value(target?.minorUnits),
                assignedAmountMinor: Value(assigned.minorUnits),
                updatedAt: Value(now),
                revision: Value(nextRevision(existing.revision)),
              ),
            );
        return (
          syncedPlan(rows.single),
          [
            _saveOperation(
              existing.id,
              existing,
              month,
              categoryId,
              target,
              assigned,
            ),
          ],
        );
      }
      if (category.isArchived) {
        throw const PlanValidationException(
          PlanValidationError.categoryArchived,
        );
      }
      final id = newRecordId();
      final row = await _database
          .into(_plans)
          .insertReturning(
            SyncedMonthlyPlansCompanion.insert(
              id: id,
              month: month.toIsoString(),
              categoryId: categoryId,
              targetAmountMinor: Value(target?.minorUnits),
              assignedAmountMinor: assigned.minorUnits,
              currencyCode: assigned.currencyCode,
              createdAt: now,
              updatedAt: now,
              revision: 1,
            ),
          );
      return (
        syncedPlan(row),
        [_saveOperation(id, null, month, categoryId, target, assigned)],
      );
    });
  }

  /// `plan.save` addresses the plan by category and month; `previous` is
  /// the record this device saw, so a plan another device created or changed
  /// meanwhile is a conflict rather than overwritten.
  static SyncOperation _saveOperation(
    String id,
    SyncedMonthlyPlanRow? previous,
    CalendarMonth month,
    String categoryId,
    Money? target,
    Money assigned,
  ) => SyncOperation(
    'plan.save',
    id,
    data: {
      'category_id': categoryId,
      'month': month.toIsoString(),
      'target_amount_minor': target == null
          ? null
          : wireMinor(target.minorUnits),
      'assigned_amount_minor': wireMinor(assigned.minorUnits),
      'previous': previous == null
          ? null
          : {'id': previous.id, 'revision': previous.revision.toString()},
    },
  );

  @override
  Future<void> clear({
    required CalendarMonth month,
    required String categoryId,
  }) => save(
    month: month,
    categoryId: categoryId,
    target: null,
    assigned: const Money.zero(Account.defaultCurrency),
  );

  @override
  Future<void> setArchived(String categoryId, {required bool archived}) async {
    // Read before the transaction: it waits on the platform.
    final timeZone = archived ? await _timeZone() : null;
    await _database.writeAndQueue(() async {
      final category = await _category(categoryId);
      if (category.kind != CategoryKind.spending.name) {
        throw const PlanValidationException(
          PlanValidationError.categoryNotSpending,
        );
      }
      if (category.isPlanDeleted) {
        throw const PlanValidationException(PlanValidationError.planDeleted);
      }
      if (!archived && category.isArchived) {
        throw const PlanValidationException(
          PlanValidationError.categoryArchived,
        );
      }
      // Already in that state: the server keeps the revision, so nothing is
      // changed or sent.
      if (category.isPlanArchived == archived) {
        return (null, <SyncOperation>[]);
      }
      if (archived) await _requireNoRemainingAllocation(category);
      await (_database.update(
        _database.syncedCategories,
      )..where((c) => c.id.equals(categoryId))).write(
        SyncedCategoriesCompanion(
          isPlanArchived: Value(archived),
          updatedAt: Value(syncedTimestamp(_now())),
          revision: Value(nextRevision(category.revision)),
        ),
      );
      return (
        null,
        [
          SyncOperation(
            'plan.set_archived',
            categoryId,
            expectedRevision: category.revision,
            data: {'archived': archived, 'timezone': ?timeZone},
          ),
        ],
      );
    });
  }

  /// The local store's archive rule: no month from the current one onwards
  /// may still hold money reserved from the budget account.
  Future<void> _requireNoRemainingAllocation(SyncedCategoryRow category) async {
    final today = _now().toLocal();
    final currentMonth = CalendarMonth(today.year, today.month);
    final plans =
        await (_database.select(_plans)
              ..where(
                (p) =>
                    p.categoryId.equals(category.id) &
                    p.month.isBiggerOrEqualValue(currentMonth.toIsoString()),
              )
              ..orderBy([(p) => OrderingTerm(expression: p.month)]))
            .get();
    final budgetIds = {
      for (final account in await (_database.select(
        _database.syncedAccounts,
      )..where((a) => a.isBudgetAccount.equals(true))).get())
        account.id,
    };
    final entries = budgetIds.isEmpty
        ? <TransactionDraft>[]
        : [
            for (final row
                in await (_database.select(_database.syncedTransactions)..where(
                      (t) =>
                          t.sourceAccountId.isIn(budgetIds) &
                          t.date.isBiggerOrEqualValue(
                            currentMonth.dateRange.start.toIsoString(),
                          ),
                    ))
                    .get())
              TransactionDraft(
                type: TransactionType.values.byName(row.type),
                date: parseSyncedDate(row.date),
                amount: Money(
                  minorUnits: row.amountMinor,
                  currencyCode: row.currencyCode,
                ),
                categoryId: row.categoryId,
                sourceAccountId: row.sourceAccountId,
                destinationAccountId: row.destinationAccountId,
              ),
          ];
    final remaining = <CalendarMonth, Money>{};
    for (final row in plans) {
      final plan = syncedPlan(row);
      final allocation = remainingPlanAllocation(
        plan: plan,
        budgetAccountIds: budgetIds,
        linkedAccountId: category.linkedAccountId,
        transactions: entries,
      );
      if (!allocation.isZero) remaining[plan.month] = allocation;
    }
    if (remaining.isNotEmpty) throw PlanArchiveBlocked(remaining);
  }

  @override
  Future<void> deletePermanently(String categoryId) =>
      _database.writeAndQueue(() async {
        final status = PlanRepository.deletionStatusOf(
          await _deletionQuery(categoryId).getSingleOrNull(),
        );
        if (status != PlanDeletionStatus.allowed) {
          throw PlanDeletionException(status);
        }
        final category = await _category(categoryId);
        await (_database.delete(
          _plans,
        )..where((p) => p.categoryId.equals(categoryId))).go();
        await (_database.update(
          _database.syncedCategories,
        )..where((c) => c.id.equals(categoryId))).write(
          SyncedCategoriesCompanion(
            isPlanArchived: const Value(true),
            isPlanDeleted: const Value(true),
            updatedAt: Value(syncedTimestamp(_now())),
            revision: Value(nextRevision(category.revision)),
          ),
        );
        return (
          null,
          [
            SyncOperation(
              'plan.delete_permanently',
              categoryId,
              expectedRevision: category.revision,
            ),
          ],
        );
      });

  Selectable<QueryRow> _deletionQuery(String categoryId) =>
      _database.customSelect(
        PlanRepository.deletionStatusSql,
        variables: [Variable.withString(categoryId)],
        readsFrom: {
          _database.syncedCategories,
          _database.syncedMonthlyPlans,
          _database.syncedTransactions,
        },
      );

  Future<SyncedCategoryRow> _category(String categoryId) async {
    final category = await (_database.select(
      _database.syncedCategories,
    )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
    if (category == null) {
      throw const PlanValidationException(PlanValidationError.categoryNotFound);
    }
    return category;
  }

  Future<SyncedMonthlyPlanRow?> _find(CalendarMonth month, String categoryId) =>
      (_database.select(_plans)..where(
            (plan) =>
                plan.month.equals(month.toIsoString()) &
                plan.categoryId.equals(categoryId),
          ))
          .getSingleOrNull();

  void _requireSupportedCurrency(Money amount) {
    if (amount.currencyCode != Account.defaultCurrency) {
      throw ArgumentError.value(
        amount.currencyCode,
        'currencyCode',
        'Only ${Account.defaultCurrency} plans are supported.',
      );
    }
  }
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
