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
/// month. Category targets and assignments do not carry over between months.
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

  /// Spending, or payments into a linked liability, dated in the month.
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
/// - Regular category Activity counts Spending only. Linked liability rows
///   count transfers and card payments into their account. Neither changes
///   spending/inflow totals; card purchases remain Spending in their category.
/// - Main rows exclude archived plans and categories. With [archived], all
///   archived spending rows are returned, including those without history.
/// - Inflow categories never appear: plans are for spending only.
/// - Plans for other months in [plans] are ignored.
List<CategoryPlanSummary> planSummaries({
  required CalendarMonth month,
  required Iterable<Category> categories,
  required Iterable<MonthlyPlan> plans,
  required Iterable<TransactionDraft> transactions,
  String currencyCode = Account.defaultCurrency,
  bool archived = false,
}) {
  final planByCategory = {
    for (final plan in plans)
      if (plan.month == month) plan.categoryId: plan,
  };

  final entries = transactions.toList();
  final activityByCategory = <String, Money>{};
  for (final category in categories) {
    var activity = Money.zero(currencyCode);
    for (final transaction in entries) {
      if (month.dateRange.contains(transaction.date) &&
          isCategoryPlanActivity(category, transaction)) {
        activity += transaction.amount;
      }
    }
    if (!activity.isZero) activityByCategory[category.id] = activity;
  }

  return [
    for (final category in categories)
      if (category.kind == CategoryKind.spending &&
          !category.isPlanDeleted &&
          category.isArchivedInPlans == archived)
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

/// Debt rows count payments to the linked account; regular rows count Spending.
/// Payments remain excluded from spending totals throughout the app.
bool isCategoryPlanActivity(Category category, TransactionDraft transaction) {
  final accountId = category.linkedAccountId;
  if (accountId != null) {
    return transaction.destinationAccountId == accountId &&
        (transaction.type == TransactionType.transfer ||
            transaction.type == TransactionType.creditCardPayment);
  }
  return transaction.type == TransactionType.spending &&
      transaction.categoryId == category.id;
}

/// Current budget-account balance and the selected month's allocations.
@immutable
final class ReadyToAssign {
  const ReadyToAssign({
    required this.balance,
    required this.carryOver,
    required this.assigned,
    required this.remaining,
  });

  final Money balance;

  /// Opening balance plus transactions before the selected month's first day.
  /// Already included in [balance]; never add it again as income or a transfer.
  final Money carryOver;
  final Money assigned;

  /// Assigned money still reserved, after eligible spending per category.
  final Money remaining;

  Money get amount => balance - remaining;

  @override
  bool operator ==(Object other) =>
      other is ReadyToAssign &&
      other.balance == balance &&
      other.carryOver == carryOver &&
      other.assigned == assigned &&
      other.remaining == remaining;

  @override
  int get hashCode => Object.hash(balance, carryOver, assigned, remaining);
}

/// Current balance (including opening money and all recorded transactions)
/// minus the selected month's remaining allocations. This is a live balance,
/// even when viewing another month; monthly allocations do not carry over.
/// Spending and linked liability payments from the budget account in that
/// month release their respective allocations.
/// Each category's remaining allocation is floored at zero so overspending
/// cannot release money reserved for other categories. Other transfers affect
/// the balance without releasing allocations.
ReadyToAssign readyToAssign({
  required CalendarMonth month,
  required Account budgetAccount,
  required Iterable<MonthlyPlan> plans,
  required Iterable<TransactionDraft> transactions,
  Iterable<Category> categories = const [],
}) {
  final entries = transactions.toList();
  final zero = Money.zero(budgetAccount.openingBalance.currencyCode);
  final linkedAccountByCategory = {
    for (final category in categories) category.id: category.linkedAccountId,
  };
  var assigned = zero;
  var remaining = zero;
  for (final plan in plans) {
    if (plan.month != month) continue;
    assigned += plan.assigned;
    remaining += remainingPlanAllocation(
      plan: plan,
      budgetAccountId: budgetAccount.id,
      linkedAccountId: linkedAccountByCategory[plan.categoryId],
      transactions: entries,
    );
  }
  return ReadyToAssign(
    balance: currentBalance(budgetAccount, entries),
    carryOver: currentBalance(
      budgetAccount,
      entries.where(
        (transaction) => transaction.date.isBefore(month.dateRange.start),
      ),
    ),
    assigned: assigned,
    remaining: remaining,
  );
}

/// Unspent allocation reserved in the budget account for this plan. This is
/// shared by Ready to assign and the archive guard so their rules stay equal.
Money remainingPlanAllocation({
  required MonthlyPlan plan,
  required String? budgetAccountId,
  required Iterable<TransactionDraft> transactions,
  String? linkedAccountId,
}) {
  var spent = Money.zero(plan.assigned.currencyCode);
  if (budgetAccountId != null) {
    for (final transaction in transactions) {
      final eligible = linkedAccountId == null
          ? transaction.type == TransactionType.spending &&
                transaction.categoryId == plan.categoryId
          : (transaction.type == TransactionType.transfer ||
                    transaction.type == TransactionType.creditCardPayment) &&
                transaction.destinationAccountId == linkedAccountId;
      if (eligible &&
          transaction.sourceAccountId == budgetAccountId &&
          plan.month.dateRange.contains(transaction.date)) {
        spent += transaction.amount;
      }
    }
  }
  final remaining = plan.assigned - spent;
  return remaining.isNegative
      ? Money.zero(plan.assigned.currencyCode)
      : remaining;
}
