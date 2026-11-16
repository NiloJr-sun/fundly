import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/categories/presentation/categories_providers.dart';
import 'package:fundly/features/spending/presentation/spending_screen.dart';
import 'package:fundly/features/transactions/presentation/transaction_form_screen.dart';

import '../../helpers/provider_overrides.dart';

void main() {
  testWidgets('Add transaction offers Spending and Inflow and opens the form', (
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

    await tester.tap(find.text('Add transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Spending'), findsWidgets);
    expect(find.text('Inflow'), findsOneWidget);
    expect(find.text('Transfer'), findsNothing);

    await tester.tap(find.text('Inflow'));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionFormScreen), findsOneWidget);
    expect(find.text('New Inflow'), findsOneWidget);
  });
}
