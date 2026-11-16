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

void main() {
  final november = DateRange.monthOf(CalendarDate(2026, 11, 16));

  Account withOpening(int id, int openingMinor) =>
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
    saved(inflow(amount: 3000000), id: 1), // +30,000 to BDO
    saved(spending(amount: 50000), id: 2), // -500 from BDO
    saved(spending(from: rcbcCardId, amount: 120000), id: 3), // card +1,200
    saved(transfer(amount: 200000), id: 4), // BDO -> wallet, not counted
    saved(cardPayment(amount: 300000), id: 5), // not counted
    saved(spending(amount: 7000, date: october), id: 6), // other month
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
          currentPeriodProvider.overrideWithValue(november),
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
    expect(find.text('₱41,430.00'), findsOneWidget);
    // Card: owed 3,000 + 1,200 - 3,000 paid = 1,200.
    expect(find.text('₱1,200.00'), findsOneWidget);
    expect(find.text('₱50,000.00'), findsOneWidget);
  });

  testWidgets('shows this month\'s inflow and spending (rule 5)', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Nov 1, 2026 – Nov 30, 2026'), findsOneWidget);
    expect(find.text('+₱30,000.00'), findsOneWidget);
    // 500 + 1,200 card purchase; transfer, card payment and October excluded.
    expect(find.text('-₱1,700.00'), findsOneWidget);
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
          currentPeriodProvider.overrideWithValue(november),
        ],
        child: const MaterialApp(home: SpendingScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('₱0.00'), findsNWidgets(3));
    expect(find.text('+₱0.00'), findsOneWidget);
    expect(find.text('-₱0.00'), findsOneWidget);
  });

  group('formatOwed', () {
    test('owed amounts are plain; overpaid is labelled', () {
      expect(formatOwed(php(120000)), '₱1,200.00');
      expect(formatOwed(php(0)), '₱0.00');
      expect(formatOwed(php(-2500)), 'Overpaid ₱25.00');
    });
  });
}
