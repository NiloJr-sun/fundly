import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../../core/time/calendar_month.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../spending/domain/period_summary.dart';
import '../../transactions/domain/transaction.dart';
import 'monthly_plan.dart';

/// Whether a category's assigned money covers its target.
enum PlanStatus {
  /// Assigned is at least the target.
  funded,

  /// Assigned is below the target.
  underfunded,
}

/// One category's target, assigned, activity and available amounts in one
/// month. Nothing carries over between months.
@immutable
final class CategoryPlanSummary {
  const CategoryPlanSummary({
    required this.category,
    required this.target,
    required this.assigned,
    required this.activity,
    required this.hasPlan,
  });

  final Category category;

  /// The month's budget, or `null` when no target is set.
  final Money? target;

  /// Money set aside this month; zero when nothing is assigned.
  final Money assigned;

  /// Spending dated in the month with this category. Zero or positive.
  final Money activity;

  /// Whether a plan is saved for this month (a target, an assigned amount,
  /// or both).
  final bool hasPlan;

  /// `assigned - activity`; negative when more was spent than assigned.
  Money get available => assigned - activity;

  bool get isOverspent => available.isNegative;

  /// [PlanStatus.funded] when assigned covers the target,
  /// [PlanStatus.underfunded] when it does not, and `null` without a target.
  /// Spending does not change the status; overspending shows in [available].
  PlanStatus? get status {
    final target = this.target;
    if (target == null) return null;
    return assigned.minorUnits >= target.minorUnits
        ? PlanStatus.funded
        : PlanStatus.underfunded;
  }

  @override
  bool operator ==(Object other) =>
      other is CategoryPlanSummary &&
      other.category == category &&
      other.target == target &&
      other.assigned == assigned &&
      other.activity == activity &&
      other.hasPlan == hasPlan;

  @override
  int get hashCode =>
      Object.hash(category, target, assigned, activity, hasPlan);

  @override
  String toString() =>
      'CategoryPlanSummary(${category.name}, target: $target, '
      'assigned: $assigned, activity: $activity)';
}

/// One row per spending category for [month], in the order of [categories].
///
/// - Activity counts only Spending transactions dated in the month (rule 5):
///   transfers, card payments and inflows (including refunds) are ignored.
///   Card purchases are Spending, so they count once (rule 6).
/// - Rows cover active spending categories, plus any archived spending
///   category with a plan or spending this month, so no history is hidden.
/// - Inflow categories never appear: plans are for spending only.
/// - Plans for other months in [plans] are ignored.
List<CategoryPlanSummary> planSummaries({
  required CalendarMonth month,
  required Iterable<Category> categories,
  required Iterable<MonthlyPlan> plans,
  required Iterable<TransactionDraft> transactions,
  String currencyCode = Account.defaultCurrency,
}) {
  final planByCategory = {
    for (final plan in plans)
      if (plan.month == month) plan.categoryId: plan,
  };

  final range = month.dateRange;
  final activityByCategory = <int, Money>{};
  for (final transaction in transactions) {
    final categoryId = transaction.categoryId;
    if (!transaction.type.countsAsSpending ||
        categoryId == null ||
        !range.contains(transaction.date)) {
      continue;
    }
    activityByCategory[categoryId] =
        (activityByCategory[categoryId] ?? Money.zero(currencyCode)) +
        transaction.amount;
  }

  return [
    for (final category in categories)
      if (category.kind == CategoryKind.spending &&
          (!category.isArchived ||
              planByCategory.containsKey(category.id) ||
              activityByCategory.containsKey(category.id)))
        CategoryPlanSummary(
          category: category,
          target: planByCategory[category.id]?.target,
          assigned:
              planByCategory[category.id]?.assigned ?? Money.zero(currencyCode),
          activity: activityByCategory[category.id] ?? Money.zero(currencyCode),
          hasPlan: planByCategory.containsKey(category.id),
        ),
  ];
}

/// The month's income set against what has been assigned to categories.
@immutable
final class ReadyToAssign {
  const ReadyToAssign({required this.income, required this.assigned});

  /// Inflow transactions dated in the month.
  final Money income;

  /// Every category's assigned amount for the month.
  final Money assigned;

  /// `income - assigned`; negative when more was assigned than received.
  Money get amount => income - assigned;

  @override
  bool operator ==(Object other) =>
      other is ReadyToAssign &&
      other.income == income &&
      other.assigned == assigned;

  @override
  int get hashCode => Object.hash(income, assigned);

  @override
  String toString() => 'ReadyToAssign(income: $income, assigned: $assigned)';
}

/// How much of [month]'s income is not yet assigned (CLAUDE.md §11).
///
/// - Income is every Inflow transaction dated in the month, into any account
///   (archived ones included), as in the Spending tab's inflow total.
///   Transfers and card payments never count.
/// - Assigned is the total of every plan's assigned amount for the month,
///   archived categories included.
/// - Nothing carries over between months.
ReadyToAssign readyToAssign({
  required CalendarMonth month,
  required Iterable<MonthlyPlan> plans,
  required Iterable<TransactionDraft> transactions,
  String currencyCode = Account.defaultCurrency,
}) {
  var assigned = Money.zero(currencyCode);
  for (final plan in plans) {
    if (plan.month == month) assigned += plan.assigned;
  }
  return ReadyToAssign(
    income: periodTotals(
      transactions,
      month.dateRange,
      currencyCode: currencyCode,
    ).inflow,
    assigned: assigned,
  );
}
