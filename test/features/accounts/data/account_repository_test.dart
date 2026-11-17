import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/data/custom_account_type_repository.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/account_validation_exception.dart';

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

Matcher throwsValidation(AccountValidationError error) => throwsA(
  isA<AccountValidationException>().having((e) => e.error, 'error', error),
);

void main() {
  late AppDatabase database;
  late AccountRepository repository;
  final fixedNow = DateTime.utc(2026, 11, 16, 9, 30);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = AccountRepository(database, clock: () => fixedNow);
  });

  tearDown(() => database.close());

  Future<Account> create(
    String name, {
    AccountType type = AccountType.savingsCash,
    int entered = 0,
  }) => repository.create(
    name: name,
    type: type,
    enteredOpeningAmount: php(entered),
  );

  group('create', () {
    test('stores and returns the account', () async {
      final account = await create('  BDO Savings  ', entered: 1500000);

      expect(account.id, isPositive);
      expect(account.name, 'BDO Savings');
      expect(account.type, AccountType.savingsCash);
      expect(account.openingBalance, php(1500000));
      expect(account.createdAt, fixedNow);
      expect(account.createdAt.isUtc, isTrue);
      expect(account.isArchived, isFalse);
      expect(await repository.watchById(account.id).first, account);
    });

    test('stores liability opening balances as negative (D1)', () async {
      final card = await create(
        'RCBC Credit',
        type: AccountType.credit,
        entered: 300000,
      );
      final loan = await create(
        'Car Loan',
        type: AccountType.loan,
        entered: 5000000,
      );

      expect(card.openingBalance, php(-300000));
      expect(loan.openingBalance, php(-5000000));
    });

    test('accepts a zero opening balance', () async {
      final account = await create('Cash Wallet');

      expect(account.openingBalance, php(0));
    });

    test('rejects an empty name', () {
      expect(create('   '), throwsValidation(AccountValidationError.nameEmpty));
    });

    test('rejects a name over 40 characters', () {
      expect(
        create('a' * 41),
        throwsValidation(AccountValidationError.nameTooLong),
      );
    });

    test('rejects a duplicate name, ignoring case and spaces', () async {
      await create('BDO Savings');

      expect(
        create(' bdo SAVINGS '),
        throwsValidation(AccountValidationError.nameTaken),
      );
    });

    test('rejects a name used by an archived account', () async {
      final old = await create('Old Wallet');
      await (database.update(database.accounts)
            ..where((a) => a.id.equals(old.id)))
          .write(const AccountsCompanion(isArchived: Value(true)));

      expect(
        create('Old Wallet'),
        throwsValidation(AccountValidationError.nameTaken),
      );
    });

    test('rejects a negative opening amount', () {
      expect(
        repository.create(
          name: 'Overdrawn',
          type: AccountType.savingsCash,
          enteredOpeningAmount: php(-1),
        ),
        throwsValidation(AccountValidationError.negativeOpeningBalance),
      );
    });

    test('rejects a non-PHP currency (G6)', () {
      expect(
        repository.create(
          name: 'Dollar Account',
          type: AccountType.savingsCash,
          enteredOpeningAmount: const Money(
            minorUnits: 100,
            currencyCode: 'USD',
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('update', () {
    test('renames an account', () async {
      final account = await create('BDO');

      final updated = await repository.update(
        account.id,
        name: ' BDO Savings ',
      );

      expect(updated.name, 'BDO Savings');
      expect(updated.openingBalance, account.openingBalance);
    });

    test('allows changing only the case of its own name', () async {
      final account = await create('bdo savings');

      final updated = await repository.update(account.id, name: 'BDO Savings');

      expect(updated.name, 'BDO Savings');
    });

    test("rejects another account's name", () async {
      await create('BDO Savings');
      final other = await create('Cash Wallet');

      expect(
        repository.update(other.id, name: 'bdo savings'),
        throwsValidation(AccountValidationError.nameTaken),
      );
    });

    test('changes the opening balance using the account type sign', () async {
      final card = await create(
        'RCBC Credit',
        type: AccountType.credit,
        entered: 300000,
      );

      final updated = await repository.update(
        card.id,
        enteredOpeningAmount: php(450000),
      );

      expect(updated.openingBalance, php(-450000));
    });

    test('keeps type, createdAt and archive status', () async {
      final loan = await create('Car Loan', type: AccountType.loan);

      final updated = await repository.update(loan.id, name: 'Auto Loan');

      expect(updated.type, AccountType.loan);
      expect(updated.createdAt, loan.createdAt);
      expect(updated.isArchived, isFalse);
    });

    test('validates like create', () async {
      final account = await create('BDO');

      expect(
        repository.update(account.id, name: ''),
        throwsValidation(AccountValidationError.nameEmpty),
      );
      expect(
        repository.update(account.id, enteredOpeningAmount: php(-5)),
        throwsValidation(AccountValidationError.negativeOpeningBalance),
      );
    });

    test('throws for an unknown id', () {
      expect(repository.update(999, name: 'Ghost'), throwsStateError);
    });
  });

  group('watchAll', () {
    test('orders by type (Savings/Cash, Credit, Loan) then name', () async {
      await create('Car Loan', type: AccountType.loan);
      await create('rcbc Credit', type: AccountType.credit);
      await create('Cash Wallet');
      await create('BPI Credit', type: AccountType.credit);
      await create('bdo Savings');

      final names = (await repository.watchAll().first).map((a) => a.name);

      expect(names, [
        'bdo Savings',
        'Cash Wallet',
        'BPI Credit',
        'rcbc Credit',
        'Car Loan',
      ]);
    });

    test('hides archived accounts unless asked', () async {
      await create('Active');
      final archived = await create('Archived');
      await (database.update(database.accounts)
            ..where((a) => a.id.equals(archived.id)))
          .write(const AccountsCompanion(isArchived: Value(true)));

      final visible = await repository.watchAll().first;
      final everything = await repository.watchAll(includeArchived: true).first;

      expect(visible.map((a) => a.name), ['Active']);
      expect(everything.map((a) => a.name), ['Active', 'Archived']);
    });

    test('emits again when accounts change', () async {
      final names = repository.watchAll().map(
        (accounts) => accounts.map((a) => a.name).toList(),
      );
      final expectation = expectLater(
        names,
        emitsInOrder([
          <String>[],
          ['BDO'],
          ['BDO Savings'],
        ]),
      );

      final account = await create('BDO');
      await repository.update(account.id, name: 'BDO Savings');

      await expectation;
    });
  });

  group('setArchived', () {
    test('hides the account from the active list and keeps it', () async {
      final account = await create('Old Wallet', entered: 5000);

      await repository.setArchived(account.id, archived: true);

      expect(await repository.watchAll().first, isEmpty);
      final archived = await repository.watchById(account.id).first;
      expect(archived!.isArchived, isTrue);
      expect(archived.openingBalance, php(5000));
    });

    test('unarchiving restores it to the active list', () async {
      final account = await create('Old Wallet');
      await repository.setArchived(account.id, archived: true);

      await repository.setArchived(account.id, archived: false);

      expect((await repository.watchAll().first).single.id, account.id);
    });

    test('throws for an unknown id', () {
      expect(repository.setArchived(999, archived: true), throwsStateError);
    });
  });

  group('watchById', () {
    test('emits null for a missing account', () async {
      expect(await repository.watchById(42).first, isNull);
    });
  });

  group('custom types', () {
    late CustomAccountTypeRepository types;

    setUp(() => types = CustomAccountTypeRepository(database));

    test('new accounts have no custom type by default', () async {
      expect((await create('BDO Savings')).customTypeId, isNull);
    });

    test('create stores a custom type with the same base type', () async {
      final eWallet = await types.create(
        name: 'E-wallet',
        baseType: AccountType.savingsCash,
      );

      final account = await repository.create(
        name: 'GCash',
        type: AccountType.savingsCash,
        enteredOpeningAmount: php(120000),
        customTypeId: eWallet.id,
      );

      expect(account.customTypeId, eWallet.id);
      expect(account.openingBalance, php(120000));
      expect(await repository.watchById(account.id).first, account);
    });

    test('a liability custom type keeps the liability sign (D1)', () async {
      final payLater = await types.create(
        name: 'Pay later',
        baseType: AccountType.credit,
      );

      final account = await repository.create(
        name: 'SPayLater',
        type: AccountType.credit,
        enteredOpeningAmount: php(50000),
        customTypeId: payLater.id,
      );

      expect(account.openingBalance, php(-50000));
    });

    test('create rejects a custom type with another base type', () async {
      final payLater = await types.create(
        name: 'Pay later',
        baseType: AccountType.credit,
      );

      await expectLater(
        repository.create(
          name: 'GCash',
          type: AccountType.savingsCash,
          enteredOpeningAmount: php(0),
          customTypeId: payLater.id,
        ),
        throwsArgumentError,
      );
      expect(await repository.watchAll().first, isEmpty);
    });

    test('create rejects a missing custom type', () async {
      await expectLater(
        repository.create(
          name: 'GCash',
          type: AccountType.savingsCash,
          enteredOpeningAmount: php(0),
          customTypeId: 99,
        ),
        throwsArgumentError,
      );
    });

    test('update moves between types with the same base type', () async {
      final eWallet = await types.create(
        name: 'E-wallet',
        baseType: AccountType.savingsCash,
      );
      final account = await create('GCash');

      final moved = await repository.update(
        account.id,
        customType: (id: eWallet.id),
      );
      expect(moved.customTypeId, eWallet.id);

      final renamed = await repository.update(account.id, name: 'Maya');
      expect(renamed.customTypeId, eWallet.id, reason: 'kept when omitted');

      final back = await repository.update(account.id, customType: (id: null));
      expect(back.customTypeId, isNull);
      expect(back.type, AccountType.savingsCash);
    });

    test('update rejects a custom type with another base type', () async {
      final loanLike = await types.create(
        name: 'Personal debt',
        baseType: AccountType.loan,
      );
      final card = await create(
        'RCBC Credit',
        type: AccountType.credit,
        entered: 300000,
      );

      await expectLater(
        repository.update(card.id, customType: (id: loanLike.id)),
        throwsArgumentError,
      );
      expect((await repository.watchById(card.id).first)!.customTypeId, isNull);
    });

    test('the database refuses to delete a custom type in use', () async {
      final eWallet = await types.create(
        name: 'E-wallet',
        baseType: AccountType.savingsCash,
      );
      await repository.create(
        name: 'GCash',
        type: AccountType.savingsCash,
        enteredOpeningAmount: php(0),
        customTypeId: eWallet.id,
      );

      await expectLater(
        (database.delete(
          database.customAccountTypes,
        )..where((type) => type.id.equals(eWallet.id))).go(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('database constraints (backstop if Dart checks are bypassed)', () {
    Future<int> insertRaw({
      String name = 'Raw',
      AccountType type = AccountType.savingsCash,
      int opening = 0,
    }) => database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: name,
            type: type,
            openingBalanceMinor: opening,
            createdAt: fixedNow,
          ),
        );

    test('rejects a negative opening balance on Savings/Cash', () {
      expect(insertRaw(opening: -1), throwsA(isA<Exception>()));
    });

    test('rejects a positive opening balance on Credit and Loan', () {
      expect(
        insertRaw(type: AccountType.credit, opening: 1),
        throwsA(isA<Exception>()),
      );
      expect(
        insertRaw(name: 'Raw 2', type: AccountType.loan, opening: 1),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects duplicate names ignoring ASCII case', () async {
      await insertRaw(name: 'BDO');

      expect(insertRaw(name: 'bdo'), throwsA(isA<Exception>()));
    });

    test('rejects empty and over-long names', () {
      expect(insertRaw(name: ''), throwsA(isA<Exception>()));
      expect(insertRaw(name: 'a' * 41), throwsA(isA<Exception>()));
    });

    test('accepts valid rows', () async {
      expect(await insertRaw(type: AccountType.credit, opening: -100), 1);
    });
  });
}
