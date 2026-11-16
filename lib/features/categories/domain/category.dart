import 'package:flutter/foundation.dart';

/// Whether a category classifies spending or inflows.
enum CategoryKind { spending, inflow }

/// A category that transactions can be assigned to.
///
/// Phase 2 uses a fixed, seeded list (CLAUDE.md §11, G1). Managing
/// categories arrives in Phase 4.
@immutable
final class Category {
  const Category({required this.id, required this.name, required this.kind});

  final int id;
  final String name;
  final CategoryKind kind;

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(id, name, kind);

  @override
  String toString() => 'Category($id, "$name", ${kind.name})';
}
