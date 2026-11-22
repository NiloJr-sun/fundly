import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/date_range.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/spending/presentation/spending_providers.dart';
import 'package:fundly/features/spending/presentation/spending_screen.dart';
import 'package:fundly/features/spending/presentation/summary_cards.dart';

import '../../../helpers/provider_overrides.dart';
import '../../transactions/domain/transaction_fixtures.dart';

/// Finds [text] inside a summary card, ignoring the recent transactions list.
Finder inCard(String text) =>
    find.descendant(of: find.byType(Card), matching: find.text(text));

void main() {
  Account withOpening(String id, int openingMinor) =>
      accounts[id]!.copyWith(openingBalance: php(openingMinor));

  final active = [
    withOpening(bdoId, 1500000), // 15,000
    withOpening(walletId, 0),
    withOpening(rcbcCardId, -300000), // owes 3,000
    withOpening(carLoanId, -5000000), // owes 50,000
  ];
  final archived = [withOpening(oldWalletId, 99900)];

  final october = CalendarDate(2026, 10, 20);
  final transactions = [
    saved(inflow(amount: 3000000), id: '1'), // +30,000 to BDO
    saved(spending(amount: 50000), id: '2'), // -500 from BDO
    saved(spending(from: rcbcCardId, amount: 120000), id: '3'), // card +1,200
    saved(transfer(amount: 200000), id: '4'), // BDO -> wallet, not counted
    saved(cardPayment(amount: 300000), id: '5'), // not counted
    saved(spending(amount: 7000, date: october), id: '6'), // other month
  ];

  Future<void> pump(
    WidgetTester tester, {
    List<Override> extra = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeAccounts(
            active,
            archived: archived,
            transactions: transactions,
          ),
          todayProvider.overrideWithValue(CalendarDate(2026, 11, 16)),
          ...extra,
        ],
        retry: (_, _) => null,
        child: const MaterialApp(home: SpendingScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows available money and amounts owed (D2)', (tester) async {
    await pump(tester);

    // BDO: 15,000 + 30,000 - 500 - 2,000 - 3,000 - 70 = 39,430.
    // Wallet: +2,000. Archived Old Wallet excluded.
    expect(find.text('Available money'), findsOneWidget);
    expect(inCard('₱41,430.00'), findsOneWidget);
    // Card: owed 3,000 + 1,200 - 3,000 paid = 1,200.
    expect(inCard('₱1,200.00'), findsOneWidget);
    expect(inCard('₱50,000.00'), findsOneWidget);
  });

  testWidgets('shows this month\'s inflow and spending (rule 5)', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('This month'), findsNWidgets(2), reason: 'title+chip');
    expect(find.text('Nov 1, 2026 – Nov 30, 2026'), findsOneWidget);
    expect(inCard('+₱30,000.00'), findsOneWidget);
    // 500 + 1,200 card purchase; transfer, card payment and October excluded.
    expect(inCard('-₱1,700.00'), findsOneWidget);
  });

  testWidgets('shows placeholders while loading', (tester) async {
    await pump(
      tester,
      extra: [periodTotalsProvider.overrideWithValue(const AsyncLoading())],
    );

    expect(find.text('…'), findsNWidgets(2));
  });

  testWidgets('shows a message when totals fail to load', (tester) async {
    await pump(
      tester,
      extra: [
        periodTotalsProvider.overrideWithValue(
          AsyncError(Exception('disk'), StackTrace.empty),
        ),
      ],
    );

    expect(find.text('Totals could not be loaded.'), findsOneWidget);
  });

  testWidgets('with no accounts, everything is zero', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...noAccounts(),
          todayProvider.overrideWithValue(CalendarDate(2026, 11, 16)),
        ],
        child: const MaterialApp(home: SpendingScreen()),
      ),
    );
    await tester.pump();

    expect(inCard('₱0.00'), findsNWidgets(3));
    expect(inCard('+₱0.00'), findsOneWidget);
    expect(inCard('-₱0.00'), findsOneWidget);
  });

  group('formatOwed', () {
    test('owed amounts are plain; overpaid is labelled', () {
      expect(formatOwed(php(120000)), '₱1,200.00');
      expect(formatOwed(php(0)), '₱0.00');
      expect(formatOwed(php(-2500)), 'Overpaid ₱25.00');
    });
  });

  group('period selector', () {
    Future<void> tapChip(WidgetTester tester, String label) async {
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, label));
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
    }

    testWidgets('starts on this month', (tester) async {
      await pump(tester);

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'This month'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('Last month shows October totals', (tester) async {
      await pump(tester);

      await tapChip(tester, 'Last month');

      expect(find.text('Last month'), findsNWidgets(2), reason: 'title+chip');
      expect(find.text('Oct 1, 2026 – Oct 31, 2026'), findsOneWidget);
      expect(inCard('-₱70.00'), findsOneWidget);
      expect(inCard('+₱0.00'), findsOneWidget);
    });

    testWidgets('This month switches back', (tester) async {
      await pump(tester);
      await tapChip(tester, 'Last month');

      await tapChip(tester, 'This month');

      expect(find.text('Nov 1, 2026 – Nov 30, 2026'), findsOneWidget);
      expect(inCard('-₱1,700.00'), findsOneWidget);
    });

    testWidgets(
      'Custom opens a date range picker; cancelling keeps the period',
      (tester) async {
        await pump(tester);

        await tapChip(tester, 'Custom');
        expect(find.byType(DateRangePickerDialog), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text('Nov 1, 2026 – Nov 30, 2026'), findsOneWidget);
        final chip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'This month'),
        );
        expect(chip.selected, isTrue);
      },
    );

    testWidgets('a custom range filters the totals', (tester) async {
      await pump(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SpendingScreen)),
      );

      container
          .read(selectedPeriodProvider.notifier)
          .selectCustom(DateRange(october, october));
      await tester.pumpAndSettle();

      expect(find.text('Custom range'), findsOneWidget);
      expect(find.text('Oct 20, 2026 – Oct 20, 2026'), findsOneWidget);
      expect(inCard('-₱70.00'), findsOneWidget);
    });
  });
}
