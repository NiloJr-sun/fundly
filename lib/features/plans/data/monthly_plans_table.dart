import 'package:drift/drift.dart';

import '../../../core/database/calendar_month_converter.dart';
import '../../categories/data/categories_table.dart';

/// SQLite table for monthly plans (added in schema v5; target and assigned
/// amounts since v6): one spending category's optional target and assigned
/// amount in one month.
///
/// The database enforces one plan per category per month, zero or positive
/// amounts and a well-formed month. Rules that need other tables (spending
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

  /// The budget for the month: zero or positive minor units (centavos for
  /// PHP), or `NULL` when the category has no target. Named
  /// `planned_amount_minor` before v6.
  IntColumn get targetAmountMinor => integer().nullable()();

  /// Money set aside for the category this month, in minor units. Zero or
  /// positive; entered by the user and not checked against income.
  IntColumn get assignedAmountMinor => integer()();

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
    'CHECK (target_amount_minor IS NULL OR target_amount_minor >= 0)',
    'CHECK (assigned_amount_minor >= 0)',
    "CHECK (month GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'"
        " AND substr(month, 6, 2) BETWEEN '01' AND '12')",
  ];
}
