import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/domain/monthly_plan.dart';
import 'package:fundly/features/plans/domain/plan_deletion.dart';
import 'package:fundly/features/plans/domain/plan_validation_exception.dart';
import 'package:fundly/features/plans/presentation/archived_plans_screen.dart';
import 'package:fundly/features/plans/presentation/plan_row.dart';
import 'package:fundly/features/plans/presentation/plans_screen.dart';
import 'package:fundly/features/spending/presentation/spending_providers.dart';
import 'package:fundly/features/transactions/presentation/all_transactions_screen.dart';

import '../../../helpers/fake_plan_repository.dart';
import '../../../helpers/provider_overrides.dart';
import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  late FakePlanRepository repository;
  final month = CalendarMonth(2026, 11);
  Category food({
    bool archived = false,
    bool categoryArchived = false,
    bool deleted = false,
    String? linkedAccountId,
  }) => Category(
    id: foodId,
    name: 'Food',
    kind: CategoryKind.spending,
    isPlanArchived: archived,
    isPlanDeleted: deleted,
    isArchived: categoryArchived,
    linkedAccountId: linkedAccountId,
  );
  setUp(() => repository = FakePlanRepository());

  Future<void> pump(
    WidgetTester tester, {
    List<Category> rows = const [],
    List<MonthlyPlan> plans = const [],
    Stream<List<Category>>? stream,
    bool main = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(CalendarDate(2026, 11, 17)),
          ...fakeAccounts(
            accounts.values.toList(),
            categories: rows,
            categoryStream: stream,
            plans: plans,
            planRepository: repository,
          ),
        ],
        child: MaterialApp(
          home: main ? const PlansScreen() : const ArchivedPlansScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openArchive(WidgetTester tester) async {
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive plan'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'archive and unarchive update the lists without changing the category',
    (tester) async {
      final stream = StreamController<List<Category>>();
      addTearDown(stream.close);
      stream.add([food()]);
      repository.onArchive = (_, archived) =>
          stream.add([food(archived: archived)]);
      await pump(tester, stream: stream.stream, main: true);
      await openArchive(tester);
      expect(
        find.textContaining(
          'no remaining allocation in the current or any future month',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(find.byType(PlanRow), findsNothing);
      expect(find.textContaining('No active plans.'), findsOneWidget);
      expect(find.text('Ready to assign'), findsOneWidget);
      expect(repository.archivedChanges, [
        (categoryId: foodId, archived: true),
      ]);
      await tester.tap(find.byTooltip('Archived plans'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      expect(find.text('Food (archived)'), findsOneWidget);
      expect(find.byTooltip('Edit Food assigned'), findsNothing);
      await tester.tap(find.byTooltip('Show Food transactions'));
      await tester.pumpAndSettle();
      expect(find.byType(AllTransactionsScreen), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unarchive plan'));
      await tester.pumpAndSettle();
      expect(find.text('No archived plans.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(PlanRow, 'Food'), findsOneWidget);
      expect(repository.archivedChanges.last, (
        categoryId: foodId,
        archived: false,
      ));
    },
  );

  testWidgets('explains blocking amounts by month and leaves the plan active', (
    tester,
  ) async {
    repository.archiveBlocked = PlanArchiveBlocked({
      month: php(10000),
      month.next: php(5000),
    });
    await pump(tester, rows: [food()], main: true);
    await openArchive(tester);
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.text('Plan still has allocated money'), findsOneWidget);
    expect(find.textContaining('November 2026: ₱100.00'), findsOneWidget);
    expect(find.textContaining('December 2026: ₱50.00'), findsOneWidget);
    expect(find.textContaining('Reduce Assigned'), findsOneWidget);
    expect(repository.archivedChanges, isEmpty);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PlanRow, 'Food'), findsOneWidget);
  });

  testWidgets('cancelling archive makes no change', (tester) async {
    await pump(tester, rows: [food()], main: true);
    await openArchive(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.archivedChanges, isEmpty);
  });

  testWidgets('archive failures are reported', (tester) async {
    repository.failArchive = true;
    await pump(tester, rows: [food()], main: true);
    await openArchive(tester);
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.text('This plan could not be archived.'), findsOneWidget);
  });

  testWidgets('lists all archived rows, including rows without saved amounts', (
    tester,
  ) async {
    await pump(
      tester,
      rows: [food(archived: true), categories[giftsId]!, categories[salaryId]!],
    );
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Gifts'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);
  });

  testWidgets('history follows month selection and remains read-only', (
    tester,
  ) async {
    await pump(
      tester,
      rows: [food(archived: true)],
      plans: [
        MonthlyPlan(
          id: '1',
          month: month.previous,
          categoryId: foodId,
          target: php(20000),
          assigned: php(10000),
          createdAt: DateTime.utc(2026, 10),
          updatedAt: DateTime.utc(2026, 10),
        ),
      ],
    );
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('₱200.00'), findsOneWidget);
    expect(find.byTooltip('Edit Food target'), findsNothing);
  });

  for (final linked in [false, true]) {
    testWidgets(
      'an archived ${linked ? 'account' : 'category'} must be restored first',
      (tester) async {
        await pump(
          tester,
          rows: [
            food(
              categoryArchived: true,
              linkedAccountId: linked ? rcbcCardId : null,
            ),
          ],
        );
        await tester.tap(find.text('Food'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            linked
                ? 'Unarchive it in the Account tab first.'
                : 'Unarchive it in Categories first.',
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Unarchive plan'),
              )
              .onPressed,
          isNull,
        );
      },
    );
  }

  testWidgets('an unarchive failure keeps the archived detail open', (
    tester,
  ) async {
    repository.failArchive = true;
    await pump(tester, rows: [food(archived: true)]);
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unarchive plan'));
    await tester.pumpAndSettle();
    expect(find.text('This plan could not be unarchived.'), findsOneWidget);
    expect(find.text('Food (archived)'), findsOneWidget);
  });

  testWidgets('permanent delete is below Unarchive and requires confirmation', (
    tester,
  ) async {
    await pump(tester, rows: [food(archived: true)]);
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    final delete = find.widgetWithText(OutlinedButton, 'Delete permanently');
    final unarchive = find.widgetWithText(FilledButton, 'Unarchive plan');
    expect(
      tester.getTopLeft(delete).dy,
      greaterThan(tester.getTopLeft(unarchive).dy),
    );
    expect(
      tester.widget<OutlinedButton>(delete).style!.foregroundColor!.resolve({}),
      Theme.of(tester.element(delete)).colorScheme.error,
    );
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('Delete Food plan?'), findsOneWidget);
    expect(find.textContaining('This cannot be undone.'), findsOneWidget);
    expect(
      find.textContaining('Your category and account are kept.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.deleted, isEmpty);
    expect(find.text('Food (archived)'), findsOneWidget);
  });

  testWidgets(
    'successful deletion removes the archived row while keeping its category',
    (tester) async {
      final stream = StreamController<List<Category>>();
      addTearDown(stream.close);
      var current = food(archived: true);
      stream.add([current]);
      repository.onDelete = (_) {
        current = food(archived: true, deleted: true);
        stream.add([current]);
      };
      await pump(tester, stream: stream.stream);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(repository.deleted, [foodId]);
      expect(current.id, foodId);
      expect(current.isArchived, isFalse);
      expect(find.text('No archived plans.'), findsOneWidget);
      expect(find.text('Food plan deleted.'), findsOneWidget);
    },
  );

  for (final (status, message) in [
    (
      PlanDeletionStatus.hasAssignedMoney,
      'Assigned must be zero in every month',
    ),
    (PlanDeletionStatus.hasActivity, 'spending or payment history'),
  ]) {
    testWidgets('deletion is disabled and explains $status', (tester) async {
      repository.deletionStatus = status;
      await pump(tester, rows: [food(archived: true)]);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Delete permanently'),
            )
            .onPressed,
        isNull,
      );
      expect(find.textContaining(message), findsOneWidget);
    });
  }

  testWidgets(
    'loading eligibility disables deletion and reacts to later data',
    (tester) async {
      final stream = StreamController<PlanDeletionStatus>();
      addTearDown(stream.close);
      repository.deletionStatusStream = stream.stream;
      await pump(tester, rows: [food(archived: true)]);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(OutlinedButton, 'Delete permanently');
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      expect(
        find.text('Checking whether this plan can be deleted…'),
        findsOneWidget,
      );
      stream.add(PlanDeletionStatus.allowed);
      await tester.pumpAndSettle();
      expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
      stream.add(PlanDeletionStatus.hasAssignedMoney);
      await tester.pumpAndSettle();
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    },
  );

  testWidgets('an eligibility error never enables deletion', (tester) async {
    repository.failDeletionCheck = true;
    await pump(tester, rows: [food(archived: true)]);
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Delete permanently'),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.text('Could not check whether this plan can be deleted.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a write-time rejection preserves the plan and explains the rule',
    (tester) async {
      await pump(tester, rows: [food(archived: true)]);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      repository.deleteBlocked = PlanDeletionStatus.hasActivity;
      repository.deletionStatus = PlanDeletionStatus.hasActivity;
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(repository.deleted, isEmpty);
      expect(find.text('Food (archived)'), findsOneWidget);
      expect(find.textContaining('spending or payment history'), findsWidgets);
    },
  );

  testWidgets('a delete failure leaves the detail open', (tester) async {
    repository.failDelete = true;
    await pump(tester, rows: [food(archived: true)]);
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(repository.deleted, isEmpty);
    expect(find.text('This plan could not be deleted.'), findsOneWidget);
    expect(find.text('Food (archived)'), findsOneWidget);
  });

  testWidgets('empty state', (tester) async {
    await pump(tester);
    expect(find.text('No archived plans.'), findsOneWidget);
  });

  testWidgets('loading and error states', (tester) async {
    final stream = StreamController<List<Category>>();
    addTearDown(stream.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(CalendarDate(2026, 11, 17)),
          ...fakeAccounts([], categoryStream: stream.stream),
        ],
        child: const MaterialApp(home: ArchivedPlansScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    stream.addError(StateError('Unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Archived plans could not be loaded.'), findsOneWidget);
  });
}
