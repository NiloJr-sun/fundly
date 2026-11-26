import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/categories/presentation/categories_screen.dart';
import 'package:fundly/features/categories/presentation/category_form_screen.dart';
import 'package:fundly/features/plans/presentation/plans_screen.dart';

import '../../../helpers/provider_overrides.dart';
import '../../transactions/domain/transaction_fixtures.dart' as fixtures;

void main() {
  const food = Category(id: '1', name: 'Food', kind: CategoryKind.spending);
  const salary = Category(id: '2', name: 'Salary', kind: CategoryKind.inflow);
  const gifts = Category(
    id: '3',
    name: 'Gifts',
    kind: CategoryKind.spending,
    isArchived: true,
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    List<Category> categories,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeAccounts(const [], categories: categories),
        child: const MaterialApp(home: CategoriesScreen()),
      ),
    );
    await tester.pump();
  }

  /// Top of the first widget showing [text], to check the list order.
  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text).first).dy;

  testWidgets('opens from the Plans tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeAccounts(const [], categories: const [food]),
        child: const MaterialApp(home: PlansScreen()),
      ),
    );

    await tester.tap(find.byTooltip('Categories'));
    await tester.pumpAndSettle();

    expect(find.byType(CategoriesScreen), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets('groups active categories by kind, archived last', (
    tester,
  ) async {
    await pumpScreen(tester, const [food, salary, gifts]);

    expect(top(tester, 'Spending'), lessThan(top(tester, 'Food')));
    expect(top(tester, 'Food'), lessThan(top(tester, 'Inflow')));
    expect(top(tester, 'Inflow'), lessThan(top(tester, 'Salary')));
    expect(top(tester, 'Salary'), lessThan(top(tester, 'Archived')));
    expect(top(tester, 'Archived'), lessThan(top(tester, 'Gifts')));
    // Archived rows say which kind they were.
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Gifts'),
        matching: find.text('Spending'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a Plans group other than Spending', (tester) async {
    await pumpScreen(tester, const [
      food,
      Category(
        id: '4',
        name: 'Emergency fund',
        kind: CategoryKind.spending,
        planGroup: PlanGroup.savings,
      ),
      Category(
        id: '5',
        name: 'Old card',
        kind: CategoryKind.spending,
        isArchived: true,
        planGroup: PlanGroup.liability,
      ),
    ]);

    String? subtitleOf(String name) {
      final tile = tester.widget<ListTile>(find.widgetWithText(ListTile, name));
      return (tile.subtitle as Text?)?.data;
    }

    expect(subtitleOf('Emergency fund'), 'Savings');
    expect(subtitleOf('Food'), isNull, reason: 'the default is not shown');
    expect(subtitleOf('Old card'), 'Spending · Liability');
  });

  testWidgets('hides empty sections', (tester) async {
    await pumpScreen(tester, const [food]);

    expect(find.text('Inflow'), findsNothing);
    expect(find.text('Archived'), findsNothing);
  });

  testWidgets('tapping a category opens it for editing', (tester) async {
    await pumpScreen(tester, const [food]);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    expect(find.text('Edit category'), findsOneWidget);
  });

  testWidgets('the add button opens a new category form', (tester) async {
    await pumpScreen(tester, const [food]);

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryFormScreen), findsOneWidget);
    expect(find.text('New category'), findsOneWidget);
  });

  group('Liability section', () {
    const insurance = Category(
      id: '6',
      name: 'Insurance',
      kind: CategoryKind.spending,
      planGroup: PlanGroup.liability,
    );
    final card = fixtures.accounts[fixtures.rcbcCardId]!;
    final cardRow = Category(
      id: '7',
      name: card.name,
      kind: CategoryKind.spending,
      planGroup: PlanGroup.liability,
      linkedAccountId: card.id,
    );

    Future<void> pumpWithAccounts(
      WidgetTester tester,
      List<Category> categories,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: fakeAccounts(
            fixtures.accounts.values.toList(),
            categories: categories,
          ),
          child: const MaterialApp(home: CategoriesScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    String? subtitleOf(WidgetTester tester, String name) {
      final tile = tester.widget<ListTile>(find.widgetWithText(ListTile, name));
      return (tile.subtitle as Text?)?.data;
    }

    final loan = fixtures.accounts[fixtures.carLoanId]!;
    final loanRow = Category(
      id: '9',
      name: loan.name,
      kind: CategoryKind.spending,
      planGroup: PlanGroup.liability,
      linkedAccountId: loan.id,
    );

    testWidgets('debt rows split into Credit card payments and Loans, then '
        'Liability-group categories, before Inflow', (tester) async {
      await pumpWithAccounts(tester, [
        food,
        salary,
        insurance,
        cardRow,
        loanRow,
      ]);

      double heading(String title) => top(tester, title);
      expect(top(tester, 'Food'), lessThan(heading('Credit card payments')));
      expect(heading('Credit card payments'), lessThan(top(tester, card.name)));
      expect(top(tester, card.name), lessThan(heading('Loans')));
      expect(heading('Loans'), lessThan(top(tester, loan.name)));
      expect(top(tester, loan.name), lessThan(heading('Liability')));
      expect(heading('Liability'), lessThan(top(tester, 'Insurance')));
      expect(top(tester, 'Insurance'), lessThan(heading('Inflow')));
      expect(
        subtitleOf(tester, 'Insurance'),
        isNull,
        reason: 'the section heading already names the group',
      );
      expect(subtitleOf(tester, card.name), 'From account · Credit');
    });

    testWidgets('hides Liability without Liability-group categories', (
      tester,
    ) async {
      await pumpWithAccounts(tester, [food, cardRow]);

      expect(find.text('Credit card payments'), findsOneWidget);
      expect(find.text('Loans'), findsNothing);
      expect(find.text('Liability'), findsNothing);
    });

    testWidgets('a debt row opens its Target form', (tester) async {
      await pumpWithAccounts(tester, [food, cardRow]);

      await tester.tap(find.text(card.name));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryFormScreen), findsOneWidget);
      expect(find.text('Open account'), findsOneWidget);
    });

    testWidgets('archived and permanently deleted debt rows are not listed', (
      tester,
    ) async {
      await pumpWithAccounts(tester, [
        food,
        Category(
          id: '7',
          name: card.name,
          kind: CategoryKind.spending,
          planGroup: PlanGroup.liability,
          linkedAccountId: card.id,
          isArchived: true,
        ),
        const Category(
          id: '8',
          name: 'Old loan',
          kind: CategoryKind.spending,
          planGroup: PlanGroup.liability,
          linkedAccountId: fixtures.carLoanId,
          isPlanDeleted: true,
        ),
      ]);

      expect(find.text('Credit card payments'), findsNothing);
      expect(find.text('Loans'), findsNothing);
      expect(find.text(card.name), findsNothing);
      expect(find.text('Old loan'), findsNothing);
    });
  });
}
