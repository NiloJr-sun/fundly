import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/theme/app_colors.dart';
import 'package:fundly/app/theme/app_theme.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/presentation/account_display.dart';

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

void main() {
  test('accountTypeLabel', () {
    expect(accountTypeLabel(AccountType.savingsCash), 'Savings / Cash');
    expect(accountTypeLabel(AccountType.credit), 'Credit');
    expect(accountTypeLabel(AccountType.loan), 'Loan');
  });

  test('formatBalance shows the signed amount; money owed is negative', () {
    expect(formatBalance(php(150000)), '₱1,500.00');
    expect(formatBalance(php(-300000)), '-₱3,000.00');
    expect(formatBalance(php(0)), '₱0.00');
  });

  group('BalanceText', () {
    const base = TextStyle(fontSize: 20, color: Color(0xFF000001));

    Future<Text> pump(
      WidgetTester tester,
      Money balance,
      ThemeData theme,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: BalanceText(balance, style: base),
        ),
      );
      return tester.widget<Text>(find.byType(Text));
    }

    testWidgets('positive is green', (tester) async {
      final text = await pump(tester, php(150000), AppTheme.light());

      expect(text.data, '₱1,500.00');
      expect(text.style?.color, AppColors.light.positive);
      expect(text.style?.fontSize, 20);
    });

    testWidgets('a lighter green in the dark theme', (tester) async {
      final text = await pump(tester, php(1), AppTheme.dark());

      expect(text.style?.color, AppColors.dark.positive);
    });

    testWidgets('negative and zero keep the default colour', (tester) async {
      for (final balance in [php(-300000), php(0)]) {
        final text = await pump(tester, balance, AppTheme.light());

        expect(text.style?.color, base.color, reason: '$balance');
      }
    });
  });
}
