import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/formatting/money_formatter.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/domain/plan_summary.dart';
import 'package:fundly/features/plans/presentation/plan_details.dart';
import 'package:fundly/features/plans/presentation/ready_to_assign_card.dart';
import 'package:fundly/features/spending/presentation/spending_providers.dart';

import '../../../helpers/provider_overrides.dart';
import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  const cardRow = Category(
    id: '101',
    name: 'RCBC Credit',
    kind: CategoryKind.spending,
    planGroup: PlanGroup.liability,
    linkedAccountId: rcbcCardId,
  );

  Future<void> pumpDetails(WidgetTester tester, CategoryPlanSummary summary) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PlanDetails(summary: summary)),
          ),
        ),
      );

  testWidgets('a card row shows carried over and moved in', (tester) async {
    await pumpDetails(
      tester,
      CategoryPlanSummary(
        category: cardRow,
        target: null,
        assigned: php(100000),
        activity: php(50000),
        hasPlan: true,
        carriedOver: php(30000),
        movedIn: php(20000),
      ),
    );

    expect(find.text('Carried over'), findsOneWidget);
    expect(find.text(MoneyFormatter.format(php(30000))), findsOneWidget);
    expect(find.text('Moved from categories'), findsOneWidget);
    expect(find.text(MoneyFormatter.format(php(20000))), findsOneWidget);
    // ₱1,000 + ₱300 + ₱200 − ₱500.
    expect(find.text(MoneyFormatter.format(php(100000))), findsNWidgets(2));
  });

  testWidgets('other rows do not', (tester) async {
    await pumpDetails(
      tester,
      CategoryPlanSummary(
        category: categories[foodId]!,
        target: null,
        assigned: php(100000),
        activity: php(50000),
        hasPlan: true,
      ),
    );

    expect(find.text('Carried over'), findsNothing);
    expect(find.text('Moved from categories'), findsNothing);
  });

  testWidgets('Ready to assign lists money held for card payments', (
    tester,
  ) async {
    final budget = Account(
      id: bdoId,
      name: 'BDO Savings',
      type: AccountType.savingsCash,
      openingBalance: php(1000000),
      createdAt: DateTime.utc(2026, 11, 1),
      isBudgetAccount: true,
    );
    final december = CalendarMonth(2026, 12);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(CalendarDate(2026, 12, 3)),
          ...fakeAccounts(
            [budget, accounts[rcbcCardId]!],
            categories: [categories[foodId]!, cardRow],
            plans: [
              MonthlyPlan(
                id: 'p1',
                month: CalendarMonth(2026, 11),
                categoryId: foodId,
                target: null,
                assigned: php(500000),
                createdAt: DateTime.utc(2026, 11, 1),
                updatedAt: DateTime.utc(2026, 11, 1),
              ),
            ],
            transactions: [
              saved(
                spending(
                  amount: 50000,
                  from: rcbcCardId,
                  date: CalendarDate(2026, 11, 10),
                ),
              ),
            ],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReadyToAssignCard(month: december),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('− Held for card payments'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('ready-to-assign-amount')),
      findsOneWidget,
    );
    final amount = tester.widget<Text>(
      find.byKey(const ValueKey('ready-to-assign-amount')),
    );
    expect(amount.data, MoneyFormatter.format(php(950000)));
  });
}
