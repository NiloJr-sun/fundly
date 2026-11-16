import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_balance.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';

void main() {
  test('Phase 1: current balance is the opening balance', () {
    for (final type in AccountType.values) {
      final opening = Money(
        minorUnits: type.isLiability ? -300000 : 1500000,
        currencyCode: 'PHP',
      );
      final account = Account(
        id: 1,
        name: 'Test',
        type: type,
        openingBalance: opening,
        createdAt: DateTime.utc(2026, 11, 16),
      );

      expect(currentBalance(account), opening, reason: type.name);
    }
  });

  group('needsArchiveConfirmation', () {
    Account withBalance(AccountType type, int minorUnits) => Account(
      id: 1,
      name: 'Test',
      type: type,
      openingBalance: Money(minorUnits: minorUnits, currencyCode: 'PHP'),
      createdAt: DateTime.utc(2026, 11, 16),
    );

    test('not needed when the balance is zero', () {
      for (final type in AccountType.values) {
        expect(
          needsArchiveConfirmation(withBalance(type, 0)),
          isFalse,
          reason: type.name,
        );
      }
    });

    test('needed when money is held', () {
      expect(
        needsArchiveConfirmation(withBalance(AccountType.savingsCash, 1)),
        isTrue,
      );
    });

    test('needed when money is owed', () {
      expect(
        needsArchiveConfirmation(withBalance(AccountType.credit, -1)),
        isTrue,
      );
      expect(
        needsArchiveConfirmation(withBalance(AccountType.loan, -500000)),
        isTrue,
      );
    });
  });
}
