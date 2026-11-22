import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_month.dart';

/// One spending category's target and assigned amount in one month.
///
/// Each month stands alone: nothing carries over between months.
@immutable
final class MonthlyPlan {
  const MonthlyPlan({
    required this.id,
    required this.month,
    required this.categoryId,
    required this.target,
    required this.assigned,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final CalendarMonth month;
  final String categoryId;

  /// The budget for the month: zero or positive, or `null` for no target.
  /// A zero target differs from having none.
  final Money? target;

  /// Money set aside for the category this month: zero or positive. Entered
  /// by the user; it is not checked against income or balances.
  final Money assigned;

  /// UTC instants.
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is MonthlyPlan &&
      other.id == id &&
      other.month == month &&
      other.categoryId == categoryId &&
      other.target == target &&
      other.assigned == assigned &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    month,
    categoryId,
    target,
    assigned,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'MonthlyPlan($id, $month, category $categoryId, target: $target, '
      'assigned: $assigned)';
}
