import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../../core/time/calendar_month.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_balance.dart';
import '../../accounts/domain/account_type.dart';
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
/// month. Assignments do not carry over between months; a month without its
/// own plan uses the category's default Target. A credit card's row also
/// holds what card purchases moved to it ([movedIn]) and what is still unpaid
/// from earlier months ([carriedOver]); see [cardRowFunding].
@immutable
final class CategoryPlanSummary {
  const CategoryPlanSummary({
    required this.category,
    required this.target,
    required this.assigned,
    required this.activity,
    required this.hasPlan,
    this.carriedOver,
    this.movedIn,
  });

  final Category category;

  /// The month's budget: its own plan's Target, or the category's default
  /// Target when the month has no plan; `null` when neither sets one.
  final Money? target;

  /// Money set aside this month; zero when nothing is assigned.
  final Money assigned;

  /// Spending (card purchases included), or payments into a linked
  /// liability, dated in the month.
  final Money activity;

  /// Card rows only: money moved in during earlier months and not yet paid.
  /// `null` on other rows.
  final Money? carriedOver;

  /// Card rows only: the covered part of this month's card purchases, moved
  /// from their categories. `null` on other rows.
  final Money? movedIn;

  /// Whether a plan is saved for this month (a target, an assigned amount,
  /// or both).
  final bool hasPlan;

  /// `assigned - activity`, plus [carriedOver] and [movedIn] on a card row;
  /// negative when more was spent (or paid) than it holds.
  Money get available {
    var total = assigned - activity;
    if (carriedOver case final carried?) total += carried;
    if (movedIn case final moved?) total += moved;
    return total;
  }

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
      other.hasPlan == hasPlan &&
      other.carriedOver == carriedOver &&
      other.movedIn == movedIn;

  @override
  int get hashCode => Object.hash(
    category,
    target,
    assigned,
    activity,
    hasPlan,
    carriedOver,
    movedIn,
  );

  @override
  String toString() =>
      'CategoryPlanSummary(${category.name}, target: $target, '
      'assigned: $assigned, activity: $activity)';
}

/// One row per spending category for [month], in the order of [categories].
///
/// - Regular category Activity counts Spending, card purchases included.
///   Linked liability rows count transfers and card payments into their
///   account. Neither changes spending/inflow totals.
/// - A Credit account's row (custom credit types included) also gets
///   [CategoryPlanSummary.carriedOver] and [CategoryPlanSummary.movedIn] from
///   [cardRowFunding]. [plans] may hold every month: earlier months decide
///   what card purchases moved and what is still unpaid.
/// - Main rows exclude archived plans and categories. With [archived], all
///   archived spending rows are returned, including those without history.
/// - Inflow categories never appear: plans are for spending only.
/// - Plans for other months in [plans] are ignored.
/// - A month with its own plan uses that plan's Target, even when it has
///   none; a month without one uses the category's default Target.
List<CategoryPlanSummary> planSummaries({
  required CalendarMonth month,
  required Iterable<Category> categories,
  required Iterable<MonthlyPlan> plans,
  required Iterable<TransactionDraft> transactions,
  required Iterable<Account> accounts,
  String currencyCode = Account.defaultCurrency,
  bool archived = false,
}) {
  final funding = cardRowFunding(
    month: month,
    categories: categories,
    plans: plans,
    transactions: transactions,
    accounts: accounts,
    currencyCode: currencyCode,
  );
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
          target: planByCategory.containsKey(category.id)
              ? planByCategory[category.id]!.target
              : category.defaultTarget,
          assigned:
              planByCategory[category.id]?.assigned ?? Money.zero(currencyCode),
          activity: activityByCategory[category.id] ?? Money.zero(currencyCode),
          hasPlan: planByCategory.containsKey(category.id),
          carriedOver: switch (funding[category.linkedAccountId]) {
            final row? => row.carriedOver,
            null => null,
          },
          movedIn: switch (funding[category.linkedAccountId]) {
            final row? => row.movedIn,
            null => null,
          },
        ),
  ];
}

