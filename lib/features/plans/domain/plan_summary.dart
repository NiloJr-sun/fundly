import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../../core/time/calendar_month.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_balance.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
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

/// Current budget-account balance and the selected month's allocations.
@immutable
final class ReadyToAssign {
  const ReadyToAssign({
    required this.balance,
    required this.assigned,
    required this.remaining,
  });

  final Money balance;
  final Money assigned;

  /// Assigned money still reserved, after eligible spending per category.
  final Money remaining;

  Money get amount => balance - remaining;

  @override
  bool operator ==(Object other) =>
      other is ReadyToAssign &&
      other.balance == balance &&
      other.assigned == assigned &&
      other.remaining == remaining;

  @override
  int get hashCode => Object.hash(balance, assigned, remaining);
}

/// Current balance (including opening money and all recorded transactions)
/// minus the selected month's remaining allocations. This is a live balance,
/// even when viewing another month; monthly allocations do not carry over.
/// Only Spending from the budget account in that month releases an allocation.
/// Each category's remaining allocation is floored at zero so overspending
/// cannot release money reserved for other categories. Transfers and card
/// payments affect the balance but never release category allocations.
ReadyToAssign readyToAssign({
  required CalendarMonth month,
  required Account budgetAccount,
  required Iterable<MonthlyPlan> plans,
  required Iterable<TransactionDraft> transactions,
}) {
  final entries = transactions.toList();
  final zero = Money.zero(budgetAccount.openingBalance.currencyCode);
  final spent = <int, Money>{};
  for (final transaction in entries) {
    final category = transaction.categoryId;
    if (transaction.type == TransactionType.spending &&
        transaction.sourceAccountId == budgetAccount.id &&
        month.dateRange.contains(transaction.date) &&
        category != null) {
      spent[category] = (spent[category] ?? zero) + transaction.amount;
    }
  }
  var assigned = zero;
  var remaining = zero;
  for (final plan in plans) {
    if (plan.month != month) continue;
    assigned += plan.assigned;
    final unspent = plan.assigned - (spent[plan.categoryId] ?? zero);
    if (!unspent.isNegative) remaining += unspent;
  }
  return ReadyToAssign(
    balance: currentBalance(budgetAccount, entries),
    assigned: assigned,
    remaining: remaining,
  );
}
