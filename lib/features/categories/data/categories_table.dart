import 'package:drift/drift.dart';

import '../../accounts/data/accounts_table.dart';
import '../domain/category.dart';

/// SQLite table for [Category]s (added in schema v2; `is_archived` in v4;
/// `plan_group` in v8).
///
/// Names are unique ignoring ASCII case and 1-40 characters long. A category
/// used by a transaction cannot be deleted (the foreign key restricts it).
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();

  /// Stored by enum name (`spending` or `inflow`).
  TextColumn get kind => textEnum<CategoryKind>()();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Hides only the Plans row, independently of category/account archiving.
  BoolColumn get isPlanArchived =>
      boolean().withDefault(const Constant(false))();

  /// Keeps a permanently deleted Plans row from being recreated.
  BoolColumn get isPlanDeleted => boolean()
      .withDefault(const Constant(false))
      // A deleted row must be an archived spending plan. The check refers to
      // this column, as required by drift's CHECK API, without runtime recursion.
      .check(
        // ignore: recursive_getters
        isPlanDeleted.equals(false) |
            (isPlanArchived.equals(true) & kind.equals('spending')),
      )();

  /// The Plans page section, stored by enum name. Inflow categories keep the
  /// default; the repository only lets spending categories change it.
  TextColumn get planGroup => textEnum<PlanGroup>()
      .withDefault(const Constant('spending'))
      // The check refers to the column itself, which is drift's documented
      // way to write a column CHECK; the generated code does not recurse.
      // ignore: recursive_getters
      .check(planGroup.isIn(const ['spending', 'savings', 'liability']))();

  /// Managed Plans row for one liability account; normal categories have none.
  IntColumn get linkedAccountId => integer().nullable().unique().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  List<String> get customConstraints => [
    'CHECK (length(name) BETWEEN 1 AND 40)',
    "CHECK (linked_account_id IS NULL OR (kind = 'spending' AND plan_group = 'liability'))",
    "CHECK (kind IN ('spending', 'inflow'))",
  ];
}