/// Credit accounts, custom credit types included (they store the base type):
/// their purchases move covered money to the card's Plans row.
Set<String> creditAccountIds(Iterable<Account> accounts) => {
  for (final account in accounts)
    if (account.type == AccountType.credit) account.id,
};

/// Debt rows count payments to the linked account; regular rows count
/// Spending, card purchases included. Payments remain excluded from spending
/// totals throughout the app.
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

/// What a credit card's Plans row holds in one month from card purchases.
@immutable
final class CardRowFunding {
  const CardRowFunding({required this.carriedOver, required this.movedIn});

  /// Moved in during earlier months and not yet paid.
  final Money carriedOver;

  /// Moved in this month.
  final Money movedIn;

  @override
  bool operator ==(Object other) =>
      other is CardRowFunding &&
      other.carriedOver == carriedOver &&
      other.movedIn == movedIn;

  @override
  int get hashCode => Object.hash(carriedOver, movedIn);

  @override
  String toString() =>
      'CardRowFunding(carriedOver: $carriedOver, movedIn: $movedIn)';
}

/// Per Credit account in [accounts] (custom credit types included), what its
/// Plans row holds in [month] from card purchases, as YNAB does:
///
/// - A card purchase in a spending category moves the part the category
///   could cover to the card's row: the category's Available just before the
///   purchase, never below zero. The rest is debt with no money behind it,
///   and the category shows overspent.
/// - Within a month each category's Spending (cash and card) is taken by
///   date, then by when it was recorded, starting from that month's Assigned
///   as it is now. Purchases without a category move nothing.
/// - Payments into the card (card payments and transfers) use moved money
///   first. What is left unpaid at a month's end carries to the next month,
///   never below zero. Assigned does not carry over.
///
/// [plans] should hold every month up to [month], and [transactions] the
/// whole history: earlier months decide what is carried over. Every card is
/// in the result, with zeros when nothing was moved.
Map<String, CardRowFunding> cardRowFunding({
  required CalendarMonth month,
  required Iterable<Category> categories,
  required Iterable<MonthlyPlan> plans,
  required Iterable<TransactionDraft> transactions,
  required Iterable<Account> accounts,
  String currencyCode = Account.defaultCurrency,
}) {
  final zero = Money.zero(currencyCode);
  final cards = creditAccountIds(accounts);
  if (cards.isEmpty) return const {};
  final regularCategories = {
    for (final category in categories)
      if (category.kind == CategoryKind.spending &&
          category.linkedAccountId == null)
        category.id,
  };
  final assigned = {
    for (final plan in plans) (plan.month, plan.categoryId): plan.assigned,
  };

  final spendingByMonth = <CalendarMonth, List<TransactionDraft>>{};
  final paymentsByMonth = <CalendarMonth, Map<String, Money>>{};
  CalendarMonth? first;
  for (final transaction in _chronological(transactions)) {
    final transactionMonth = CalendarMonth.of(transaction.date);
    if (transactionMonth.compareTo(month) > 0) continue;
    final source = transaction.sourceAccountId;
    final destination = transaction.destinationAccountId;
    final bool startsHistory;
    if (transaction.type == TransactionType.spending &&
        regularCategories.contains(transaction.categoryId)) {
      (spendingByMonth[transactionMonth] ??= []).add(transaction);
      startsHistory = cards.contains(source);
    } else if ((transaction.type == TransactionType.transfer ||
            transaction.type == TransactionType.creditCardPayment) &&
        cards.contains(destination)) {
      final payments = paymentsByMonth[transactionMonth] ??= {};
      payments[destination!] =
          (payments[destination] ?? zero) + transaction.amount;
      startsHistory = true;
    } else {
      startsHistory = false;
    }
    if (startsHistory &&
        (first == null || transactionMonth.compareTo(first) < 0)) {
      first = transactionMonth;
    }
  }

  var carried = <String, Money>{};
  if (first != null) {
    for (var current = first; ; current = current.next) {
      final movedIn = _movedToCards(
        spendingByMonth[current] ?? const [],
        current,
        assigned,
        cards,
        zero,
      );
      if (current == month) {
        return {
          for (final card in cards)
            card: CardRowFunding(
              carriedOver: carried[card] ?? zero,
              movedIn: movedIn[card] ?? zero,
            ),
        };
      }
      final payments = paymentsByMonth[current] ?? const {};
      carried = {
        for (final card in cards)
          if ((carried[card] ?? zero) +
                  (movedIn[card] ?? zero) -
                  (payments[card] ?? zero)
              case final unpaid when unpaid.minorUnits > 0)
            card: unpaid,
      };
    }
  }
  return {
    for (final card in cards)
      card: CardRowFunding(carriedOver: zero, movedIn: zero),
  };
}

