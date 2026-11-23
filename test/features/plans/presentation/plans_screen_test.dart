import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/theme/app_colors.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/presentation/plan_row.dart';
import 'package:fundly/features/plans/presentation/plans_screen.dart';
import 'package:fundly/features/spending/presentation/spending_providers.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';
import 'package:fundly/features/transactions/presentation/all_transactions_screen.dart';
import 'package:fundly/features/transactions/presentation/transaction_tile.dart';

import '../../../helpers/fake_plan_repository.dart';
import '../../../helpers/provider_overrides.dart';
import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  late FakePlanRepository repository;

  setUp(() => repository = FakePlanRepository());

  final november = CalendarMonth(2026, 11);
  final october = CalendarMonth(2026, 10);
  const transportId = '11';
  const transport = Category(
    id: transportId,
    name: 'Transport',
    kind: CategoryKind.spending,
  );
  // Food and Transport are active spending; Salary is inflow; Gifts is
  // archived spending.
  final allCategories = [...categories.values, transport];

  /// A plan with [target] (`null` for none) and [assigned], which defaults
  /// to the target.
  MonthlyPlan plan(
    String categoryId,
    int? target, {
    int? assigned,
    CalendarMonth? month,
  }) => MonthlyPlan(
    id: categoryId,
    month: month ?? november,
    categoryId: categoryId,
    target: target == null ? null : php(target),
    assigned: php(assigned ?? target ?? 0),
    createdAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 1),
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Category>? withCategories,
    List<MonthlyPlan> plans = const [],
    List<Transaction> transactions = const [],
    bool bdoIsBudgetAccount = false,
    int? budgetOpeningBalance,
  }) async {
    final bdo = accounts[bdoId]!;
    final withBudget = [
      for (final account in accounts.values)
        if (account.id == bdoId && bdoIsBudgetAccount)
          Account(
            id: bdo.id,
            name: bdo.name,
            type: bdo.type,
            openingBalance: budgetOpeningBalance == null
                ? bdo.openingBalance
                : php(budgetOpeningBalance),
            createdAt: bdo.createdAt,
            isBudgetAccount: true,
          )
        else
          account,
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(CalendarDate(2026, 11, 16)),
          ...fakeAccounts(
            withBudget,
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

  Finder row(String name) => find.widgetWithText(PlanRow, name);

  Finder inRow(String name, String text) =>
      find.descendant(of: row(name), matching: find.text(text));

  /// The value under [label] in [name]'s row, e.g. Target or Available.
  String amount(WidgetTester tester, String name, String label) {
    final column = find
        .ancestor(of: inRow(name, label), matching: find.byType(Column))
        .first;
    final texts = tester
        .widgetList<Text>(
          find.descendant(of: column, matching: find.byType(Text)),
        )
        .map((text) => text.data)
        .where((data) => data != label);
    return texts.single!;
  }

  ({String target, String assigned, String activity, String available}) amounts(
    WidgetTester tester,
    String name,
  ) => (
    target: amount(tester, name, 'Target'),
    assigned: amount(tester, name, 'Assigned'),
    activity: amount(tester, name, 'Activity'),
    available: amount(tester, name, 'Available'),
  );

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

    testWidgets('only the Spending section when nothing is grouped', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Spending'), findsOneWidget);
      expect(find.text('Savings'), findsNothing);
      expect(find.text('Liability'), findsNothing);
    });

    testWidgets('sections follow the groups: Spending, Savings, Liability', (
      tester,
    ) async {
      // Tall enough for every section; the list builds only visible rows.
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpScreen(
        tester,
        withCategories: [
          ...allCategories,
          const Category(
            id: '40',
            name: 'Emergency fund',
            kind: CategoryKind.spending,
            planGroup: PlanGroup.savings,
          ),
          const Category(
            id: '41',
            name: 'Card payoff',
            kind: CategoryKind.spending,
            planGroup: PlanGroup.liability,
          ),
        ],
      );

      double top(Finder finder) => tester.getTopLeft(finder).dy;
      expect(top(find.text('Spending')), lessThan(top(row('Food'))));
      expect(top(row('Transport')), lessThan(top(find.text('Savings'))));
      expect(top(find.text('Savings')), lessThan(top(row('Emergency fund'))));
      expect(top(row('Emergency fund')), lessThan(top(find.text('Liability'))));
      expect(top(find.text('Liability')), lessThan(top(row('Card payoff'))));
    });

    testWidgets('groups start expanded and collapse independently', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpScreen(
        tester,
        withCategories: [
          ...allCategories,
          const Category(
            id: '40',
            name: 'Emergency fund',
            kind: CategoryKind.spending,
            planGroup: PlanGroup.savings,
          ),
          const Category(
            id: '41',
            name: 'Card payoff',
            kind: CategoryKind.spending,
            planGroup: PlanGroup.liability,
          ),
        ],
      );
      expect(row('Food'), findsOneWidget);
      expect(row('Emergency fund'), findsOneWidget);
      expect(row('Card payoff'), findsOneWidget);
      await tester.tap(find.text('Spending'));
      await tester.pumpAndSettle();
      expect(row('Food'), findsNothing);
      expect(row('Transport'), findsNothing);
      expect(row('Emergency fund'), findsOneWidget);
      expect(row('Card payoff'), findsOneWidget);
      expect(find.text('Ready to assign'), findsOneWidget);
      await tester.tap(find.text('Savings'));
      await tester.pumpAndSettle();
      expect(row('Emergency fund'), findsNothing);
      expect(row('Card payoff'), findsOneWidget);
      await tester.tap(find.text('Liability'));
      await tester.pumpAndSettle();
      expect(row('Card payoff'), findsNothing);
      await tester.tap(find.text('Spending'));
      await tester.pumpAndSettle();
      expect(row('Food'), findsOneWidget);
      expect(row('Transport'), findsOneWidget);
      expect(row('Emergency fund'), findsNothing);
    });

    testWidgets('a collapsed section stays collapsed when switching months', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        plans: [
          plan(foodId, 100000),
          plan(foodId, 200000, month: october),
        ],
      );
      await tester.tap(find.text('Spending'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
      expect(row('Food'), findsNothing);
      await tester.tap(find.text('Spending'));
      await tester.pumpAndSettle();
      expect(amount(tester, 'Food', 'Target'), '₱2,000.00');
    });

    testWidgets('a section with only Savings categories hides Spending', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        withCategories: const [
          Category(
            id: '40',
            name: 'Emergency fund',
            kind: CategoryKind.spending,
            planGroup: PlanGroup.savings,
          ),
        ],
      );

      expect(find.text('Savings'), findsOneWidget);
      expect(find.text('Spending'), findsNothing);
    });

    testWidgets('shows target, assigned, activity, available and status', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        plans: [plan(foodId, 500000, assigned: 250000)],
        transactions: [saved(spending(amount: 120000))],
      );

      expect(amounts(tester, 'Food'), (
        target: '₱5,000.00',
        assigned: '₱2,500.00',
        activity: '₱1,200.00',
        available: '₱1,300.00',
      ));
      expect(inRow('Food', 'Underfunded'), findsOneWidget);
    });

    testWidgets('funded when assigned covers the target', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)]);

      expect(inRow('Food', 'Funded'), findsOneWidget);
    });

    testWidgets('no target: displays zero and no status', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, null, assigned: 100000)]);

      expect(amount(tester, 'Food', 'Target'), '₱0.00');
      expect(amount(tester, 'Food', 'Available'), '₱1,000.00');
      expect(inRow('Food', 'Funded'), findsNothing);
      expect(inRow('Food', 'Underfunded'), findsNothing);
    });

    testWidgets('spending with nothing assigned shows a red available', (
      tester,
    ) async {
      await pumpScreen(tester, transactions: [saved(spending(amount: 8000))]);

      expect(amounts(tester, 'Food'), (
        target: '₱0.00',
        assigned: '₱0.00',
        activity: '₱80.00',
        available: '-₱80.00',
      ));
      final available = tester.widget<Text>(inRow('Food', '-₱80.00'));
      final context = tester.element(row('Food'));
      expect(available.style?.color, Theme.of(context).colorScheme.error);
    });

    testWidgets('transfers and card payments are not activity', (tester) async {
      await pumpScreen(
        tester,
        plans: [plan(foodId, 500000)],
        transactions: [
          saved(spending(amount: 100000), id: '1'),
          saved(transfer(), id: '2'),
          saved(cardPayment(), id: '3'),
        ],
      );

      expect(amount(tester, 'Food', 'Activity'), '₱1,000.00');
    });

    testWidgets('an archived category with spending moves to the archive', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        transactions: [saved(spending(amount: 5000, category: giftsId))],
      );

      expect(row('Gifts (archived)'), findsNothing);
      await tester.tap(find.byTooltip('Archived plans'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gifts'));
      await tester.pumpAndSettle();
      expect(row('Gifts (archived)'), findsOneWidget);
      await tester.tap(find.text('Gifts (archived)'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('large amounts fit a narrow phone without overflow', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(375, 812)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpScreen(
        tester,
        plans: [plan(foodId, 99999999999, assigned: 1)],
        transactions: [saved(spending(amount: 99999999999))],
      );

      expect(tester.takeException(), isNull);
      expect(inRow('Food', 'Underfunded'), findsOneWidget);
    });

    testWidgets('shows an empty state without spending categories', (
      tester,
    ) async {
      await pumpScreen(tester, withCategories: [categories[salaryId]!]);

      expect(find.textContaining('No active plans.'), findsOneWidget);
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
      expect(amount(tester, 'Food', 'Target'), '₱3,000.00');

      await tester.tap(find.text('This month'));
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);
      expect(amount(tester, 'Food', 'Target'), '₱5,000.00');
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

  group('activity', () {
    testWidgets("opens that category's transactions for the month", (
      tester,
    ) async {
      await pumpScreen(
        tester,
        transactions: [
          saved(spending(amount: 8000, payee: 'Jollibee'), id: '1'),
          saved(
            spending(
              amount: 9000,
              payee: 'Last month',
              date: CalendarDate(2026, 10, 31),
            ),
            id: '2',
          ),
          saved(
            spending(amount: 7000, payee: 'Grab', category: transportId),
            id: '3',
          ),
        ],
      );

      await tester.tap(find.byTooltip('Show Food transactions'));
      await tester.pumpAndSettle();

      expect(find.byType(AllTransactionsScreen), findsOneWidget);
      expect(find.text('Nov 1, 2026 – Nov 30, 2026'), findsOneWidget);
      expect(
        tester
            .widgetList<TransactionTile>(find.byType(TransactionTile))
            .map((tile) => tile.transaction.payee),
        ['Jollibee'],
      );
    });
  });

  group('Ready to assign', () {
    Finder card() => find.ancestor(
      of: find.text('Ready to assign'),
      matching: find.byType(ListTile),
    );

    Text amountText(WidgetTester tester) => tester.widget<Text>(
      find.descendant(of: card(), matching: find.textContaining('₱')).last,
    );

    TransactionDraft transferToWallet(int amount) => TransactionDraft(
      type: TransactionType.transfer,
      amount: php(amount),
      date: CalendarDate(2026, 11, 16),
      sourceAccountId: bdoId,
      destinationAccountId: walletId,
    );

    testWidgets('without a budget account, says how to choose one', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        transactions: [saved(inflow(amount: 4000000), id: '1')],
      );

      expect(
        find.text(
          "Choose a budget account in the Account tab to see what's ready "
          'to assign.',
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card(), matching: find.textContaining('₱')),
        findsNothing,
      );
      final tile = tester.widget<ListTile>(card());
      expect(tile.onTap, isNull);
    });

    testWidgets('shows money in minus moved out and assigned, in green', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        bdoIsBudgetAccount: true,
        plans: [plan(foodId, 500000), plan(transportId, null, assigned: 0)],
        transactions: [
          saved(inflow(amount: 4000000), id: '1'),
          // Transfers out to Savings/Cash are moved out.
          saved(transferToWallet(500000), id: '2'),
        ],
      );

      expect(
        find.descendant(
          of: card(),
          matching: find.text(
            'Carry over from last month: ₱0.00'
            '\nMoney in this month: ₱40,000.00'
            '\nMoved out this month: ₱5,000.00'
            '\nAssigned: ₱5,000.00',
          ),
        ),
        findsOneWidget,
      );
      final amount = amountText(tester);
      expect(amount.data, '₱30,000.00');
      final context = tester.element(card());
      expect(amount.style?.color, AppColors.of(context).positive);
      expect(
        tester.getTopLeft(card()).dy,
        lessThan(tester.getTopLeft(find.text('Spending')).dy),
      );
    });

    testWidgets('opening balance is available without incoming transactions', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        bdoIsBudgetAccount: true,
        budgetOpeningBalance: 1000000,
        plans: [plan(foodId, 400000)],
      );
      expect(amountText(tester).data, '₱6,000.00');
      expect(
        find.textContaining('Carry over from last month: ₱10,000.00'),
        findsOneWidget,
      );
    });

    testWidgets('spending does not change it', (tester) async {
      await pumpScreen(
        tester,
        bdoIsBudgetAccount: true,
        plans: [plan(foodId, 400000)],
        transactions: [
          saved(inflow(amount: 1000000), id: '1'),
          saved(spending(amount: 100000), id: '2'),
          saved(spending(amount: 200000, from: rcbcCardId), id: '3'),
        ],
      );
      expect(amountText(tester).data, '₱6,000.00');
      expect(
        find.textContaining('Money in this month: ₱10,000.00'),
        findsOneWidget,
      );
      expect(find.textContaining('Moved out'), findsNothing);
    });

    testWidgets('is red when more was assigned than came in', (tester) async {
      await pumpScreen(
        tester,
        bdoIsBudgetAccount: true,
        plans: [plan(foodId, 500000)],
      );

      final amount = amountText(tester);
      expect(amount.data, '-₱5,000.00');
      expect(
        find.textContaining('Overallocated by: ₱5,000.00'),
        findsOneWidget,
      );
      final context = tester.element(card());
      expect(amount.style?.color, Theme.of(context).colorScheme.error);
    });

    testWidgets('zero uses the default colour', (tester) async {
      await pumpScreen(tester, bdoIsBudgetAccount: true);

      final amount = amountText(tester);
      expect(amount.data, '₱0.00');
      final context = tester.element(card());
      expect(
        amount.style?.color,
        Theme.of(context).textTheme.titleLarge?.color,
      );
    });

    testWidgets('follows the selected month', (tester) async {
      await pumpScreen(
        tester,
        bdoIsBudgetAccount: true,
        plans: [plan(foodId, 100000, month: october)],
        transactions: [saved(inflow(amount: 4000000), id: '1')],
      );

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      // October has no money in, so its ₱1,000 assignment is overallocated.
      expect(amountText(tester).data, '-₱1,000.00');
    });

    testWidgets("tapping it opens the budget account's month", (tester) async {
      await pumpScreen(
        tester,
        bdoIsBudgetAccount: true,
        transactions: [saved(inflow(amount: 4000000), id: '1')],
      );

      await tester.tap(find.text('Ready to assign'));
      await tester.pumpAndSettle();

      expect(find.byType(AllTransactionsScreen), findsOneWidget);
      expect(find.text('Nov 1, 2026 – Nov 30, 2026'), findsOneWidget);
      expect(find.textContaining('BDO Savings'), findsWidgets);
    });
  });

  group('editing the plan', () {
    Future<void> openDialog(WidgetTester tester, String name) async {
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }

    Finder field(String label) => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextFormField, label),
    );

    testWidgets('saves target and assigned for the shown month', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      await openDialog(tester, 'Food');
      expect(find.text('October 2026'), findsNWidgets(2));
      expect(find.text('Clear plan'), findsNothing);
      await tester.enterText(field('Target'), '5,000');
      await tester.enterText(field('Assigned'), '2,500.50');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.saved.single, (
        month: october,
        categoryId: foodId,
        target: php(500000),
        assigned: php(250050),
      ));
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('an empty target means none; empty assigned is zero', (
      tester,
    ) async {
      await pumpScreen(tester);

      await openDialog(tester, 'Food');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.saved.single.target, isNull);
      expect(repository.saved.single.assigned, php(0));
    });

    testWidgets('pre-fills the plan; Clear plan removes both amounts', (
      tester,
    ) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000, assigned: 250000)]);

      await openDialog(tester, 'Food');
      expect(find.text('5000.00'), findsOneWidget);
      expect(find.text('2500.00'), findsOneWidget);
      await tester.tap(find.text('Clear plan'));
      await tester.pumpAndSettle();

      expect(repository.saved.single.target, isNull);
      expect(repository.saved.single.assigned, php(0));
    });

    testWidgets('nothing assigned starts empty with a 0.00 hint', (
      tester,
    ) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000, assigned: 0)]);

      await tester.tap(find.byTooltip('Edit Food assigned'));
      await tester.pumpAndSettle();

      final assigned = tester.widget<TextField>(
        find.descendant(
          of: field('Assigned'),
          matching: find.byType(TextField),
        ),
      );
      expect(assigned.controller!.text, isEmpty);
      expect(assigned.decoration!.hintText, '0.00');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repository.saved.single.assigned, php(0));
      expect(repository.saved.single.target, php(500000));
    });

    group('a zero target', () {
      TextField targetField(WidgetTester tester) => tester.widget<TextField>(
        find.descendant(of: field('Target'), matching: find.byType(TextField)),
      );

      testWidgets('starts empty with a 0.00 hint and stays zero if left', (
        tester,
      ) async {
        await pumpScreen(tester, plans: [plan(foodId, 0, assigned: 0)]);

        await tester.tap(find.byTooltip('Edit Food target'));
        await tester.pumpAndSettle();
        expect(targetField(tester).controller!.text, isEmpty);
        expect(targetField(tester).decoration!.hintText, '0.00');
        expect(find.text('Leave empty to keep a ₱0.00 target'), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(repository.saved.single.target, php(0));
      });

      testWidgets('typing replaces it directly', (tester) async {
        await pumpScreen(tester, plans: [plan(foodId, 0, assigned: 0)]);

        await tester.tap(find.byTooltip('Edit Food target'));
        await tester.pumpAndSettle();
        await tester.enterText(field('Target'), '1,500');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(repository.saved.single.target, php(150000));
      });
    });

    testWidgets('rejects invalid amounts and saves nothing', (tester) async {
      await pumpScreen(tester);
      await openDialog(tester, 'Food');

      await tester.enterText(field('Target'), '-5');
      await tester.enterText(field('Assigned'), 'abc');
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

      await tester.enterText(field('Assigned'), '100');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.saved, isEmpty);
    });

    testWidgets('tapping Target edits only the target', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000, assigned: 250000)]);

      await tester.tap(find.byTooltip('Edit Food target'));
      await tester.pumpAndSettle();
      expect(field('Target'), findsOneWidget);
      expect(field('Assigned'), findsNothing);
      expect(find.text('Clear plan'), findsNothing);

      await tester.enterText(field('Target'), '6,000');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.saved.single, (
        month: november,
        categoryId: foodId,
        target: php(600000),
        assigned: php(250000),
      ));
    });

    testWidgets('tapping Assigned edits only the assigned amount', (
      tester,
    ) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000, assigned: 250000)]);

      await tester.tap(find.byTooltip('Edit Food assigned'));
      await tester.pumpAndSettle();
      expect(field('Assigned'), findsOneWidget);
      expect(field('Target'), findsNothing);

      await tester.enterText(field('Assigned'), '5,000');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.saved.single, (
        month: november,
        categoryId: foodId,
        target: php(500000),
        assigned: php(500000),
      ));
    });

    testWidgets('editing one amount keeps having no target', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Edit Food assigned'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Assigned'), '100');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.saved.single.target, isNull);
      expect(repository.saved.single.assigned, php(10000));
    });

    testWidgets('an archived category without a plan has no edit links', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        transactions: [saved(spending(amount: 5000, category: giftsId))],
      );

      await tester.tap(find.byTooltip('Archived plans'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gifts'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Edit Gifts target'), findsNothing);
      expect(find.byTooltip('Edit Gifts assigned'), findsNothing);
      expect(find.byTooltip('Show Gifts transactions'), findsOneWidget);
    });

    testWidgets('an archived category keeps its plan as read-only history', (
      tester,
    ) async {
      await pumpScreen(tester, plans: [plan(giftsId, 200000)]);

      await tester.tap(find.byTooltip('Archived plans'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gifts'));
      await tester.pumpAndSettle();
      expect(amount(tester, 'Gifts (archived)', 'Assigned'), '₱2,000.00');
      expect(find.byTooltip('Edit Gifts assigned'), findsNothing);
      expect(find.text('Unarchive plan'), findsOneWidget);
    });
  });
}
