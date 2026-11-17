import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/date_range.dart';
import 'package:fundly/features/transactions/domain/transaction_filter.dart';
import 'package:fundly/features/transactions/presentation/all_transactions_screen.dart';
import 'package:fundly/features/transactions/presentation/transaction_tile.dart';
import 'package:fundly/features/transactions/presentation/transactions_providers.dart';

import '../../../helpers/provider_overrides.dart';
import '../domain/transaction_fixtures.dart';

void main() {
  final lunch = saved(
    spending(
      from: walletId,
      payee: 'Jollibee',
      date: CalendarDate(2026, 11, 16),
    ),
    id: 4,
  );
  final move = saved(transfer(), id: 3); // BDO -> wallet
  final salary = saved(inflow(), id: 2); // into BDO
  final oldCoffee = saved(
    spending(
      from: oldWalletId,
      payee: 'Coffee',
      date: CalendarDate(2026, 10, 2),
    ),
    id: 1,
  );
  final transactions = [lunch, move, salary, oldCoffee];

  Future<void> pump(WidgetTester tester) async {
    final all = accounts.values.toList();
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeAccounts(
          [
            for (final a in all)
              if (!a.isArchived) a,
          ],
          archived: [
            for (final a in all)
              if (a.isArchived) a,
          ],
          transactions: transactions,
          categories: categories.values.toList(),
        ),
        child: const MaterialApp(home: AllTransactionsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> shownIds(WidgetTester tester) => tester
      .widgetList<TransactionTile>(find.byType(TransactionTile))
      .map((tile) => tile.transaction.id.toString())
      .toList();

  Future<void> pickFromSheet(
    WidgetTester tester,
    String chip,
    String option,
  ) async {
    await tester.tap(find.widgetWithText(InputChip, chip));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(option),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows everything with no filters', (tester) async {
    await pump(tester);

    expect(shownIds(tester), ['4', '3', '2', '1']);
    expect(find.text('Clear all'), findsNothing);
  });

  testWidgets('filters by account, including archived accounts', (
    tester,
  ) async {
    await pump(tester);

    await pickFromSheet(tester, 'All accounts', 'Cash Wallet');
    expect(shownIds(tester), ['4', '3']);

    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    await pickFromSheet(tester, 'All accounts', 'Old Wallet');
    expect(shownIds(tester), ['1']);
  });

  testWidgets('filters by category', (tester) async {
    await pump(tester);

    await pickFromSheet(tester, 'All categories', 'Salary');

    expect(shownIds(tester), ['2']);
    expect(find.widgetWithText(InputChip, 'Salary'), findsOneWidget);
  });

  testWidgets('combines filters and explains when nothing matches', (
    tester,
  ) async {
    await pump(tester);

    await pickFromSheet(tester, 'All accounts', 'BDO Savings');
    await pickFromSheet(tester, 'All categories', 'Food');

    expect(shownIds(tester), isEmpty);
    expect(find.text('No transactions match these filters.'), findsOneWidget);
  });

  testWidgets('a date range filter shows on its chip and applies', (
    tester,
  ) async {
    await pump(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AllTransactionsScreen)),
    );

    container
        .read(transactionFilterProvider(TransactionFilter.none).notifier)
        .set(
          TransactionFilter(
            dateRange: DateRange(
              CalendarDate(2026, 10, 1),
              CalendarDate(2026, 10, 31),
            ),
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text('Oct 1, 2026 – Oct 31, 2026'), findsOneWidget);
    expect(shownIds(tester), ['1']);
  });

  testWidgets('the date chip opens a date range picker', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(InputChip, 'Any date'));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsOneWidget);
  });

  testWidgets('Clear all removes every filter', (tester) async {
    await pump(tester);
    await pickFromSheet(tester, 'All accounts', 'BDO Savings');
    await pickFromSheet(tester, 'All categories', 'Food');

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    expect(shownIds(tester), ['4', '3', '2', '1']);
    expect(find.text('All accounts'), findsOneWidget);
    expect(find.text('All categories'), findsOneWidget);
  });
}
