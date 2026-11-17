import 'package:flutter/foundation.dart' show immutable;

import '../../../core/money/money.dart';
import '../../../core/time/calendar_month.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction.dart';
import 'monthly_plan.dart';

/// Planned versus actual spending for one category in one month.
@immutable
final class CategoryPlanSummary {
  const CategoryPlanSummary({
    required this.category,
    required this.planned,
    required this.actual,
  });

  final Category category;

  /// `null` when the category has no plan this month.
  final Money? planned;

  /// Spending dated in the month with this category. Zero or positive.
  final Money actual;

  /// `planned - actual`; negative when overspent. `null` without a plan.
  Money? get remaining {
    final planned = this.planned;
    return planned == null ? null : planned - actual;
  }

  bool get isOverspent => remaining?.isNegative ?? false;

  @override
  bool operator ==(Object other) =>
      other is CategoryPlanSummary &&
      other.category == category &&
      other.planned == planned &&
      other.actual == actual;

  @override
  int get hashCode => Object.hash(category, planned, actual);

  @override
  String toString() =>
      'CategoryPlanSummary(${category.name}, planned: $planned, '
      'actual: $actual)';
}

/// One row per spending category for [month], in the order of [categories].
///
/// - Actual counts only Spending transactions dated in the month (rule 5):
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
  final plannedByCategory = {
    for (final plan in plans)
      if (plan.month == month) plan.categoryId: plan.target,
  };

  final range = month.dateRange;
  final actualByCategory = <int, Money>{};
  for (final transaction in transactions) {
    final categoryId = transaction.categoryId;
    if (!transaction.type.countsAsSpending ||
        categoryId == null ||
        !range.contains(transaction.date)) {
      continue;
    }
    actualByCategory[categoryId] =
        (actualByCategory[categoryId] ?? Money.zero(currencyCode)) +
        transaction.amount;
  }

  return [
    for (final category in categories)
      if (category.kind == CategoryKind.spending &&
          (!category.isArchived ||
              plannedByCategory.containsKey(category.id) ||
              actualByCategory.containsKey(category.id)))
        CategoryPlanSummary(
          category: category,
          planned: plannedByCategory[category.id],
          actual: actualByCategory[category.id] ?? Money.zero(currencyCode),
        ),
  ];
}
