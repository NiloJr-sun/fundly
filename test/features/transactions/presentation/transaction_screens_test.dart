import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/features/accounts/presentation/account_detail_screen.dart';
import 'package:fundly/features/spending/presentation/spending_screen.dart';
import 'package:fundly/features/transactions/presentation/all_transactions_screen.dart';
import 'package:fundly/features/transactions/presentation/transaction_detail_screen.dart';

import '../../../helpers/provider_overrides.dart';
import '../domain/transaction_fixtures.dart';

void main() {
  final allAccounts = accounts.values.toList();
  final active = [
    for (final a in allAccounts)
      if (!a.isArchived) a,
  ];
  final archived = [
    for (final a in allAccounts)
      if (a.isArchived) a,
  ];

  // Newest first, as the repository returns them.
  final lunch = saved(
    spending(
      from: walletId,
      amount: 15000,
      payee: 'Jollibee',
      date: CalendarDate(2026, 11, 16),
      note: 'Team lunch',
    ),
    id: 3,
  );
  final move = saved(transfer(amount: 200000), id: 2);
  final salary = saved(inflow(amount: 3000000), id: 1);
  final transactions = [lunch, move, salary];

  List<Override> overrides() => fakeAccounts(
    active,
    archived: archived,
    transactions: transactions,
    categories: categories.values.toList(),
  );

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('All transactions', () {
    testWidgets('lists every transaction, newest first', (tester) async {
      await pump(tester, const AllTransactionsScreen());

      final titles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => (tile.title! as Text).data)
          .toList();
      expect(titles, ['Jollibee', 'Transfer', 'Employer']);
    });

    testWidgets('shows amounts, categories and accounts', (tester) async {
      await pump(tester, const AllTransactionsScreen());

      expect(find.text('-₱150.00'), findsOneWidget);
      expect(find.text('₱2,000.00'), findsOneWidget);
      expect(find.text('+₱30,000.00'), findsOneWidget);
      expect(find.text('Nov 16, 2026 · Food · Cash Wallet'), findsOneWidget);
      expect(
        find.text('Nov 16, 2026 · BDO Savings → Cash Wallet'),
        findsOneWidget,
      );
      expect(find.text('Nov 16, 2026 · Salary · BDO Savings'), findsOneWidget);
    });

    testWidgets('shows an empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: noAccounts(),
          child: const MaterialApp(home: AllTransactionsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No transactions yet.'), findsOneWidget);
    });

    testWidgets('opens from the Spending tab', (tester) async {
      await pump(tester, const SpendingScreen());

      await tester.tap(find.byTooltip('All transactions'));
      await tester.pumpAndSettle();

      expect(find.byType(AllTransactionsScreen), findsOneWidget);
    });

    testWidgets('tapping a transaction opens its details', (tester) async {
      await pump(tester, const AllTransactionsScreen());

      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionDetailScreen), findsOneWidget);
    });
  });

  group('Account details', () {
    testWidgets("lists the account's transactions with its signs", (
      tester,
    ) async {
      await pump(tester, const AccountDetailScreen(accountId: walletId));

      // Wallet: +2,000 transfer in, -150 lunch. Salary went to BDO.
      expect(find.text('Jollibee'), findsOneWidget);
      expect(find.text('-₱150.00'), findsOneWidget);
      expect(find.text('+₱2,000.00'), findsOneWidget);
      expect(find.text('Employer'), findsNothing);
      expect(find.text('₱1,850.00'), findsOneWidget, reason: 'balance');
    });

    testWidgets('a transfer is negative on the source account', (tester) async {
      await pump(tester, const AccountDetailScreen(accountId: bdoId));

      expect(find.text('-₱2,000.00'), findsOneWidget);
      expect(find.text('+₱30,000.00'), findsOneWidget);
    });

    testWidgets('says when an account has no transactions', (tester) async {
      await pump(tester, const AccountDetailScreen(accountId: carLoanId));

      expect(find.text('No transactions yet.'), findsOneWidget);
    });
  });

  group('Transaction details', () {
    testWidgets('shows the full trail of a spending', (tester) async {
      await pump(tester, const TransactionDetailScreen(transactionId: 3));

      expect(find.text('Spending'), findsOneWidget);
      expect(find.text('₱150.00'), findsOneWidget);
      expect(find.text('Nov 16, 2026'), findsWidgets);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('Cash Wallet'), findsOneWidget);
      expect(find.text('To'), findsNothing);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Jollibee'), findsOneWidget);
      expect(find.text('Team lunch'), findsOneWidget);
      expect(find.text('Recorded'), findsOneWidget);
      expect(find.text('Last edited'), findsNothing);
    });

    testWidgets('shows both accounts of a transfer', (tester) async {
      await pump(tester, const TransactionDetailScreen(transactionId: 2));

      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('BDO Savings'), findsOneWidget);
      expect(find.text('Cash Wallet'), findsOneWidget);
      expect(find.text('Category'), findsNothing);
    });

    testWidgets('marks an archived account', (tester) async {
      final fromOld = saved(spending(from: oldWalletId), id: 9);
      await tester.pumpWidget(
        ProviderScope(
          overrides: fakeAccounts(
            active,
            archived: archived,
            transactions: [fromOld],
          ),
          child: const MaterialApp(
            home: TransactionDetailScreen(transactionId: 9),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Old Wallet (archived)'), findsOneWidget);
    });

    testWidgets('shows when it was last edited', (tester) async {
      final edited = saved(
        transfer(),
        id: 5,
        createdAt: DateTime.utc(2026, 11, 1, 12),
        updatedAt: DateTime.utc(2026, 11, 10, 12),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: fakeAccounts(active, transactions: [edited]),
          child: const MaterialApp(
            home: TransactionDetailScreen(transactionId: 5),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nov 1, 2026'), findsOneWidget);
      expect(find.text('Last edited'), findsOneWidget);
      expect(find.text('Nov 10, 2026'), findsOneWidget);
    });

    testWidgets('says when the transaction does not exist', (tester) async {
      await pump(tester, const TransactionDetailScreen(transactionId: 404));

      expect(find.text('This transaction no longer exists.'), findsOneWidget);
    });
  });
}
