import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/data/custom_bank_repository.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/custom_bank.dart';

// Banks on accounts, signed out (docs/BANKS_PLAN.md, B.2). The synchronized
// store's versions are in test/core/sync/synced_writes_test.dart.

Matcher throwsValidation(CustomBankValidationError error) => throwsA(
  isA<CustomBankValidationException>().having((e) => e.error, 'error', error),
);

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

void main() {
  late AppDatabase database;
  late CustomBankRepository banks;
  late AccountRepository accounts;
  final fixedNow = DateTime.utc(2026, 11, 25, 9, 30);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    banks = CustomBankRepository(database, clock: () => fixedNow);
    accounts = AccountRepository(database, clock: () => fixedNow);
  });

  tearDown(() => database.close());

  Future<Account> savings(
    String name, {
    String? bankKey,
    String? customBankId,
  }) => accounts.create(
    name: name,
    type: AccountType.savingsCash,
    enteredOpeningAmount: php(100000),
    bankKey: bankKey,
    customBankId: customBankId,
  );

  group('custom banks', () {
    test('stores and returns the trimmed bank', () async {
      final bank = await banks.create('  Town Coop  ');

      expect(int.parse(bank.id), isPositive);
      expect(bank.name, 'Town Coop');
      expect(bank.createdAt, fixedNow);
      expect(await banks.watchAll().first, [bank]);
    });

    test('rejects empty, over-long and taken names', () async {
      await banks.create('Town Coop');

      await expectLater(
        banks.create('   '),
        throwsValidation(CustomBankValidationError.nameEmpty),
      );
      await expectLater(
        banks.create('x' * 41),
        throwsValidation(CustomBankValidationError.nameTooLong),
      );
      await expectLater(
        banks.create('TOWN COOP'),
        throwsValidation(CustomBankValidationError.nameTaken),
      );
    });

    test('rejects built-in bank names, ignoring case', () async {
      for (final name in ['BDO', 'gcash', ' Land Bank ']) {
        await expectLater(
          banks.create(name),
          throwsValidation(CustomBankValidationError.nameTaken),
          reason: name,
        );
      }
    });

    test('watchAll orders by name ignoring case', () async {
      await banks.create('zeta Rural Bank');
      await banks.create('Alpha Coop');
      await banks.create('beta Lending');

      expect(
        [for (final bank in await banks.watchAll().first) bank.name],
        ['Alpha Coop', 'beta Lending', 'zeta Rural Bank'],
      );
    });

    test('renames, allowing a case-only change of its own name', () async {
      final bank = await banks.create('Town Coop');
      await banks.create('Credit Union');

      expect((await banks.rename(bank.id, 'TOWN coop')).name, 'TOWN coop');
      await expectLater(
        banks.rename(bank.id, 'credit union'),
        throwsValidation(CustomBankValidationError.nameTaken),
      );
      await expectLater(
        banks.rename(bank.id, 'Maya'),
        throwsValidation(CustomBankValidationError.nameTaken),
      );
      await expectLater(banks.rename('99', 'Other'), throwsStateError);
    });

    test('deletes only while no account, even archived, uses it', () async {
      final bank = await banks.create('Town Coop');
      final account = await savings('Coop Savings', customBankId: bank.id);
      await accounts.setArchived(account.id, archived: true);

      await expectLater(
        banks.delete(bank.id),
        throwsValidation(CustomBankValidationError.inUse),
      );

      await accounts.update(
        account.id,
        bank: (bankKey: null, customBankId: null),
      );
      await banks.delete(bank.id);
      expect(await banks.watchAll().first, isEmpty);
      await expectLater(banks.delete(bank.id), throwsStateError);
    });
  });

  group("an account's bank", () {
    test('an account has a built-in bank, a custom bank, or none', () async {
      final coop = await banks.create('Town Coop');
      final bdo = await savings('BDO Savings', bankKey: 'bdo');
      final coopSavings = await savings('Coop Savings', customBankId: coop.id);
      final wallet = await savings('Cash wallet');

      expect(bdo.bank, (bankKey: 'bdo', customBankId: null));
      expect(coopSavings.bank, (bankKey: null, customBankId: coop.id));
      expect(wallet.bank, (bankKey: null, customBankId: null));
      // Read back from the database too.
      expect(await accounts.watchById(coopSavings.id).first, coopSavings);
    });

    test('every account type can have a bank', () async {
      final card = await accounts.create(
        name: 'BPI Card',
        type: AccountType.credit,
        enteredOpeningAmount: php(0),
        bankKey: 'bpi',
      );
      final loan = await accounts.create(
        name: 'Landbank Loan',
        type: AccountType.loan,
        enteredOpeningAmount: php(500000),
        bankKey: 'landbank',
      );

      expect(card.bankKey, 'bpi');
      expect(loan.bankKey, 'landbank');
    });

    test(
      'refuses two banks, an unknown key or a missing custom bank',
      () async {
        final coop = await banks.create('Town Coop');

        await expectLater(
          savings('Both', bankKey: 'bdo', customBankId: coop.id),
          throwsArgumentError,
        );
        await expectLater(
          savings('Komo', bankKey: 'komo'),
          throwsArgumentError,
        );
        await expectLater(
          savings('Gone', customBankId: '99'),
          throwsArgumentError,
        );
        expect(await accounts.watchAll().first, isEmpty);
      },
    );

    test('an edit switches, clears or keeps the bank', () async {
      final coop = await banks.create('Town Coop');
      final account = await savings('Savings', bankKey: 'bdo');

      final renamed = await accounts.update(account.id, name: 'My Savings');
      expect(renamed.bank, (bankKey: 'bdo', customBankId: null));

      final switched = await accounts.update(
        account.id,
        bank: (bankKey: null, customBankId: coop.id),
      );
      expect(switched.bank, (bankKey: null, customBankId: coop.id));

      final cleared = await accounts.update(
        account.id,
        bank: (bankKey: null, customBankId: null),
      );
      expect(cleared.bank, (bankKey: null, customBankId: null));

      await expectLater(
        accounts.update(
          account.id,
          bank: (bankKey: 'unknown', customBankId: null),
        ),
        throwsArgumentError,
      );
    });

    test('a bank is a label: the opening balance is unchanged', () async {
      final account = await savings('Savings');

      final updated = await accounts.update(
        account.id,
        bank: (bankKey: 'gcash', customBankId: null),
      );

      expect(updated.openingBalance, account.openingBalance);
      expect(updated.type, account.type);
    });
  });

  group('database constraints (backstop if Dart checks are bypassed)', () {
    test('an account cannot have two banks or a malformed key', () async {
      final coop = await banks.create('Town Coop');
      final account = await savings('Savings', bankKey: 'bdo');

      await expectLater(
        database.customStatement(
          'UPDATE accounts SET custom_bank_id = ${coop.id} '
          'WHERE id = ${account.id}',
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        database.customStatement(
          "UPDATE accounts SET bank_key = 'Bdo' WHERE id = ${account.id}",
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('a custom bank in use cannot be deleted', () async {
      final coop = await banks.create('Town Coop');
      await savings('Savings', customBankId: coop.id);

      await expectLater(
        database.customStatement('DELETE FROM custom_banks'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
