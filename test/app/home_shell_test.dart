import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/home_shell.dart';
import 'package:fundly/app/theme/app_theme.dart';
import 'package:fundly/features/accounts/presentation/account_form_screen.dart';
import 'package:fundly/features/accounts/presentation/accounts_screen.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/presentation/plan_row.dart';
import 'package:fundly/features/plans/presentation/plans_screen.dart';
import 'package:fundly/features/profile/presentation/profile_screen.dart';
import 'package:fundly/features/spending/presentation/spending_screen.dart';

import '../helpers/provider_overrides.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: noAccounts(),
      child: const MaterialApp(home: HomeShell()),
    ),
  );

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectOnlyVisible(Type screen) {
    for (final type in [
      SpendingScreen,
      PlansScreen,
      AccountsScreen,
      ProfileScreen,
    ]) {
      expect(
        find.byType(type),
        type == screen ? findsOneWidget : findsNothing,
        reason: '$type visibility',
      );
    }
  }

  testWidgets('starts on the Spending tab', (tester) async {
    await pumpShell(tester);

    expectOnlyVisible(SpendingScreen);
  });

  testWidgets('switches between all four tabs', (tester) async {
    await pumpShell(tester);

    await tapTab(tester, 'Plans');
    expectOnlyVisible(PlansScreen);

    await tapTab(tester, 'Accounts');
    expectOnlyVisible(AccountsScreen);

    await tapTab(tester, 'Profile');
    expectOnlyVisible(ProfileScreen);

    await tapTab(tester, 'Spending');
    expectOnlyVisible(SpendingScreen);
  });
  testWidgets('signed out, a long press on Profile acts as a tap', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.longPress(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profile'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expectOnlyVisible(ProfileScreen);
  });

  testWidgets(
    'compact layout keeps actions reachable and collapsed plans across tabs',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: fakeAccounts(
            [],
            categories: const [
              Category(id: '1', name: 'Food', kind: CategoryKind.spending),
            ],
          ),
          child: MaterialApp(theme: AppTheme.light(), home: const HomeShell()),
        ),
      );
      await tester.pumpAndSettle();
      final navigation = find.byType(NavigationBar);
      expect(
        tester.getBottomRight(find.byType(FloatingActionButton)).dy,
        lessThan(tester.getTopLeft(navigation).dy),
      );
      await tapTab(tester, 'Accounts');
      expect(
        tester.getBottomRight(find.byType(FloatingActionButton)).dy,
        lessThan(tester.getTopLeft(navigation).dy),
      );
      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'Add account'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AccountFormScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapTab(tester, 'Plans');
      await tester.tap(
        find.descendant(
          of: find.byType(ExpansionTile),
          matching: find.text('Spending'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(PlanRow, 'Food'), findsNothing);
      await tapTab(tester, 'Accounts');
      await tapTab(tester, 'Plans');
      expect(find.widgetWithText(PlanRow, 'Food'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
