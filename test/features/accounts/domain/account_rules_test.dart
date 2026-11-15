import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_rules.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';

Money php(int minorUnits) =>
    Money(minorUnits: minorUnits, currencyCode: Account.defaultCurrency);

Account accountOf(AccountType type, Money openingBalance) => Account(
  id: 1,
  name: 'Test',
  type: type,
  openingBalance: openingBalance,
  createdAt: DateTime.utc(2026, 11, 16),
);

void main() {
  group('AccountType.isLiability', () {
    test('Savings/Cash is an asset', () {
      expect(AccountType.savingsCash.isLiability, isFalse);
    });

    test('Credit and Loan are liabilities', () {
      expect(AccountType.credit.isLiability, isTrue);
      expect(AccountType.loan.isLiability, isTrue);
    });
  });

  group('validateAccountName', () {
    test('accepts a normal name', () {
      expect(validateAccountName('BDO Savings'), isNull);
    });

    test('rejects empty and whitespace-only names', () {
      expect(validateAccountName(''), AccountNameError.empty);
      expect(validateAccountName('   '), AccountNameError.empty);
      expect(validateAccountName('\t\n'), AccountNameError.empty);
    });

    test('accepts exactly $maxAccountNameLength characters', () {
      expect(validateAccountName('a' * maxAccountNameLength), isNull);
    });

    test('rejects ${maxAccountNameLength + 1} characters', () {
      expect(
        validateAccountName('a' * (maxAccountNameLength + 1)),
        AccountNameError.tooLong,
      );
    });

    test('measures length after trimming', () {
      expect(validateAccountName('  ${'a' * maxAccountNameLength}  '), isNull);
    });
  });

  group('openingBalanceFor (D1 signed balances)', () {
    test('Savings/Cash stores the entered amount as positive', () {
      expect(
        openingBalanceFor(AccountType.savingsCash, php(1500000)),
        php(1500000),
      );
    });

    test('Credit stores the amount owed as negative', () {
      expect(openingBalanceFor(AccountType.credit, php(300000)), php(-300000));
    });

    test('Loan stores the amount owed as negative', () {
      expect(openingBalanceFor(AccountType.loan, php(5000000)), php(-5000000));
    });

    test('zero stays zero for every type', () {
      for (final type in AccountType.values) {
        expect(openingBalanceFor(type, php(0)), php(0), reason: type.name);
      }
    });

    test('keeps the currency', () {
      expect(
        openingBalanceFor(AccountType.credit, php(100)).currencyCode,
        'PHP',
      );
    });

    test('rejects a negative entered amount for every type', () {
      for (final type in AccountType.values) {
        expect(
          () => openingBalanceFor(type, php(-1)),
          throwsArgumentError,
          reason: type.name,
        );
      }
    });
  });

  group('enteredAmountFor', () {
    test('is the reverse of openingBalanceFor for every type', () {
      for (final type in AccountType.values) {
        final entered = php(123450);
        final account = accountOf(type, openingBalanceFor(type, entered));

        expect(enteredAmountFor(account), entered, reason: type.name);
      }
    });

    test('shows a credit balance owed as a positive amount', () {
      final card = accountOf(AccountType.credit, php(-300000));

      expect(enteredAmountFor(card), php(300000));
    });
  });
}
