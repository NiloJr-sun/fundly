import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/theme/app_colors.dart';
import 'package:fundly/app/theme/app_theme.dart';
import 'package:fundly/core/formatting/money_formatter.dart';
import 'package:fundly/features/plans/domain/plan_summary.dart';
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
        'Assigned $assigned with target $target is $expected (${dark ? 'dark' : 'light'})',
        (tester) async {
          var edited = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              home: Scaffold(
                body: PlanRow(
                  summary: CategoryPlanSummary(
                    category: categories[foodId]!,
                    target: target == null ? null : php(target),
                    assigned: php(assigned),
                    activity: php(123),
                    hasPlan: true,
                  ),
                  onEdit: (_) => edited = true,
                  onActivityTap: () {},
                ),
              ),
            ),
          );
          final column = find
              .ancestor(
                of: find.text('Assigned'),
                matching: find.byType(Column),
              )
              .first;
          final amount = find.descendant(
            of: column,
            matching: find.text(MoneyFormatter.format(php(assigned))),
          );
          final context = tester.element(amount);
          final colors = Theme.of(context).colorScheme;
          expect(tester.widget<Text>(amount).style?.color, switch (expected) {
            'red' => colors.error,
            'yellow' => AppColors.of(context).warning,
            'green' => AppColors.of(context).positive,
            _ => colors.onSurface,
          });
          await tester.tap(amount);
          expect(edited, isTrue);
        },
      );
    }
  }
}
