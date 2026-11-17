import 'package:flutter/foundation.dart';

/// Whether a category classifies spending or inflows.
enum CategoryKind { spending, inflow }

/// The section of the Plans page a spending category is listed under. Only
/// organises the page: plan amounts and activity work the same in every
/// group. Fixed for now; user-defined groups are not supported.
enum PlanGroup { spending, savings, liability }

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
    this.planGroup = PlanGroup.spending,
  });

  final int id;
  final String name;
  final CategoryKind kind;

  /// Archived categories keep their history but cannot be picked for new
  /// transactions.
  final bool isArchived;

  /// Where a spending category appears on the Plans page. Inflow categories
  /// are not planned, so theirs is always [PlanGroup.spending] and unused.
  final PlanGroup planGroup;

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.isArchived == isArchived &&
      other.planGroup == planGroup;

  @override
  int get hashCode => Object.hash(id, name, kind, isArchived, planGroup);

  @override
  String toString() =>
      'Category($id, "$name", ${kind.name}, ${planGroup.name}'
      '${isArchived ? ', archived' : ''})';
}
