import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/theme/app_colors.dart';
import 'package:fundly/app/theme/app_theme.dart';
import 'package:fundly/core/formatting/money_formatter.dart';
import 'package:fundly/features/plans/domain/plan_summary.dart';
import 'package:fundly/features/plans/presentation/plan_details.dart';
import 'package:fundly/features/plans/presentation/plan_row.dart';

import '../../transactions/domain/transaction_fixtures.dart';

void main() {
  for (final dark in [false, true]) {
    for (final (target, assigned, expected) in [
      (10000, 0, 'red'),
      (10000, 5000, 'yellow'),
      (10000, 10000, 'green'),
      (10000, 15000, 'green'),
      (null, 0, 'red'),
      (null, 5000, 'default'),
      (0, 0, 'red'),
    ]) {
      testWidgets(
        'details: Assigned $assigned with target $target is $expected (${dark ? 'dark' : 'light'})',
        (tester) async {
          PlanDetailsAction? chosen;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              home: Scaffold(
                body: PlanDetails(
                  summary: CategoryPlanSummary(
                    category: categories[foodId]!,
                    target: target == null ? null : php(target),
                    assigned: php(assigned),
                    activity: php(123),
                    hasPlan: true,
                  ),
                  onAction: (action) => chosen = action,
                ),
              ),
            ),
          );
          final line = find
              .ancestor(of: find.text('Assigned'), matching: find.byType(Row))
              .first;
          final amount = find.descendant(
            of: line,
            matching: find.text(MoneyFormatter.format(php(assigned))),
          );
          final context = tester.element(amount);
          final colors = Theme.of(context).colorScheme;
          expect(tester.widget<Text>(amount).style?.color, switch (expected) {
            'red' => colors.error,
            'yellow' => AppColors.of(context).warning,
            'green' => AppColors.of(context).positive,
            _ => colors.primary,
          });
          await tester.tap(amount);
          expect(chosen, PlanDetailsAction.editAssigned);
        },
      );
    }
  }

  for (final dark in [false, true]) {
    for (final (target, assigned, activity, expected) in [
      (10000, 10000, 0, 'green'),
      (10000, 10000, 10000, 'green'),
      (10000, 5000, 0, 'yellow'),
      (10000, 5000, 6000, 'red'),
      (null, 5000, 0, 'grey'),
      (null, 0, 100, 'red'),
    ]) {
      testWidgets(
        'pill: target $target, assigned $assigned, activity $activity is '
        '$expected (${dark ? 'dark' : 'light'})',
        (tester) async {
          var tapped = false;
          final summary = CategoryPlanSummary(
            category: categories[foodId]!,
            target: target == null ? null : php(target),
            assigned: php(assigned),
            activity: php(activity),
            hasPlan: true,
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              home: Scaffold(
                body: PlanRow(summary: summary, onTap: () => tapped = true),
              ),
            ),
          );
          final text = find.descendant(
            of: find.byType(AvailablePill),
            matching: find.text(MoneyFormatter.format(summary.available)),
          );
          final context = tester.element(text);
          final appColors = AppColors.of(context);
          expect(tester.widget<Text>(text).style?.color, switch (expected) {
            'green' => appColors.positive,
            'yellow' => appColors.warning,
            'red' => appColors.expense,
            _ => Theme.of(context).colorScheme.onSurface,
          });
          await tester.tap(find.text('Food'));
          expect(tapped, isTrue);
        },
      );
    }
  }
}
