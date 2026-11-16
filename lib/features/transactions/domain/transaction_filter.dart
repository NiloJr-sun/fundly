import 'package:flutter/foundation.dart';

import '../../../core/time/date_range.dart';
import 'transaction.dart';

/// Optional filters for a transaction list. A `null` field means "any".
/// All set fields must match.
@immutable
final class TransactionFilter {
  const TransactionFilter({this.dateRange, this.accountId, this.categoryId});

  static const TransactionFilter none = TransactionFilter();

  /// Inclusive range of transaction dates.
  final DateRange? dateRange;

  /// Matches transactions where this account is the source or destination.
  final int? accountId;

  /// Matches transactions in this category. Transfers and card payments have
  /// no category, so they never match a category filter.
  final int? categoryId;

  bool get isEmpty =>
      dateRange == null && accountId == null && categoryId == null;

  bool matches(TransactionDraft transaction) {
    final range = dateRange;
    if (range != null && !range.contains(transaction.date)) return false;
    final account = accountId;
    if (account != null &&
        transaction.sourceAccountId != account &&
        transaction.destinationAccountId != account) {
      return false;
    }
    final category = categoryId;
    if (category != null && transaction.categoryId != category) return false;
    return true;
  }

  /// Keeps the matching [transactions], preserving their order.
  List<T> apply<T extends TransactionDraft>(Iterable<T> transactions) =>
      transactions.where(matches).toList();

  TransactionFilter withDateRange(DateRange? value) => TransactionFilter(
    dateRange: value,
    accountId: accountId,
    categoryId: categoryId,
  );

  TransactionFilter withAccount(int? value) => TransactionFilter(
    dateRange: dateRange,
    accountId: value,
    categoryId: categoryId,
  );

  TransactionFilter withCategory(int? value) => TransactionFilter(
    dateRange: dateRange,
    accountId: accountId,
    categoryId: value,
  );

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.dateRange == dateRange &&
      other.accountId == accountId &&
      other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(dateRange, accountId, categoryId);

  @override
  String toString() =>
      'TransactionFilter(dates: $dateRange, account: $accountId, '
      'category: $categoryId)';
}
