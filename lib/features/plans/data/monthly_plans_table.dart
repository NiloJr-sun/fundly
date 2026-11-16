import 'package:drift/drift.dart';

import '../../../core/database/calendar_month_converter.dart';
import '../../categories/data/categories_table.dart';

/// SQLite table for monthly plans (added in schema v5): how much the user
/// plans to spend in one spending category in one month.
///
/// The database enforces one plan per category per month, a zero or positive
/// amount and a well-formed month. Rules that need other tables (spending
/// categories only, no new plans for archived categories) are enforced by
/// `PlanRepository`.
///
/// Deleting a category deletes its plans: plans are budgets, not history,
/// and a category with transactions cannot be deleted at all.
@DataClassName('MonthlyPlanRow')
class MonthlyPlans extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// `YYYY-MM`.
  TextColumn get month => text().map(const CalendarMonthConverter())();

  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();

  /// Zero or positive minor units (centavos for PHP).
  IntColumn get plannedAmountMinor => integer()();

  TextColumn get currencyCode => text()();

  /// UTC instants.
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {month, categoryId},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (planned_amount_minor >= 0)',
    "CHECK (month GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'"
        " AND substr(month, 6, 2) BETWEEN '01' AND '12')",
  ];
}
