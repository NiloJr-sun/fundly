import 'package:flutter_test/flutter_test.dart';
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

  group('formatBalance', () {
    test('asset accounts show the signed amount', () {
      expect(formatBalance(AccountType.savingsCash, php(150000)), '₱1,500.00');
      expect(formatBalance(AccountType.savingsCash, php(-500)), '-₱5.00');
    });

    test('liabilities show money owed as a positive "Owed" amount', () {
      expect(formatBalance(AccountType.credit, php(-300000)), 'Owed ₱3,000.00');
      expect(formatBalance(AccountType.loan, php(-5000000)), 'Owed ₱50,000.00');
    });

    test('an overpaid liability shows as "Credit"', () {
      expect(formatBalance(AccountType.credit, php(2500)), 'Credit ₱25.00');
    });

    test('zero shows plainly for every type', () {
      for (final type in AccountType.values) {
        expect(formatBalance(type, php(0)), '₱0.00', reason: type.name);
      }
    });
  });
}
