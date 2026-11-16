import 'package:flutter/foundation.dart';

/// Whether a category classifies spending or inflows.
enum CategoryKind { spending, inflow }

/// A category that transactions can be assigned to.
///
/// The app starts with a seeded list (CLAUDE.md §11, G1); users can add,
/// rename, archive and delete categories (task 4.1). The kind never changes
/// after creation.
@immutable
final class Category {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    this.isArchived = false,
  });

  final int id;
  final String name;
  final CategoryKind kind;

  /// Archived categories keep their history but cannot be picked for new
  /// transactions.
  final bool isArchived;

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.isArchived == isArchived;

  @override
  int get hashCode => Object.hash(id, name, kind, isArchived);

  @override
  String toString() =>
      'Category($id, "$name", ${kind.name}${isArchived ? ', archived' : ''})';
}
