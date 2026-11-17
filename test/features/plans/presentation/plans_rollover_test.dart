import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/core/time/clock_provider.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/presentation/plans_screen.dart';
import 'package:fundly/features/spending/presentation/spending_providers.dart';

import '../../../helpers/fake_plan_repository.dart';
import '../../../helpers/fake_transaction_repository.dart';
import '../../../helpers/provider_overrides.dart';
import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  late DateTime now;
  late FakePlanRepository planRepository;
  late FakeTransactionRepository transactionRepository;
  final budget = Account(
    id: bdoId,
    name: 'Budget',
    type: accounts[bdoId]!.type,
    openingBalance: php(1000000),
    createdAt: DateTime.utc(2026, 11, 1),
    isBudgetAccount: true,
  );
  setUp(() {
    now = DateTime(2026, 11, 30, 23, 59, 59);
    planRepository = FakePlanRepository();
    transactionRepository = FakeTransactionRepository();
  });

  Future<void> settle(WidgetTester tester) async {
    // Drain provider streams with a small step for the midnight boundary test.
    await tester.pumpAndSettle(const Duration(milliseconds: 1));
  }

  Future<void> pump(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => now),
          ...fakeAccounts(
            [budget],
            categories: [categories[foodId]!],
            transactions: [
              saved(spending(amount: 400000, date: CalendarDate(2026, 11, 30))),
            ],
            plans: [
              MonthlyPlan(
                id: 1,
                month: CalendarMonth(2026, 12),
                categoryId: foodId,
                target: null,
                assigned: php(100000),
                createdAt: DateTime.utc(2026, 11),
                updatedAt: DateTime.utc(2026, 11),
              ),
            ],
            planRepository: planRepository,
            transactionRepository: transactionRepository,
          ),
        ],
        child: const MaterialApp(home: PlansScreen()),
      ),
    );
    await settle(tester);
  }

  String details(WidgetTester tester) {
    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Ready to assign'),
        matching: find.byType(ListTile),
      ),
    );
    return (tile.subtitle! as Text).data!;
  }

  void expectNoWrites() {
    expect(transactionRepository.created, isEmpty);
    expect(transactionRepository.updated, isEmpty);
    expect(transactionRepository.deleted, isEmpty);
    expect(planRepository.saved, isEmpty);
    expect(planRepository.cleared, isEmpty);
  }

  testWidgets(
    'rolls over at local midnight, with no transfer or duplicate money',
    (tester) async {
      await pump(tester);
      expect(find.text('November 2026'), findsOneWidget);
      now = DateTime(2026, 11, 30, 23, 59, 59, 999);
      await tester.pump(const Duration(milliseconds: 999));
      expect(find.text('November 2026'), findsOneWidget);
      now = DateTime(2026, 12, 1);
      await tester.pump(const Duration(milliseconds: 1));
      await settle(tester);
      expect(find.text('December 2026'), findsOneWidget);
      expect(details(tester), contains('Budget balance: ₱6,000.00'));
      expect(
        details(tester),
        contains('Carry over from last month: ₱6,000.00'),
      );
      expect(details(tester), contains('Assigned: ₱1,000.00'));
      expect(find.text('₱5,000.00'), findsOneWidget);
      expectNoWrites();
    },
  );

  testWidgets(
    'resume catches up missed months and repeated resumes are idempotent',
    (tester) async {
      await pump(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = DateTime(2027, 2, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(find.text('February 2027'), findsOneWidget);
      expect(
        details(tester),
        contains('Carry over from last month: ₱6,000.00'),
      );
      expect(details(tester), contains('Assigned: ₱0.00'));
      final before = details(tester);
      for (var i = 0; i < 3; i++) {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await settle(tester);
      }
      expect(details(tester), before);
      expectNoWrites();
    },
  );

  testWidgets('a browsed historical month stays selected after resuming', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Previous month'));
    await settle(tester);
    expect(find.text('October 2026'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2027, 2, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
    expect(find.text('October 2026'), findsOneWidget);
    await tester.tap(find.text('This month'));
    await settle(tester);
    expect(find.text('February 2027'), findsOneWidget);
    expect(details(tester), contains('Carry over from last month: ₱6,000.00'));
  });

  testWidgets('opening after missed months computes carry-over immediately', (
    tester,
  ) async {
    now = DateTime(2027, 3, 8);
    await pump(tester);
    expect(find.text('March 2027'), findsOneWidget);
    expect(details(tester), contains('Carry over from last month: ₱6,000.00'));
    expectNoWrites();
  });

  testWidgets(
    'the device date refreshes even when the app resumes in the same month',
    (tester) async {
      now = DateTime(2026, 11, 16);
      await pump(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = DateTime(2026, 11, 17);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PlansScreen)),
      );
      expect(container.read(todayProvider), CalendarDate(2026, 11, 17));
      expect(find.text('November 2026'), findsOneWidget);
    },
  );

  testWidgets(
    'disposing Plans cancels the midnight timer and lifecycle observer',
    (tester) async {
      await pump(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      now = DateTime(2026, 12, 1);
      await tester.pump(const Duration(seconds: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expectNoWrites();
    },
  );
}
