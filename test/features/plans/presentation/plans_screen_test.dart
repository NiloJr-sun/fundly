import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/home_shell.dart';
import 'package:fundly/app/theme/app_colors.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/presentation/assign_panel.dart';
import 'package:fundly/features/plans/presentation/plan_details.dart';
import 'package:fundly/features/plans/presentation/plan_row.dart';
import 'package:fundly/features/plans/presentation/plans_screen.dart';
import 'package:fundly/features/plans/presentation/ready_to_assign_card.dart';
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
    bool walletIsBudgetAccount = false,
    int? budgetOpeningBalance,
    bool inShell = false,
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
        else if (account.id == walletId && walletIsBudgetAccount)
          Account(
            id: account.id,
            name: account.name,
            type: account.type,
            openingBalance: account.openingBalance,
            createdAt: account.createdAt,
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
        child: MaterialApp(
          home: inShell ? const HomeShell() : const PlansScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (inShell) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Plans'),
        ),
      );
      await tester.pumpAndSettle();
    }
  }

  Finder row(String name) => find.widgetWithText(PlanRow, name);

  Finder inRow(String name, String text) =>
      find.descendant(of: row(name), matching: find.text(text));

  Finder inDetails(String text) =>
      find.descendant(of: find.byType(PlanDetails), matching: find.text(text));

  /// Opens [name]'s details sheet: tapping the row opens the keypad, whose
  /// Details button opens the sheet.
  Future<void> openDetails(WidgetTester tester, String name) async {
    await tester.ensureVisible(inRow(name, name));
    await tester.pumpAndSettle();
    await tester.tap(inRow(name, name));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AssignPanel),
        matching: find.text('Details'),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The value beside [label] (Target, Assigned, Activity or Available) in
  /// [name]'s details. Opens the row's sheet and closes it again, unless the
  /// details are already shown (archived history).
  Future<String> amount(WidgetTester tester, String name, String label) async {
    final open = find.byType(PlanDetails).evaluate().isEmpty;
    if (open) await openDetails(tester, name);
    final line = find
        .ancestor(of: inDetails(label), matching: find.byType(Row))
        .first;
    final value = tester
        .widgetList<Text>(
          find.descendant(of: line, matching: find.byType(Text)),
        )
        .map((text) => text.data)
        .where((data) => data != label)
        .single!;
    if (open) {
      Navigator.of(tester.element(find.byType(PlanDetails))).pop();
      await tester.pumpAndSettle();
    }
    return value;
  }

  Future<({String target, String assigned, String activity, String available})>
  amounts(WidgetTester tester, String name) async => (
    target: await amount(tester, name, 'Target'),
    assigned: await amount(tester, name, 'Assigned'),
    activity: await amount(tester, name, 'Activity'),
    available: await amount(tester, name, 'Available'),
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
      expect(await amount(tester, 'Food', 'Target'), '₱2,000.00');
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

    testWidgets('a row shows only Assigned and Available', (tester) async {
      await pumpScreen(
        tester,
        plans: [plan(foodId, 500000, assigned: 250000)],
        transactions: [saved(spending(amount: 120000))],
      );

      expect(inRow('Food', '₱2,500.00'), findsOneWidget);
      expect(
        find.descendant(of: row('Food'), matching: find.byType(AvailablePill)),
        findsOneWidget,
      );
      expect(inRow('Food', '₱1,300.00'), findsOneWidget);
      for (final hidden in ['Target', '₱5,000.00', 'Activity', '₱1,200.00']) {
        expect(inRow('Food', hidden), findsNothing, reason: hidden);
      }
      expect(inRow('Food', 'Underfunded'), findsNothing);
    });

    testWidgets('details show target, assigned, activity, available and '
        'status', (tester) async {
      await pumpScreen(
        tester,
        plans: [plan(foodId, 500000, assigned: 250000)],
        transactions: [saved(spending(amount: 120000))],
      );

      expect(await amounts(tester, 'Food'), (
        target: '₱5,000.00',
        assigned: '₱2,500.00',
        activity: '₱1,200.00',
        available: '₱1,300.00',
      ));
      await openDetails(tester, 'Food');
      expect(inDetails('Underfunded'), findsOneWidget);
      expect(find.text('November 2026'), findsNWidgets(2));
    });

    testWidgets('funded when assigned covers the target', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)]);

      await openDetails(tester, 'Food');
      expect(inDetails('Funded'), findsOneWidget);
    });

    testWidgets('no target: displays zero and no status', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, null, assigned: 100000)]);

      expect(await amount(tester, 'Food', 'Target'), '₱0.00');
      expect(await amount(tester, 'Food', 'Available'), '₱1,000.00');
      await openDetails(tester, 'Food');
      expect(inDetails('Funded'), findsNothing);
      expect(inDetails('Underfunded'), findsNothing);
    });

    group('the Available pill', () {
      final foodPill = find.descendant(
        of: row('Food'),
        matching: find.byType(AvailablePill),
      );

      Color? pillText(WidgetTester tester, String available) => tester
          .widget<Text>(
            find.descendant(of: foodPill, matching: find.text(available)),
          )
          .style
          ?.color;

      Color? pillBackground(WidgetTester tester) =>
          (tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: foodPill,
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .color;

      AppColors colors(WidgetTester tester) =>
          AppColors.of(tester.element(row('Food')));

      testWidgets('is green when the Target is funded', (tester) async {
        await pumpScreen(tester, plans: [plan(foodId, 500000)]);

        expect(pillText(tester, '₱5,000.00'), colors(tester).positive);
        expect(
          pillBackground(tester),
          colors(tester).positive.withValues(alpha: 0.2),
        );
      });

      testWidgets('is green at zero once funded and spent', (tester) async {
        await pumpScreen(
          tester,
          plans: [plan(foodId, 500000)],
          transactions: [saved(spending(amount: 500000))],
        );

        expect(pillText(tester, '₱0.00'), colors(tester).positive);
      });

      testWidgets('is yellow when the Target is underfunded', (tester) async {
        await pumpScreen(tester, plans: [plan(foodId, 500000, assigned: 1000)]);

        expect(pillText(tester, '₱10.00'), colors(tester).warning);
      });

      testWidgets('is red when overspent', (tester) async {
        await pumpScreen(tester, transactions: [saved(spending(amount: 8000))]);

        expect(pillText(tester, '-₱80.00'), colors(tester).expense);
      });

      testWidgets('is grey without a Target', (tester) async {
        await pumpScreen(tester, plans: [plan(foodId, null, assigned: 1000)]);
        final scheme = Theme.of(tester.element(row('Food'))).colorScheme;

        expect(pillText(tester, '₱10.00'), scheme.onSurface);
        expect(pillBackground(tester), scheme.surfaceContainerHighest);
      });
    });

    testWidgets('spending with nothing assigned shows a red available', (
      tester,
    ) async {
      await pumpScreen(tester, transactions: [saved(spending(amount: 8000))]);

      expect(await amounts(tester, 'Food'), (
        target: '₱0.00',
        assigned: '₱0.00',
        activity: '₱80.00',
        available: '-₱80.00',
      ));
      await openDetails(tester, 'Food');
      final available = tester.widget<Text>(inDetails('-₱80.00'));
      final context = tester.element(find.byType(PlanDetails));
      expect(available.style?.color, AppColors.of(context).expense);
      expect(inDetails('Overspent'), findsOneWidget);
    });

    testWidgets('overspent replaces funded, in the error colours', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        plans: [plan(foodId, 500000)],
        transactions: [saved(spending(amount: 600000))],
      );

      await openDetails(tester, 'Food');
      expect(inDetails('Overspent'), findsOneWidget);
      expect(inDetails('Funded'), findsNothing);
      final details = tester.element(find.byType(PlanDetails));
      final colors = Theme.of(details).colorScheme;
      final chip = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: inDetails('Overspent'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((chip.decoration as BoxDecoration).color, colors.errorContainer);
      expect(
        tester.widget<Text>(inDetails('Overspent')).style?.color,
        colors.onErrorContainer,
      );
      // Target and Assigned are both PHP 5,000; Assigned is the second.
      final assigned = tester.widget<Text>(inDetails('₱5,000.00').at(1));
      expect(assigned.style?.color, AppColors.of(details).positive);
    });

    testWidgets('group headers total Assigned and Available', (tester) async {
      await pumpScreen(
        tester,
        plans: [
          plan(foodId, 500000, assigned: 300000),
          plan(transportId, 100000, assigned: 100000),
        ],
        transactions: [saved(spending(amount: 450000))],
      );

      final header = find.byType(PlanGroupHeader);
      expect(
        find.descendant(of: header, matching: find.text('₱4,000.00')),
        findsOneWidget,
      );
      // Food is PHP 1,500 overspent and Transport has PHP 1,000 left.
      final available = find.descendant(
        of: header,
        matching: find.text('-₱500.00'),
      );
      expect(available, findsOneWidget);
      expect(
        tester.widget<Text>(available).style?.color,
        AppColors.of(tester.element(header)).expense,
      );
    });

    group('the details sheet', () {
      testWidgets('See transactions opens the month for the category', (
        tester,
      ) async {
        await pumpScreen(tester);

        await openDetails(tester, 'Food');
        await tester.tap(find.text('See transactions'));
        await tester.pumpAndSettle();

        expect(find.byType(AllTransactionsScreen), findsOneWidget);
        expect(find.text('Nov 1, 2026 – Nov 30, 2026'), findsOneWidget);
      });

      testWidgets('dismissing it changes nothing', (tester) async {
        await pumpScreen(tester);

        await openDetails(tester, 'Food');
        Navigator.of(tester.element(find.byType(PlanDetails))).pop();
        await tester.pumpAndSettle();

        expect(find.byType(PlanDetails), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
        expect(repository.saved, isEmpty);
      });
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

      expect(await amount(tester, 'Food', 'Activity'), '₱1,000.00');
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
      expect(inDetails('Gifts (archived)'), findsOneWidget);
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
      await openDetails(tester, 'Food');
      expect(tester.takeException(), isNull);
      expect(inDetails('Overspent'), findsOneWidget);
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
      expect(await amount(tester, 'Food', 'Target'), '₱3,000.00');

      await tester.tap(find.text('This month'));
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);
      expect(await amount(tester, 'Food', 'Target'), '₱5,000.00');
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

      await openDetails(tester, 'Food');
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
      matching: find.byType(Card),
    );

    Text amountText(WidgetTester tester) => tester.widget<Text>(
      find.byKey(const ValueKey('ready-to-assign-amount')),
    );

    /// The amount shown beside a breakdown label such as `− Assigned`.
    String? breakdown(WidgetTester tester, String label) {
      final row = find.ancestor(
        of: find.text(label),
        matching: find.byType(Row),
      );
      return tester
          .widgetList<Text>(
            find.descendant(of: row.first, matching: find.byType(Text)),
          )
          .last
          .data;
    }

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
      final inkWell = tester.widget<InkWell>(
        find.descendant(of: card(), matching: find.byType(InkWell)).first,
      );
      expect(inkWell.onTap, isNull);
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

      expect(breakdown(tester, 'Carry over'), '₱0.00');
      expect(breakdown(tester, '+ Money in this month'), '₱40,000.00');
      expect(breakdown(tester, '− Moved out this month'), '₱5,000.00');
      expect(breakdown(tester, '− Assigned'), '₱5,000.00');
      expect(find.text('From BDO Savings'), findsOneWidget);
      expect(find.text('Left to assign'), findsOneWidget);
      expect(find.text('Assign ₱30,000.00'), findsOneWidget);
      // ₱5,000 of the ₱35,000 available.
      expect(find.text('14.3% assigned'), findsOneWidget);
      expect(find.text('₱35,000.00 available'), findsOneWidget);
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
      expect(breakdown(tester, 'Carry over'), '₱10,000.00');
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
      expect(breakdown(tester, '+ Money in this month'), '₱10,000.00');
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
      expect(find.text('Over by ₱5,000.00'), findsOneWidget);
      expect(find.text('Fix over-assignment'), findsOneWidget);
      // Nothing is available, so there is no percentage.
      expect(find.textContaining('% assigned'), findsNothing);
      final context = tester.element(card());
      expect(amount.style?.color, AppColors.of(context).expense);
    });

    testWidgets('shows the share assigned when over by a little', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        bdoIsBudgetAccount: true,
        plans: [plan(foodId, 1725000)],
        transactions: [saved(inflow(amount: 1708303), id: '1')],
      );

      expect(find.text('101% assigned'), findsOneWidget);
      expect(find.text('Over by ₱166.97'), findsOneWidget);
    });

    testWidgets('zero is balanced, in the default colour', (tester) async {
      await pumpScreen(tester, bdoIsBudgetAccount: true);

      final amount = amountText(tester);
      expect(amount.data, '₱0.00');
      expect(find.text('Balanced'), findsOneWidget);
      expect(find.text('Every peso has a job'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      final context = tester.element(card());
      expect(amount.style?.color, Theme.of(context).colorScheme.onSurface);
    });

    Color? badgeColour(WidgetTester tester, String label) {
      final box = tester.widget<DecoratedBox>(
        find
            .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
            .first,
      );
      return (box.decoration as BoxDecoration).color;
    }

    ColorScheme colors(WidgetTester tester) =>
        Theme.of(tester.element(card())).colorScheme;

    testWidgets('Over badge uses the Overspent chip colour', (tester) async {
      await pumpScreen(
        tester,
        bdoIsBudgetAccount: true,
        plans: [plan(foodId, 500000)],
      );
      expect(
        badgeColour(tester, 'Over by ₱5,000.00'),
        colors(tester).errorContainer,
      );
    });

    testWidgets('Balanced badge uses the Funded chip colour', (tester) async {
      await pumpScreen(tester, bdoIsBudgetAccount: true);
      expect(badgeColour(tester, 'Balanced'), colors(tester).primaryContainer);
    });

    testWidgets('Left to assign badge uses the Underfunded chip colour', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        bdoIsBudgetAccount: true,
        transactions: [saved(inflow(amount: 100000), id: '1')],
      );
      expect(
        badgeColour(tester, 'Left to assign'),
        colors(tester).tertiaryContainer,
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

    testWidgets("tapping it opens the month's transactions, all accounts", (
      tester,
    ) async {
      await pumpScreen(
        tester,
        bdoIsBudgetAccount: true,
        transactions: [saved(inflow(amount: 4000000), id: '1')],
      );

      await tester.tap(find.text('Ready to assign'));
      await tester.pumpAndSettle();

      expect(find.byType(AllTransactionsScreen), findsOneWidget);
      expect(find.text('Nov 1, 2026 – Nov 30, 2026'), findsOneWidget);
      expect(find.text('All accounts'), findsOneWidget);
    });

    testWidgets('the Assign button scrolls to the plans, not to transactions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpScreen(
        tester,
        bdoIsBudgetAccount: true,
        transactions: [saved(inflow(amount: 4000000), id: '1')],
      );
      final list = find.byType(Scrollable).first;
      final before = tester.state<ScrollableState>(list).position.pixels;

      await tester.tap(find.text('Assign ₱40,000.00'));
      await tester.pumpAndSettle();

      expect(find.byType(AllTransactionsScreen), findsNothing);
      expect(
        tester.state<ScrollableState>(list).position.pixels,
        greaterThan(before),
      );
    });

    testWidgets('lists several budget accounts; transfers between them '
        'do not count', (tester) async {
      await pumpScreen(
        tester,
        bdoIsBudgetAccount: true,
        walletIsBudgetAccount: true,
        plans: [plan(foodId, 500000)],
        transactions: [
          saved(inflow(amount: 4000000), id: '1'),
          saved(transferToWallet(1000000), id: '2'),
        ],
      );

      expect(
        find.text('From 2 accounts · BDO Savings, Cash Wallet'),
        findsOneWidget,
      );
      expect(find.textContaining('Moved out'), findsNothing);
      expect(amountText(tester).data, '₱35,000.00');
    });
  });

  group('assignedPercentLabel', () {
    Money peso(int minorUnits) =>
        Money(minorUnits: minorUnits, currencyCode: 'PHP');

    test('rounds to one decimal and drops a trailing zero', () {
      expect(
        assignedPercentLabel(assigned: peso(1704800), available: peso(1708303)),
        '99.8%',
      );
      expect(
        assignedPercentLabel(assigned: peso(1725000), available: peso(1708303)),
        '101%',
      );
      expect(
        assignedPercentLabel(assigned: peso(1708303), available: peso(1708303)),
        '100%',
      );
    });

    test('shows 100% only when exactly balanced', () {
      expect(
        assignedPercentLabel(assigned: peso(999999), available: peso(1000000)),
        '99.9%',
      );
      expect(
        assignedPercentLabel(assigned: peso(1000001), available: peso(1000000)),
        '100.1%',
      );
    });

    test('is null when nothing is available', () {
      expect(
        assignedPercentLabel(assigned: peso(100), available: peso(0)),
        isNull,
      );
      expect(
        assignedPercentLabel(assigned: peso(0), available: peso(-100)),
        isNull,
      );
    });
  });

  group('editing the plan', () {
    Future<void> openDialog(WidgetTester tester, String name) async {
      await openDetails(tester, name);
      await tester.tap(find.text('Edit plan'));
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

      await openDetails(tester, 'Food');
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

        await openDetails(tester, 'Food');
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

        await openDetails(tester, 'Food');
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

      await openDetails(tester, 'Food');
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

      await openDetails(tester, 'Food');
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

      await openDetails(tester, 'Food');
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
      expect(await amount(tester, 'Gifts (archived)', 'Assigned'), '₱2,000.00');
      expect(find.byTooltip('Edit Gifts assigned'), findsNothing);
      expect(find.text('Unarchive plan'), findsOneWidget);
    });
  });

  group('editing Assigned in place', () {
    Finder panel() => find.byType(AssignPanel);

    Finder key(String face) =>
        find.descendant(of: panel(), matching: find.text(face));

    Future<void> startAssign(WidgetTester tester, String name) async {
      // Scrolled in code: a drag would be a tap outside the panel.
      await tester.ensureVisible(inRow(name, name));
      await tester.pumpAndSettle();
      await tester.tap(inRow(name, name));
      await tester.pumpAndSettle();
    }

    Future<void> type(WidgetTester tester, String faces) async {
      for (final face in faces.split('')) {
        await tester.tap(key(face == '-' ? '−' : face));
        await tester.pump();
      }
    }

    Future<void> tapPanel(WidgetTester tester, String label) async {
      await tester.tap(
        find.descendant(of: panel(), matching: find.text(label)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tapping a row opens the keypad on that row', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000, assigned: 250000)]);

      await startAssign(tester, 'Food');

      expect(panel(), findsOneWidget);
      expect(inRow('Food', '₱2500.00'), findsOneWidget);
      for (final label in ['Activity', 'Details', 'Cancel', 'Done']) {
        expect(
          find.descendant(of: panel(), matching: find.text(label)),
          findsOneWidget,
          reason: label,
        );
      }
      expect(find.byType(PlanDetails), findsNothing);
    });

    testWidgets('tapping the row being edited keeps editing', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)]);

      await startAssign(tester, 'Food');
      await type(tester, '42');
      await tester.tap(inRow('Food', 'Food'));
      await tester.pumpAndSettle();

      expect(panel(), findsOneWidget);
      expect(inRow('Food', '₱42'), findsOneWidget);
      expect(repository.saved, isEmpty);
    });

    testWidgets("the row's Activity button opens the transactions", (
      tester,
    ) async {
      await pumpScreen(
        tester,
        plans: [plan(foodId, 500000)],
        transactions: [saved(spending(amount: 8000, payee: 'Jollibee'))],
      );

      await tester.tap(find.byTooltip('Food activity'));
      await tester.pumpAndSettle();

      expect(panel(), findsNothing);
      expect(find.byType(AllTransactionsScreen), findsOneWidget);
      expect(
        tester
            .widgetList<TransactionTile>(find.byType(TransactionTile))
            .map((tile) => tile.transaction.payee),
        ['Jollibee'],
      );
    });

    testWidgets("the edited row's Activity button saves first", (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)]);

      await startAssign(tester, 'Food');
      await type(tester, '42');
      await tester.tap(find.byTooltip('Food activity'));
      await tester.pumpAndSettle();

      expect(repository.saved.single.assigned, php(4200));
      expect(find.byType(AllTransactionsScreen), findsOneWidget);
    });

    testWidgets('sections are nearly full width, with rounded corners', (
      tester,
    ) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)]);

      final screen = tester.getRect(find.byType(PlansScreen));
      final section = tester.getRect(find.byType(ExpansionTile).first);
      final food = tester.getRect(row('Food'));
      for (final rect in [section, food]) {
        expect(rect.left, screen.left + 8);
        expect(rect.right, screen.right - 8);
      }
      final clip = tester.widget<ClipRRect>(
        find
            .ancestor(
              of: find.byType(ExpansionTile).first,
              matching: find.byType(ClipRRect),
            )
            .first,
      );
      expect(clip.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('group totals line up with the row columns', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)]);

      final header = find.byType(PlanGroupHeader).first;
      final availableLabel = find.descendant(
        of: header,
        matching: find.text('Available'),
      );
      final pill = find.descendant(
        of: find.descendant(
          of: row('Food'),
          matching: find.byType(AvailablePill),
        ),
        matching: find.byType(DecoratedBox),
      );
      expect(
        tester.getRect(availableLabel).right,
        moreOrLessEquals(tester.getRect(pill).right, epsilon: 1),
      );
    });

    testWidgets('typing replaces the amount; Done saves it', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000, assigned: 250000)]);

      await startAssign(tester, 'Food');
      await type(tester, '3000');
      expect(inRow('Food', '₱3000'), findsOneWidget);
      await tapPanel(tester, 'Done');

      expect(panel(), findsNothing);
      expect(repository.saved.single, (
        month: november,
        categoryId: foodId,
        target: php(500000),
        assigned: php(300000),
      ));
    });

    testWidgets('the keypad adds and subtracts', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000, assigned: 250000)]);

      await startAssign(tester, 'Food');
      await type(tester, '+500-0.5=');
      expect(inRow('Food', '₱2999.50'), findsOneWidget);
      await tapPanel(tester, 'Done');

      expect(repository.saved.single.assigned, php(299950));
    });

    testWidgets('delete removes the last character', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, null, assigned: 0)]);

      await startAssign(tester, 'Food');
      await type(tester, '125');
      await tester.tap(
        find.descendant(
          of: panel(),
          matching: find.byIcon(Icons.backspace_outlined),
        ),
      );
      await tester.pump();
      await tapPanel(tester, 'Done');

      expect(repository.saved.single.assigned, php(1200));
      expect(repository.saved.single.target, isNull);
    });

    testWidgets('Cancel saves nothing', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)]);

      await startAssign(tester, 'Food');
      await type(tester, '9');
      await tapPanel(tester, 'Cancel');

      expect(panel(), findsNothing);
      expect(repository.saved, isEmpty);
      expect(inRow('Food', '₱5,000.00'), findsNWidgets(2));
    });

    testWidgets('an unchanged amount is not saved', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)]);

      await startAssign(tester, 'Food');
      await tapPanel(tester, 'Done');

      expect(repository.saved, isEmpty);
    });

    testWidgets('tapping outside saves and closes', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)]);

      await startAssign(tester, 'Food');
      await type(tester, '42');
      await tester.tap(find.text('Plans'));
      await tester.pumpAndSettle();

      expect(panel(), findsNothing);
      expect(repository.saved.single.assigned, php(4200));
    });

    testWidgets("another row's Assigned saves this one and edits that one", (
      tester,
    ) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)]);

      await startAssign(tester, 'Food');
      await type(tester, '42');
      await startAssign(tester, 'Transport');

      expect(repository.saved.single.categoryId, foodId);
      expect(panel(), findsOneWidget);
      await type(tester, '7');
      await tapPanel(tester, 'Done');
      expect(repository.saved.last.categoryId, transportId);
      expect(repository.saved.last.assigned, php(700));
    });

    testWidgets('a sum below zero is refused and kept open', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000, assigned: 10000)]);

      await startAssign(tester, 'Food');
      await type(tester, '-200');
      await tapPanel(tester, 'Done');

      expect(find.text("Assigned can't be below zero."), findsOneWidget);
      expect(panel(), findsOneWidget);
      expect(repository.saved, isEmpty);
    });

    testWidgets('an unfinished sum asks to be finished', (tester) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)]);

      await startAssign(tester, 'Food');
      await type(tester, '+');
      await tapPanel(tester, 'Done');

      expect(
        find.text('Finish the sum, for example 1,000+500.'),
        findsOneWidget,
      );
      expect(repository.saved, isEmpty);
    });

    testWidgets('the hint fills in the amount that reaches the Target', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        plans: [plan(foodId, 2400000, assigned: 1000000)],
      );

      await startAssign(tester, 'Food');
      await tapPanel(tester, 'Assign ₱14,000.00 more to reach your target');
      expect(repository.saved, isEmpty, reason: 'filling does not save');
      await tapPanel(tester, 'Done');

      expect(repository.saved.single.assigned, php(2400000));
    });

    testWidgets('no hint once the Target is reached or without one', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        plans: [plan(foodId, 500000), plan(transportId, null, assigned: 0)],
      );

      await startAssign(tester, 'Food');
      expect(find.textContaining('to reach your target'), findsNothing);
      await startAssign(tester, 'Transport');
      expect(find.textContaining('to reach your target'), findsNothing);
    });

    testWidgets('Activity saves, then opens the category transactions', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        plans: [plan(foodId, 500000)],
        transactions: [saved(spending(amount: 8000, payee: 'Jollibee'))],
      );

      await startAssign(tester, 'Food');
      await type(tester, '42');
      await tapPanel(tester, 'Activity');

      expect(repository.saved.single.assigned, php(4200));
      expect(find.byType(AllTransactionsScreen), findsOneWidget);
      expect(
        tester
            .widgetList<TransactionTile>(find.byType(TransactionTile))
            .map((tile) => tile.transaction.payee),
        ['Jollibee'],
      );
    });

    testWidgets('Details closes the keypad and opens the details', (
      tester,
    ) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)]);

      await startAssign(tester, 'Food');
      await tapPanel(tester, 'Details');

      expect(panel(), findsNothing);
      expect(find.byType(PlanDetails), findsOneWidget);
      expect(repository.saved, isEmpty);
    });

    testWidgets('docks edge to edge at the bottom, over the tab bar', (
      tester,
    ) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)], inShell: true);

      await startAssign(tester, 'Food');

      final screen = tester.getRect(find.byType(HomeShell));
      final keypad = tester.getRect(panel());
      expect(keypad.left, screen.left);
      expect(keypad.right, screen.right);
      expect(keypad.bottom, screen.bottom);
      final tabs = tester.getRect(find.byType(NavigationBar));
      expect(keypad.top, lessThanOrEqualTo(tabs.top));
      // The tab bar is covered, so tapping there is a tap on the keypad.
      expect(
        tester
            .hitTestOnBinding(tabs.center)
            .path
            .any((entry) => entry.target == tester.renderObject(panel())),
        isTrue,
      );
    });

    testWidgets('keeps the edited row above the keypad', (tester) async {
      tester.view
        ..physicalSize = const Size(390, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpScreen(tester, plans: [plan(transportId, 500000)]);

      await startAssign(tester, 'Transport');

      final keypadTop = tester.getRect(panel()).top;
      expect(tester.getRect(row('Transport')).bottom, lessThan(keypadTop));
    });

    testWidgets('closing the keypad removes it from the screen', (
      tester,
    ) async {
      await pumpScreen(tester, plans: [plan(foodId, 500000)], inShell: true);

      await startAssign(tester, 'Food');
      await tapPanel(tester, 'Cancel');

      expect(panel(), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Accounts'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PlansScreen), findsNothing);
    });

    testWidgets('fits a small phone without overflow', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpScreen(tester, plans: [plan(foodId, 500000, assigned: 1000)]);

      await startAssign(tester, 'Food');

      expect(tester.takeException(), isNull);
      expect(panel(), findsOneWidget);
    });
  });
}
