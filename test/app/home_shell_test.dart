import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/home_shell.dart';
import 'package:fundly/features/accounts/presentation/accounts_screen.dart';
import 'package:fundly/features/plans/presentation/plans_screen.dart';
import 'package:fundly/features/spending/presentation/spending_screen.dart';

import '../helpers/provider_overrides.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: fakeAccounts(),
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
    for (final type in [SpendingScreen, PlansScreen, AccountsScreen]) {
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

  testWidgets('switches between all three tabs', (tester) async {
    await pumpShell(tester);

    await tapTab(tester, 'Plans');
    expectOnlyVisible(PlansScreen);

    await tapTab(tester, 'Account');
    expectOnlyVisible(AccountsScreen);

    await tapTab(tester, 'Spending');
    expectOnlyVisible(SpendingScreen);
  });
}
