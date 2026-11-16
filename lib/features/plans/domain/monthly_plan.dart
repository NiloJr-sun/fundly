import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_month.dart';

/// How much the user plans to spend in one spending category in one month.
///
/// Each month stands alone: nothing carries over between months.
@immutable
final class MonthlyPlan {
  const MonthlyPlan({
    required this.id,
    required this.month,
    required this.categoryId,
    required this.plannedAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final CalendarMonth month;
  final int categoryId;

  /// Zero or positive. Zero means "plan to spend nothing", which differs
  /// from having no plan at all.
  final Money plannedAmount;

  /// UTC instants.
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is MonthlyPlan &&
      other.id == id &&
      other.month == month &&
      other.categoryId == categoryId &&
      other.plannedAmount == plannedAmount &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, month, categoryId, plannedAmount, createdAt, updatedAt);

  @override
  String toString() =>
      'MonthlyPlan($id, $month, category $categoryId, $plannedAmount)';
}
