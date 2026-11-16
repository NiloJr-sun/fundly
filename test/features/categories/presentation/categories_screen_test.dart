import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/categories/presentation/categories_screen.dart';
import 'package:fundly/features/categories/presentation/category_form_screen.dart';
import 'package:fundly/features/plans/presentation/plans_screen.dart';

import '../../../helpers/provider_overrides.dart';

void main() {
  const food = Category(id: 1, name: 'Food', kind: CategoryKind.spending);
  const salary = Category(id: 2, name: 'Salary', kind: CategoryKind.inflow);
  const gifts = Category(
    id: 3,
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
}
