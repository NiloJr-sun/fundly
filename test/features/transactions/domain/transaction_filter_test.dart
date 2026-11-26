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
    saved(spending(date: CalendarDate(2026, 11, 1)), id: '1'),
    saved(transfer(), id: '2'),
    saved(
      inflow(to: rcbcCardId, category: salaryId),
      id: '3',
    ),
    saved(
      spending(from: walletId, date: CalendarDate(2026, 10, 31)),
      id: '4',
    ),
  ];

  List<String> ids(TransactionFilter filter) =>
      filter.apply(all).map((t) => t.id).toList();

  test('no filter keeps everything in order', () {
    expect(TransactionFilter.none.isEmpty, isTrue);
    expect(ids(TransactionFilter.none), ['1', '2', '3', '4']);
  });

  group('date range', () {
    test('is inclusive at both ends', () {
      final filter = TransactionFilter(
        dateRange: DateRange(
          CalendarDate(2026, 11, 1),
          CalendarDate(2026, 11, 16),
        ),
      );

      expect(ids(filter), ['1', '2', '3']);
    });

    test('excludes dates outside', () {
      final filter = TransactionFilter(
        dateRange: DateRange(
          CalendarDate(2026, 10, 1),
          CalendarDate(2026, 10, 31),
        ),
      );

      expect(ids(filter), ['4']);
    });
  });

  group('account', () {
    test('matches the source account', () {
      expect(ids(const TransactionFilter(accountId: bdoId)), ['1', '2']);
    });

    test('matches the destination account', () {
      expect(ids(const TransactionFilter(accountId: walletId)), ['2', '4']);
      expect(ids(const TransactionFilter(accountId: rcbcCardId)), ['3']);
    });
  });

  group('category', () {
    test('keeps only that category', () {
      expect(ids(const TransactionFilter(categoryId: foodId)), ['1', '4']);
      expect(ids(const TransactionFilter(categoryId: salaryId)), ['3']);
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

    expect(ids(filter), ['1']);
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

  group('type', () {
    // a: cash spending, b: card purchase (no category), c: inflow,
    // d: transfer, e: loan payment, f: card payment, g: cash advance.
    final mixed = [
      saved(spending(), id: 'a'),
      saved(spending(from: rcbcCardId, category: null), id: 'b'),
      saved(inflow(), id: 'c'),
      saved(transfer(), id: 'd'),
      saved(transfer(to: carLoanId), id: 'e'),
      saved(cardPayment(), id: 'f'),
      saved(
        transfer(from: rcbcCardId, to: walletId),
        id: 'g',
      ),
    ];
    final accountTypes = {
      for (final account in accounts.values) account.id: account.type,
    };

    List<String> typeIds(Set<TransactionTypeFilter> types) => TransactionFilter
        .none
        .withTypes(types)
        .apply(mixed, accountTypes: accountTypes)
        .map((t) => t.id)
        .toList();

    test('Spending includes card purchases', () {
      expect(typeIds({TransactionTypeFilter.spending}), ['a', 'b']);
    });

    test('Card purchases are Spending from a Credit account', () {
      expect(typeIds({TransactionTypeFilter.cardPurchase}), ['b']);
    });

    test('Inflow', () {
      expect(typeIds({TransactionTypeFilter.inflow}), ['c']);
    });

    test('Transfer excludes loan payments and includes cash advances', () {
      expect(typeIds({TransactionTypeFilter.transfer}), ['d', 'g']);
    });

    test('Loan payment is a Transfer into a Loan account', () {
      expect(typeIds({TransactionTypeFilter.loanPayment}), ['e']);
    });

    test('Credit card payment', () {
      expect(typeIds({TransactionTypeFilter.cardPayment}), ['f']);
    });

    test('several types match any of them', () {
      expect(
        typeIds({TransactionTypeFilter.spending, TransactionTypeFilter.inflow}),
        ['a', 'b', 'c'],
      );
    });

    test('no types means any type', () {
      expect(typeIds({}), ['a', 'b', 'c', 'd', 'e', 'f', 'g']);
    });

    test(
      'without account types, no card purchase or loan payment is known',
      () {
        final filter = TransactionFilter.none.withTypes({
          TransactionTypeFilter.cardPurchase,
          TransactionTypeFilter.loanPayment,
        });
        expect(filter.apply(mixed), isEmpty);
        expect(
          TransactionFilter.none
              .withTypes({TransactionTypeFilter.transfer})
              .apply(mixed)
              .map((t) => t.id),
          ['d', 'e', 'g'],
        );
      },
    );

    test('combines with the account filter', () {
      final filter = TransactionFilter.none
          .withTypes({TransactionTypeFilter.spending})
          .withAccount(rcbcCardId);
      expect(filter.apply(mixed, accountTypes: accountTypes).map((t) => t.id), [
        'b',
      ]);
    });

    test('equal regardless of order; withTypes empty clears it', () {
      final a = TransactionFilter.none.withTypes({
        TransactionTypeFilter.inflow,
        TransactionTypeFilter.spending,
      });
      final b = TransactionFilter.none.withTypes({
        TransactionTypeFilter.spending,
        TransactionTypeFilter.inflow,
      });
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.isEmpty, isFalse);
      expect(a.withTypes(const {}).isEmpty, isTrue);
    });
  });

  group('no category', () {
    final mixed = [
      saved(spending(), id: 'a'),
      saved(spending(from: rcbcCardId, category: null), id: 'b'),
      saved(inflow(category: null), id: 'c'),
      saved(transfer(), id: 'd'),
      saved(cardPayment(), id: 'e'),
    ];

    test('keeps only Spending and Inflow without a category', () {
      final filter = TransactionFilter.none.withUncategorized(true);
      expect(filter.isEmpty, isFalse);
      expect(filter.apply(mixed).map((t) => t.id), ['b', 'c']);
    });

    test('replaces a category, and a category replaces it', () {
      final withCategory = TransactionFilter.none.withCategory(foodId);
      expect(
        withCategory.withUncategorized(true),
        const TransactionFilter(uncategorized: true),
      );
      expect(
        withCategory.withUncategorized(true).withCategory(foodId),
        const TransactionFilter(categoryId: foodId),
      );
    });

    test('clears the debt payments filter, which it could never match', () {
      const payments = TransactionFilter(paymentAccountId: rcbcCardId);
      expect(
        payments.withUncategorized(true),
        const TransactionFilter(uncategorized: true),
      );
    });
  });
}
