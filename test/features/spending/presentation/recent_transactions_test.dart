import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/theme/app_colors.dart';
import 'package:fundly/app/theme/app_palette.dart';
import 'package:fundly/core/database/record_id.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/date_range.dart';
import 'package:fundly/features/spending/presentation/recent_transactions.dart';
import 'package:fundly/features/spending/presentation/spending_providers.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';
import 'package:fundly/features/transactions/presentation/all_transactions_screen.dart';
import 'package:fundly/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:fundly/features/transactions/presentation/transaction_tile.dart';

import '../../../helpers/provider_overrides.dart';
import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  /// [count] spendings, newest first (as the repository returns them), with
  /// payees "Shop 1" (oldest) to "Shop [count]" (newest).
  List<Transaction> newestFirst(int count) => [
    for (var i = count; i >= 1; i--)
      saved(
        spending(payee: 'Shop $i', date: CalendarDate(2026, 11, i)),
        id: recordIdOf(i),
      ),
  ];

  Future<void> pump(WidgetTester tester, List<Transaction> transactions) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(CalendarDate(2026, 11, 16)),
          ...fakeAccounts(
            accounts.values.toList(),
            transactions: transactions,
            categories: categories.values.toList(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: RecentTransactions()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String?> shownPayees(WidgetTester tester) => tester
      .widgetList<TransactionTile>(find.byType(TransactionTile))
      .map((tile) => tile.transaction.payee)
      .toList();

  testWidgets('shows the newest $recentTransactionCount, newest first', (
    tester,
  ) async {
    await pump(tester, newestFirst(12));

    expect(shownPayees(tester), [for (var i = 12; i >= 3; i--) 'Shop $i']);
  });

  testWidgets('shows all when there are fewer than the limit', (tester) async {
    await pump(tester, newestFirst(3));

    expect(shownPayees(tester), ['Shop 3', 'Shop 2', 'Shop 1']);
  });

  testWidgets('See all opens the full list', (tester) async {
    await pump(tester, newestFirst(12));

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(find.byType(AllTransactionsScreen), findsOneWidget);
  });

  testWidgets('tapping a transaction opens its details', (tester) async {
    await pump(tester, newestFirst(2));

    await tester.tap(find.text('Shop 2'));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionDetailScreen), findsOneWidget);
  });

  testWidgets('hints at Add transaction when empty', (tester) async {
    await pump(tester, const []);

    expect(
      find.text('No transactions yet. Tap "Add transaction" to record one.'),
      findsOneWidget,
    );
  });

  group('limited to the selected period', () {
    /// Newest first: two in November, three in October, one in September.
    final mixed = [
      for (final (id, date) in [
        (6, CalendarDate(2026, 11, 10)),
        (5, CalendarDate(2026, 11, 1)),
        (4, CalendarDate(2026, 10, 31)),
        (3, CalendarDate(2026, 10, 15)),
        (2, CalendarDate(2026, 10, 1)),
        (1, CalendarDate(2026, 9, 30)),
      ])
        saved(
          spending(payee: 'Shop $id', date: date),
          id: recordIdOf(id),
        ),
    ];

    SelectedPeriodNotifier period(WidgetTester tester) =>
        ProviderScope.containerOf(
          tester.element(find.byType(RecentTransactions)),
        ).read(selectedPeriodProvider.notifier);

    testWidgets('This month shows the newest overall', (tester) async {
      await pump(tester, mixed);

      expect(find.text('Recent transactions'), findsOneWidget);
      expect(shownPayees(tester), [for (var i = 6; i >= 1; i--) 'Shop $i']);
    });

    testWidgets('Last month shows only that month', (tester) async {
      await pump(tester, mixed);

      period(tester).selectLastMonth();
      await tester.pumpAndSettle();

      expect(find.text('Transactions in October 2026'), findsOneWidget);
      expect(shownPayees(tester), ['Shop 4', 'Shop 3', 'Shop 2']);
    });

    testWidgets('a custom range shows only that range, both ends included', (
      tester,
    ) async {
      await pump(tester, mixed);

      period(tester).selectCustom(
        DateRange(CalendarDate(2026, 10, 15), CalendarDate(2026, 11, 1)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Transactions: Oct 15, 2026 – Nov 1, 2026'),
        findsOneWidget,
      );
      expect(shownPayees(tester), ['Shop 5', 'Shop 4', 'Shop 3']);
    });

    testWidgets('still shows at most $recentTransactionCount', (tester) async {
      await pump(tester, newestFirst(12));

      period(tester).selectCustom(
        DateRange(CalendarDate(2026, 11, 1), CalendarDate(2026, 11, 30)),
      );
      await tester.pumpAndSettle();

      expect(shownPayees(tester), [for (var i = 12; i >= 3; i--) 'Shop $i']);
    });

    testWidgets('says when the period has no transactions', (tester) async {
      await pump(tester, newestFirst(3));

      period(tester).selectLastMonth();
      await tester.pumpAndSettle();

      expect(find.byType(TransactionTile), findsNothing);
      expect(find.text('No transactions in this period.'), findsOneWidget);
    });

    testWidgets('See all opens the list filtered to the period', (
      tester,
    ) async {
      await pump(tester, mixed);
      period(tester).selectLastMonth();
      await tester.pumpAndSettle();

      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();

      expect(find.text('Oct 1, 2026 – Oct 31, 2026'), findsOneWidget);
      expect(shownPayees(tester), ['Shop 4', 'Shop 3', 'Shop 2']);
    });

    testWidgets('See all for This month opens unfiltered', (tester) async {
      await pump(tester, mixed);

      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();

      expect(find.text('Any date'), findsOneWidget);
      expect(shownPayees(tester), hasLength(6));
    });
  });

  testWidgets('amounts are colour-coded: spending red, inflow green, '
      'transfers and card payments neutral (rule 5)', (tester) async {
    await pump(tester, [
      saved(spending(date: CalendarDate(2026, 11, 4)), id: recordIdOf(1)),
      saved(inflow(), id: recordIdOf(2)),
      saved(transfer(), id: recordIdOf(3)),
      saved(cardPayment(), id: recordIdOf(4)),
    ]);

    final money = AppColors.fromShade(AppPalette.fallback.light);
    Color? amountColor(TransactionType type) {
      final tile = find.byWidgetPredicate(
        (widget) =>
            widget is TransactionTile && widget.transaction.type == type,
      );
      final listTile = tester.widget<ListTile>(
        find.descendant(of: tile, matching: find.byType(ListTile)),
      );
      return (listTile.trailing! as Text).style?.color;
    }

    expect(amountColor(TransactionType.spending), money.expense);
    expect(amountColor(TransactionType.inflow), money.positive);
    final neutral = Theme.of(tester.element(find.byType(RecentTransactions)))
        .textTheme
        .bodyLarge
        ?.color;
    expect(amountColor(TransactionType.transfer), neutral);
    expect(amountColor(TransactionType.creditCardPayment), neutral);
  });
}
