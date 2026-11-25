import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/categories/presentation/categories_providers.dart';
import 'package:fundly/features/spending/presentation/spending_screen.dart';
import 'package:fundly/features/transactions/presentation/transaction_form_screen.dart';

import '../../helpers/provider_overrides.dart';

void main() {
  testWidgets('Add transaction offers all five kinds and opens the form', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...noAccounts(),
          categoriesByKindProvider.overrideWith(
            (ref, kind) => Stream.value(const []),
          ),
        ],
        child: const MaterialApp(home: SpendingScreen()),
      ),
    );

    // An iPhone-sized screen, so the sheet shows all five kinds.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.tap(find.text('Add transaction'));
    await tester.pumpAndSettle();

    Finder inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(text),
    );
    expect(inSheet('Spending'), findsOneWidget);
    expect(inSheet('Inflow'), findsOneWidget);
    expect(inSheet('Transfer'), findsOneWidget);
    expect(inSheet('Move money between your accounts'), findsOneWidget);
    expect(inSheet('Loan payment'), findsOneWidget);
    expect(inSheet('Pay off a loan'), findsOneWidget);
    expect(inSheet('Credit card payment'), findsOneWidget);

    await tester.tap(inSheet('Inflow'));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionFormScreen), findsOneWidget);
    expect(find.text('New Inflow'), findsOneWidget);
  });
}