/// The covered part of [spending]'s card purchases in [month], per card.
/// [spending] is that month's Spending in regular categories, in order.
Map<String, Money> _movedToCards(
  List<TransactionDraft> spending,
  CalendarMonth month,
  Map<(CalendarMonth, String), Money> assigned,
  Set<String> cards,
  Money zero,
) {
  final availableByCategory = <String, Money>{};
  final moved = <String, Money>{};
  for (final transaction in spending) {
    final categoryId = transaction.categoryId!;
    final available =
        availableByCategory[categoryId] ??
        assigned[(month, categoryId)] ??
        zero;
    final card = transaction.sourceAccountId;
    if (card != null && cards.contains(card) && available.minorUnits > 0) {
      final covered = available.minorUnits < transaction.amount.minorUnits
          ? available
          : transaction.amount;
      moved[card] = (moved[card] ?? zero) + covered;
    }
    availableByCategory[categoryId] = available - transaction.amount;
  }
  return moved;
}

/// [transactions] oldest first: by date, then by when they were recorded
/// (when known), then in the order given.
List<TransactionDraft> _chronological(Iterable<TransactionDraft> transactions) {
  final indexed = transactions.indexed.toList()
    ..sort((a, b) {
      final byDate = a.$2.date.compareTo(b.$2.date);
      if (byDate != 0) return byDate;
      if ((a.$2, b.$2) case (
        final Transaction first,
        final Transaction second,
      )) {
        final byCreation = first.createdAt.compareTo(second.createdAt);
        if (byCreation != 0) return byCreation;
      }
      return a.$1.compareTo(b.$1);
    });
  return [for (final (_, transaction) in indexed) transaction];
}

/// The selected month's money in the budget accounts and what is assigned.
@immutable
final class ReadyToAssign {
  const ReadyToAssign({
    required this.carryOver,
    required this.moneyIn,
    required this.movedOut,
    required this.assigned,
    required this.heldForCards,
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

  /// Card purchases' covered money from earlier months, not yet paid
  /// ([CardRowFunding.carriedOver] on every card row). It is still in
  /// [carryOver] but already promised to the cards.
  final Money heldForCards;

  /// Money that came in and has not been given a job yet.
  Money get amount => carryOver + moneyIn - movedOut - heldForCards - assigned;

  @override
  bool operator ==(Object other) =>
      other is ReadyToAssign &&
      other.carryOver == carryOver &&
      other.moneyIn == moneyIn &&
      other.movedOut == movedOut &&
      other.assigned == assigned &&
      other.heldForCards == heldForCards;

  @override
  int get hashCode =>
      Object.hash(carryOver, moneyIn, movedOut, assigned, heldForCards);
}

/// Carry over plus money in, minus money moved out, money held for cards and
/// the month's assigned total, across all [budgetAccounts]. Each month has
/// its own figure. [plans] may hold every month; held for cards comes from
/// [cardRowFunding] over [accounts] (all accounts), for card rows that are
/// not permanently deleted.
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
  required Iterable<Account> accounts,
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
  final funding = cardRowFunding(
    month: month,
    categories: categories,
    plans: plans,
    transactions: transactions,
    accounts: accounts,
    currencyCode: currencyCode,
  );
  var heldForCards = zero;
  for (final category in categories) {
    final row = funding[category.linkedAccountId];
    if (row != null && !category.isPlanDeleted) {
      heldForCards += row.carriedOver;
    }
  }
  return ReadyToAssign(
    carryOver: carryOver,
    moneyIn: moneyIn,
    movedOut: movedOut,
    assigned: assigned,
    heldForCards: heldForCards,
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
