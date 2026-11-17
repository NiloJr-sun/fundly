import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/presentation/plans_screen.dart';
import 'package:fundly/features/spending/presentation/spending_providers.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';

import '../../../helpers/fake_plan_repository.dart';
import '../../../helpers/provider_overrides.dart';
import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  late FakePlanRepository repository;

  setUp(() => repository = FakePlanRepository());

  final november = CalendarMonth(2026, 11);
  final october = CalendarMonth(2026, 10);
  const transportId = 11;
  const transport = Category(
    id: transportId,
    name: 'Transport',
    kind: CategoryKind.spending,
  );
  // Food and Transport are active spending; Salary is inflow; Gifts is
  // archived spending.
  final allCategories = [...categories.values, transport];

  MonthlyPlan plan(int categoryId, int amount, {CalendarMonth? month}) =>
      MonthlyPlan(
        id: categoryId,
        month: month ?? november,
        categoryId: categoryId,
        target: php(amount),
        assigned: php(amount),
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
      );

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Category>? withCategories,
    List<MonthlyPlan> plans = const [],
    List<Transaction> transactions = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(CalendarDate(2026, 11, 16)),
          ...fakeAccounts(
            accounts.values.toList(),
            categories: withCategories ?? allCategories,
            transactions: transactions,
            plans: plans,
            planRepository: repository,
          ),
        ],
        child: const MaterialApp(home: PlansScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder row(String name) => find.widgetWithText(ListTile, name);

  Finder inRow(String name, String text) =>
      find.descendant(of: row(name), matching: find.text(text));

  group('rows', () {
    testWidgets('one per spending category for the current month', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('November 2026'), findsOneWidget);
      expect(row('Food'), findsOneWidget);
      expect(row('Transport'), findsOneWidget);
      expect(find.text('Salary'), findsNothing);
      expect(find.textContaining('Gifts'), findsNothing);
    });

    testWidgets('shows spent of planned and what is left', (tester) async {
      await pumpScreen(
        tester,
        plans: [plan(foodId, 500000)],
        transactions: [saved(spending(amount: 120000))],
      );

      expect(inRow('Food', 'Spent ₱1,200.00 of ₱5,000.00'), findsOneWidget);
      expect(inRow('Food', '₱3,800.00 left'), findsOneWidget);
    });

    testWidgets('shows overspending', (tester) async {
      await pumpScreen(
        tester,
        plans: [plan(foodId, 100000)],
        transactions: [saved(spending(amount: 125000))],
      );

      expect(inRow('Food', '₱250.00 over'), findsOneWidget);
    });

    testWidgets('a category without a plan offers to set one', (tester) async {
      await pumpScreen(tester, transactions: [saved(spending(amount: 8000))]);

      expect(inRow('Food', 'Spent ₱80.00 · No plan'), findsOneWidget);
      expect(inRow('Food', 'Set plan'), findsOneWidget);
    });

    testWidgets('transfers and card payments do not count as spent', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        plans: [plan(foodId, 500000)],
        transactions: [
          saved(spending(amount: 100000), id: 1),
          saved(transfer(), id: 2),
          saved(cardPayment(), id: 3),
        ],
      );

      expect(inRow('Food', 'Spent ₱1,000.00 of ₱5,000.00'), findsOneWidget);
    });

    testWidgets('an archived category with spending is shown, read-only', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        transactions: [saved(spending(amount: 5000, category: giftsId))],
      );

      expect(row('Gifts (archived)'), findsOneWidget);
      expect(inRow('Gifts (archived)', 'Set plan'), findsNothing);

      await tester.tap(row('Gifts (archived)'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('shows an empty state without spending categories', (
      tester,
    ) async {
      await pumpScreen(tester, withCategories: [categories[salaryId]!]);

      expect(
        find.textContaining('No spending categories yet.'),
        findsOneWidget,
      );
    });
  });

  group('month selector', () {
    testWidgets('moves between months and back to this month', (tester) async {
      await pumpScreen(
        tester,
        plans: [
          plan(foodId, 500000),
          plan(foodId, 300000, month: october),
        ],
      );
      expect(find.text('This month'), findsNothing);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);
      expect(inRow('Food', 'Spent ₱0.00 of ₱3,000.00'), findsOneWidget);

      await tester.tap(find.text('This month'));
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);
      expect(inRow('Food', 'Spent ₱0.00 of ₱5,000.00'), findsOneWidget);
    });

    testWidgets('next month crosses the year', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();

      expect(find.text('January 2027'), findsOneWidget);
    });
  });

  group('editing the planned amount', () {
    Future<void> openDialog(WidgetTester tester, String name) async {
      await tester.tap(row(name));
      await tester.pumpAndSettle();
    }

    Finder amountField() => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );

    testWidgets('sets a plan for the shown month', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      await openDialog(tester, 'Food');
      expect(find.text('Planned for October 2026'), findsOneWidget);
      expect(find.text('Clear plan'), findsNothing);
      await tester.enterText(amountField(), '4,500.50');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.saved.single, (
        month: october,
        categoryId: foodId,
        target: php(450050),
        assigned: php(450050),
      ));
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('zero is a valid plan', (tester) async {
      await pumpScreen(tester);

      await openDialog(tester, 'Food');
      await tester.enterText(amountField(), '0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.saved.single.target, php(0));
    });

    testWidgets('pre-fills the current plan and can clear it', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)]);

      await openDialog(tester, 'Food');
      expect(find.text('5000.00'), findsOneWidget);
      await tester.tap(find.text('Clear plan'));
      await tester.pumpAndSettle();

      expect(repository.cleared.single, (month: november, categoryId: foodId));
      expect(repository.saved, isEmpty);
    });

    testWidgets('rejects invalid amounts and saves nothing', (tester) async {
      await pumpScreen(tester);
      await openDialog(tester, 'Food');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter an amount.'), findsOneWidget);

      await tester.enterText(amountField(), '-5');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter the amount without a minus sign.'),
        findsOneWidget,
      );

      expect(repository.saved, isEmpty);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('cancel saves nothing', (tester) async {
      await pumpScreen(tester);
      await openDialog(tester, 'Food');

      await tester.enterText(amountField(), '100');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.saved, isEmpty);
      expect(repository.cleared, isEmpty);
    });

    testWidgets('an archived category keeps an editable plan', (tester) async {
      await pumpScreen(tester, plans: [plan(giftsId, 200000)]);

      await openDialog(tester, 'Gifts (archived)');

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
