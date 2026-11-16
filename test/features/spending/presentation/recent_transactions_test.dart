import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/features/spending/presentation/recent_transactions.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
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
        id: i,
      ),
  ];

  Future<void> pump(WidgetTester tester, List<Transaction> transactions) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeAccounts(
          accounts.values.toList(),
          transactions: transactions,
          categories: categories.values.toList(),
        ),
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
}
