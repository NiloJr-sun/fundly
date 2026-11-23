import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../../core/time/calendar_month.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_balance.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import 'monthly_plan.dart';

/// A plan row's status: overspending first, otherwise whether assigned money
/// covers the target.
enum PlanStatus {
  /// Assigned is at least the target.
  funded,

  /// Assigned is below the target.
  underfunded,

  /// Activity exceeds assigned, so Available is negative.
  overspent,
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

  /// Whether assigned covers the target; `null` without a target. Spending
  /// does not change it.
  bool? get isFunded {
    final target = this.target;
    if (target == null) return null;
    return assigned.minorUnits >= target.minorUnits;
  }

  /// [PlanStatus.overspent] whenever [available] is negative, with or without
  /// a target. Otherwise [PlanStatus.funded] or [PlanStatus.underfunded] from
  /// [isFunded], and `null` without a target.
  PlanStatus? get status => isOverspent
      ? PlanStatus.overspent
      : switch (isFunded) {
          true => PlanStatus.funded,
          false => PlanStatus.underfunded,
          null => null,
        };

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

/// The selected month's money in the budget accounts and what is assigned.
@immutable
final class ReadyToAssign {
  const ReadyToAssign({
    required this.carryOver,
    required this.moneyIn,
    required this.movedOut,
    required this.assigned,
  });

  /// Total budget-account balance on the month's first day: opening balances
  /// plus every transaction dated before it.
  final Money carryOver;

  /// Inflows into budget accounts, and transfers into them from other
  /// accounts, dated in the month.
  final Money moneyIn;

  /// Transfers from budget accounts to other accounts without a linked Plans
  /// row (Savings/Cash), dated in the month. Card and loan payments are
  /// Activity on their debt row instead; transfers between budget accounts
  /// are neither money in nor moved out.
  final Money movedOut;

  /// Total assigned in the month, including archived plan rows.
  final Money assigned;

  /// Money that came in and has not been given a job yet.
  Money get amount => carryOver + moneyIn - movedOut - assigned;

  @override
  bool operator ==(Object other) =>
      other is ReadyToAssign &&
      other.carryOver == carryOver &&
      other.moneyIn == moneyIn &&
      other.movedOut == movedOut &&
      other.assigned == assigned;

  @override
  int get hashCode => Object.hash(carryOver, moneyIn, movedOut, assigned);
}

/// Carry over plus money in, minus money moved out and the month's assigned
/// total, across all [budgetAccounts]. Each month has its own figure.
///
/// Spending from a budget account does not change it: spending is Activity
/// in its category, which turns negative when overspent. Card and loan
/// payments (transfers or card payments into an account linked to a Plans row
/// in [categories]) are likewise Activity on that row. Spending from other
/// accounts and card purchases never touch it. Earlier months' spending still
/// reaches later months through [ReadyToAssign.carryOver].
ReadyToAssign readyToAssign({
  required CalendarMonth month,
  required Iterable<Account> budgetAccounts,
  required Iterable<MonthlyPlan> plans,
  required Iterable<TransactionDraft> transactions,
  required Iterable<Category> categories,
  String currencyCode = Account.defaultCurrency,
}) {
  final budgets = budgetAccounts.toList();
  final budgetIds = {for (final account in budgets) account.id};
  final zero = Money.zero(currencyCode);
  final linkedAccountIds = {
    for (final category in categories)
      if (category.linkedAccountId != null) category.linkedAccountId,
  };
  final before = <TransactionDraft>[];
  var moneyIn = zero;
  var movedOut = zero;
  for (final transaction in transactions) {
    if (transaction.date.isBefore(month.dateRange.start)) {
      before.add(transaction);
      continue;
    }
    if (!month.dateRange.contains(transaction.date)) continue;
    final fromBudget = budgetIds.contains(transaction.sourceAccountId);
    final toBudget = budgetIds.contains(transaction.destinationAccountId);
    if (toBudget && !fromBudget) {
      moneyIn += transaction.amount;
    } else if (fromBudget &&
        !toBudget &&
        transaction.type == TransactionType.transfer &&
        !linkedAccountIds.contains(transaction.destinationAccountId)) {
      movedOut += transaction.amount;
    }
  }
  var carryOver = zero;
  for (final account in budgets) {
    carryOver += currentBalance(account, before);
  }
  var assigned = zero;
  for (final plan in plans) {
    if (plan.month == month) assigned += plan.assigned;
  }
  return ReadyToAssign(
    carryOver: carryOver,
    moneyIn: moneyIn,
    movedOut: movedOut,
    assigned: assigned,
  );
}

/// Unspent allocation for this plan: Assigned minus that month's eligible
/// Spending (or linked debt payments) from any budget account, floored at
/// zero. The archive guard uses it to block archiving rows that still hold
/// money.
Money remainingPlanAllocation({
  required MonthlyPlan plan,
  required Set<String> budgetAccountIds,
  required Iterable<TransactionDraft> transactions,
  String? linkedAccountId,
}) {
  var spent = Money.zero(plan.assigned.currencyCode);
  if (budgetAccountIds.isNotEmpty) {
    for (final transaction in transactions) {
      final eligible = linkedAccountId == null
          ? transaction.type == TransactionType.spending &&
                transaction.categoryId == plan.categoryId
          : (transaction.type == TransactionType.transfer ||
                    transaction.type == TransactionType.creditCardPayment) &&
                transaction.destinationAccountId == linkedAccountId;
      if (eligible &&
          budgetAccountIds.contains(transaction.sourceAccountId) &&
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
