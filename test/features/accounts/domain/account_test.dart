import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 16, 8);
  final account = Account(
    id: '7',
    name: 'RCBC Credit Card',
    type: AccountType.credit,
    openingBalance: const Money(minorUnits: -300000, currencyCode: 'PHP'),
    createdAt: createdAt,
  );

  group('Account', () {
    test('is active by default', () {
      expect(account.isArchived, isFalse);
    });

    test('takes its currency from the opening balance', () {
      expect(account.currencyCode, 'PHP');
    });

    test('defaults to PHP (G6)', () {
      expect(Account.defaultCurrency, 'PHP');
    });

    test('equal when all fields match', () {
      expect(account.copyWith(), account);
      expect(account.copyWith().hashCode, account.hashCode);
      expect(account.copyWith(name: 'Other'), isNot(account));
    });
  });

  group('Account.copyWith', () {
    test('changes the editable fields', () {
      const newBalance = Money(minorUnits: -100, currencyCode: 'PHP');
      final edited = account.copyWith(
        name: 'RCBC Visa',
        openingBalance: newBalance,
        isArchived: true,
      );

      expect(edited.name, 'RCBC Visa');
      expect(edited.openingBalance, newBalance);
      expect(edited.isArchived, isTrue);
    });

    test('keeps id, type and createdAt', () {
      final edited = account.copyWith(name: 'Renamed', isArchived: true);

      expect(edited.id, '7');
      expect(edited.type, AccountType.credit);
      expect(edited.createdAt, createdAt);
    });
  });
}
