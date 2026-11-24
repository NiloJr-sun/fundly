import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/theme/app_palette.dart';
import 'package:fundly/app/theme/app_theme.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/custom_account_type.dart';
import 'package:fundly/features/accounts/presentation/account_display.dart';

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

void main() {
  test('accountTypeLabel', () {
    expect(accountTypeLabel(AccountType.savingsCash), 'Savings / Cash');
    expect(accountTypeLabel(AccountType.credit), 'Credit');
    expect(accountTypeLabel(AccountType.loan), 'Loan');
  });

  test('accountTypeNames lists custom types after their base type', () {
    CustomAccountType custom(String id, String name, AccountType base) =>
        CustomAccountType(
          id: id,
          name: name,
          baseType: base,
          createdAt: DateTime.utc(2026, 11, 17),
        );
    final types = [
      custom('10', 'E-wallet', AccountType.savingsCash),
      custom('11', 'Pay later', AccountType.credit),
      custom('12', 'Debt', AccountType.loan),
    ];

    expect(
      accountTypeNames({AccountType.credit, AccountType.savingsCash}, types),
      'Savings / Cash, E-wallet, Credit or Pay later',
    );
    expect(accountTypeNames({AccountType.loan}, types), 'Loan or Debt');
    expect(accountTypeNames({AccountType.credit}, const []), 'Credit');
    expect(
      accountTypeNames({AccountType.savingsCash, AccountType.credit}, const []),
      'Savings / Cash or Credit',
    );
  });

  test('accountClassLabel', () {
    expect(accountClassLabel(AccountClass.asset), 'Assets');
    expect(accountClassLabel(AccountClass.liability), 'Liabilities');
  });

  test('accountTypeName prefers the custom type name', () {
    final eWallet = CustomAccountType(
      id: '10',
      name: 'E-wallet',
      baseType: AccountType.savingsCash,
      createdAt: DateTime.utc(2026, 11, 17),
    );
    Account wallet({String? customTypeId}) => Account(
      id: '1',
      name: 'GCash',
      type: AccountType.savingsCash,
      openingBalance: const Money.zero('PHP'),
      createdAt: DateTime.utc(2026, 11, 17),
      customTypeId: customTypeId,
    );

    expect(
      accountTypeName(wallet(customTypeId: '10'), {'10': eWallet}),
      'E-wallet',
    );
    expect(accountTypeName(wallet(), {'10': eWallet}), 'Savings / Cash');
    expect(
      accountTypeName(wallet(customTypeId: '10'), const {}),
      'Savings / Cash',
      reason: 'while custom types load',
    );
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
      expect(text.style?.color, AppPalette.classicTeal.light.positive);
      expect(text.style?.fontSize, 20);
    });

    testWidgets('a lighter green in the dark theme', (tester) async {
      final text = await pump(tester, php(1), AppTheme.dark());

      expect(text.style?.color, AppPalette.classicTeal.dark.positive);
    });

    testWidgets('negative and zero keep the default colour', (tester) async {
      for (final balance in [php(-300000), php(0)]) {
        final text = await pump(tester, balance, AppTheme.light());

        expect(text.style?.color, base.color, reason: '$balance');
      }
    });
  });
}
