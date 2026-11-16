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
}
