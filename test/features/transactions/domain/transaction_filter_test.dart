import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/date_range.dart';
import 'package:fundly/features/transactions/domain/transaction_filter.dart';

import 'transaction_fixtures.dart';

void main() {
  // 1: BDO spending (Food) on Nov 1.
  // 2: BDO -> wallet transfer on Nov 16 (no category).
  // 3: inflow to the card (Salary) on Nov 16.
  // 4: wallet spending (Food) on Oct 31.
  final all = [
    saved(spending(date: CalendarDate(2026, 11, 1)), id: 1),
    saved(transfer(), id: 2),
    saved(inflow(to: rcbcCardId, category: salaryId), id: 3),
    saved(spending(from: walletId, date: CalendarDate(2026, 10, 31)), id: 4),
  ];

  List<int> ids(TransactionFilter filter) =>
      filter.apply(all).map((t) => t.id).toList();

  test('no filter keeps everything in order', () {
    expect(TransactionFilter.none.isEmpty, isTrue);
    expect(ids(TransactionFilter.none), [1, 2, 3, 4]);
  });

  group('date range', () {
    test('is inclusive at both ends', () {
      final filter = TransactionFilter(
        dateRange: DateRange(
          CalendarDate(2026, 11, 1),
          CalendarDate(2026, 11, 16),
        ),
      );

      expect(ids(filter), [1, 2, 3]);
    });

    test('excludes dates outside', () {
      final filter = TransactionFilter(
        dateRange: DateRange(
          CalendarDate(2026, 10, 1),
          CalendarDate(2026, 10, 31),
        ),
      );

      expect(ids(filter), [4]);
    });
  });

  group('account', () {
    test('matches the source account', () {
      expect(ids(const TransactionFilter(accountId: bdoId)), [1, 2]);
    });

    test('matches the destination account', () {
      expect(ids(const TransactionFilter(accountId: walletId)), [2, 4]);
      expect(ids(const TransactionFilter(accountId: rcbcCardId)), [3]);
    });
  });

  group('category', () {
    test('keeps only that category', () {
      expect(ids(const TransactionFilter(categoryId: foodId)), [1, 4]);
      expect(ids(const TransactionFilter(categoryId: salaryId)), [3]);
    });

    test('never matches transfers, which have no category', () {
      expect(
        ids(const TransactionFilter(categoryId: foodId)),
        isNot(contains(2)),
      );
    });
  });

  test('combined filters must all match', () {
    final filter = TransactionFilter(
      dateRange: DateRange(
        CalendarDate(2026, 11, 1),
        CalendarDate(2026, 11, 30),
      ),
      accountId: bdoId,
      categoryId: foodId,
    );

    expect(ids(filter), [1]);
  });

  test('with... replaces or clears one field and keeps the rest', () {
    final range = DateRange(
      CalendarDate(2026, 11, 1),
      CalendarDate(2026, 11, 2),
    );
    final filter = TransactionFilter(
      dateRange: range,
      accountId: bdoId,
      categoryId: foodId,
    );

    expect(
      filter.withAccount(null),
      TransactionFilter(dateRange: range, categoryId: foodId),
    );
    expect(
      filter.withDateRange(null).withCategory(null),
      const TransactionFilter(accountId: bdoId),
    );
    expect(
      filter.withDateRange(null).withAccount(null).withCategory(null).isEmpty,
      isTrue,
    );
  });
}
