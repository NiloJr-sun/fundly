import 'package:drift/drift.dart';

import '../domain/category.dart';

/// Historical v2 seed list. Keep unchanged so old migration steps and
/// category IDs retain their original meaning.
const List<({String name, CategoryKind kind})> legacyDefaultCategories = [
  (name: 'Food', kind: CategoryKind.spending),
  (name: 'Transport', kind: CategoryKind.spending),
  (name: 'Utilities', kind: CategoryKind.spending),
  (name: 'Subscriptions', kind: CategoryKind.spending),
  (name: 'Shopping', kind: CategoryKind.spending),
  (name: 'Health', kind: CategoryKind.spending),
  (name: 'Other', kind: CategoryKind.spending),
  (name: 'Salary', kind: CategoryKind.inflow),
  (name: 'Other income', kind: CategoryKind.inflow),
];

/// Inserts [legacyDefaultCategories] during historical migrations.
///
/// Uses plain SQL with explicit columns rather than the generated table class,
/// so this keeps working inside old migration steps after later schema
/// versions add columns to `categories`.
Future<void> seedDefaultCategories(DatabaseConnectionUser database) async {
  for (final category in legacyDefaultCategories) {
    await database.customStatement(
      'INSERT INTO categories (name, kind) VALUES (?, ?)',
      [category.name, category.kind.name],
    );
  }
}

/// Defaults for new databases. Historical migration seeds stay unchanged.
const List<({String name, CategoryKind kind})> defaultCategories = [
  (name: 'Rent', kind: CategoryKind.spending),
  (name: 'Utilities', kind: CategoryKind.spending),
  (name: 'Internet', kind: CategoryKind.spending),
  (name: 'Subscriptions', kind: CategoryKind.spending),
  (name: 'Food & Groceries', kind: CategoryKind.spending),
  (name: 'Fuel', kind: CategoryKind.spending),
  (name: 'Miscellaneous', kind: CategoryKind.spending),
  (name: 'Salary', kind: CategoryKind.inflow),
  (name: 'Other income', kind: CategoryKind.inflow),
];

/// Adds missing defaults without renaming or replacing existing categories.
Future<void> addCurrentDefaultCategories(
  DatabaseConnectionUser database,
) async {
  for (final category in defaultCategories) {
    await database.customStatement(
      'INSERT OR IGNORE INTO categories (name, kind) VALUES (?, ?)',
      [category.name, category.kind.name],
    );
  }
}
