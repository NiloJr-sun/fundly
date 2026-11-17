import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/presentation/plan_row.dart';
import 'package:fundly/features/plans/presentation/plans_screen.dart';
import 'package:fundly/features/spending/presentation/spending_providers.dart';
import 'package:fundly/features/transactions/presentation/all_transactions_screen.dart';
import 'package:fundly/features/transactions/presentation/transaction_tile.dart';

import '../../../helpers/fake_plan_repository.dart';
import '../../../helpers/provider_overrides.dart';
import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  testWidgets(
    'a liability row can be allocated and Activity shows payments only',
    (tester) async {
      final repository = FakePlanRepository();
      const debt = Category(
        id: 101,
        name: 'RCBC Credit',
        kind: CategoryKind.spending,
        planGroup: PlanGroup.liability,
        linkedAccountId: rcbcCardId,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayProvider.overrideWithValue(CalendarDate(2026, 11, 17)),
            ...fakeAccounts(
              accounts.values.toList(),
              categories: [categories[foodId]!, debt],
              planRepository: repository,
              transactions: [
                saved(cardPayment(amount: 20000), id: 1),
                saved(spending(from: rcbcCardId), id: 2),
              ],
            ),
          ],
          child: const MaterialApp(home: PlansScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Liability'), findsOneWidget);
      expect(find.widgetWithText(PlanRow, 'RCBC Credit'), findsOneWidget);
      await tester.tap(find.byTooltip('Edit RCBC Credit assigned'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Assigned'),
        '500',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repository.saved.single.categoryId, debt.id);
      expect(repository.saved.single.assigned, php(50000));
      await tester.tap(find.byTooltip('Show RCBC Credit transactions'));
      await tester.pumpAndSettle();
      expect(find.byType(AllTransactionsScreen), findsOneWidget);
      expect(find.text('Debt payments'), findsOneWidget);
      final tiles = tester.widgetList<TransactionTile>(
        find.byType(TransactionTile),
      );
      expect(tiles.map((t) => t.transaction.id), [1]);
    },
  );
}
