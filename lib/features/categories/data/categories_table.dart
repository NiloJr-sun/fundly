import 'package:drift/drift.dart';

import '../domain/category.dart';

/// SQLite table for [Category]s (added in schema v2; `is_archived` in v4).
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

  @override
  List<String> get customConstraints => [
    'CHECK (length(name) BETWEEN 1 AND 40)',
    "CHECK (kind IN ('spending', 'inflow'))",
  ];
}
