import 'package:drift/drift.dart';

import '../domain/category.dart';

/// SQLite table for [Category]s (added in schema v2).
///
/// Names are unique ignoring ASCII case and 1-40 characters long.
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();

  /// Stored by enum name (`spending` or `inflow`).
  TextColumn get kind => textEnum<CategoryKind>()();

  @override
  List<String> get customConstraints => [
    'CHECK (length(name) BETWEEN 1 AND 40)',
    "CHECK (kind IN ('spending', 'inflow'))",
  ];
}
