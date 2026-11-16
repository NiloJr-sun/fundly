import 'package:drift/drift.dart';

import '../domain/category.dart';

/// The fixed categories seeded into every database (CLAUDE.md §11, G1).
///
/// Order matters: categories are listed in insertion order, so "Other" stays
/// last within spending.
const List<({String name, CategoryKind kind})> defaultCategories = [
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

/// Inserts [defaultCategories].
///
/// Uses plain SQL with explicit columns rather than the generated table class,
/// so this keeps working inside old migration steps after later schema
/// versions add columns to `categories`.
Future<void> seedDefaultCategories(DatabaseConnectionUser database) async {
  for (final category in defaultCategories) {
    await database.customStatement(
      'INSERT INTO categories (name, kind) VALUES (?, ?)',
      [category.name, category.kind.name],
    );
  }
}
