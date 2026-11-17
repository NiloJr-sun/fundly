import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_groups.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/custom_account_type.dart';

Account account(int id, AccountType type, {int? customTypeId}) => Account(
  id: id,
  name: 'Account $id',
  type: type,
  openingBalance: const Money.zero('PHP'),
  createdAt: DateTime.utc(2026, 11, 17),
  customTypeId: customTypeId,
);

CustomAccountType customType(int id, String name, AccountType baseType) =>
    CustomAccountType(
      id: id,
      name: name,
      baseType: baseType,
      createdAt: DateTime.utc(2026, 11, 17),
    );

void main() {
  test('AccountType.accountClass', () {
    expect(AccountType.savingsCash.accountClass, AccountClass.asset);
    expect(AccountType.credit.accountClass, AccountClass.liability);
    expect(AccountType.loan.accountClass, AccountClass.liability);
  });

  group('groupAccounts', () {
    final eWallet = customType(10, 'E-wallet', AccountType.savingsCash);
    final payLater = customType(11, 'pay later', AccountType.credit);
    final debt = customType(12, 'Debt', AccountType.loan);

    test('orders assets then liabilities, built-in types before custom', () {
      final groups = groupAccounts(
        [
          account(1, AccountType.savingsCash),
          account(2, AccountType.savingsCash, customTypeId: eWallet.id),
          account(3, AccountType.credit),
          account(4, AccountType.loan),
          account(5, AccountType.credit, customTypeId: payLater.id),
          account(6, AccountType.loan, customTypeId: debt.id),
        ],
        [payLater, eWallet, debt],
      );

      expect(
        [
          for (final group in groups)
            (group.accountClass, group.type, group.customType?.name),
        ],
        [
          (AccountClass.asset, AccountType.savingsCash, null),
          (AccountClass.asset, AccountType.savingsCash, 'E-wallet'),
          (AccountClass.liability, AccountType.credit, null),
          (AccountClass.liability, AccountType.loan, null),
          // Custom types by name ignoring case.
          (AccountClass.liability, AccountType.loan, 'Debt'),
          (AccountClass.liability, AccountType.credit, 'pay later'),
        ],
      );
    });

    test('keeps account order within a group', () {
      final groups = groupAccounts(
        [
          account(3, AccountType.savingsCash, customTypeId: eWallet.id),
          account(1, AccountType.savingsCash, customTypeId: eWallet.id),
        ],
        [eWallet],
      );

      expect(groups.single.accounts.map((a) => a.id), [3, 1]);
    });

    test('leaves out types without accounts', () {
      final groups = groupAccounts(
        [account(1, AccountType.credit)],
        [eWallet, payLater],
      );

      expect(groups, hasLength(1));
      expect(groups.single.type, AccountType.credit);
      expect(groups.single.customType, isNull);
    });

    test('an unknown custom type falls back to the built-in type', () {
      final groups = groupAccounts([
        account(1, AccountType.savingsCash, customTypeId: 99),
      ], const []);

      expect(groups.single.customType, isNull);
      expect(groups.single.accounts.single.id, 1);
    });

    test('no accounts gives no groups', () {
      expect(groupAccounts(const [], [eWallet]), isEmpty);
    });
  });
}
