import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/data/custom_account_type_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/custom_account_type.dart';
import 'package:fundly/features/accounts/domain/custom_account_type_validation_exception.dart';

Matcher throwsValidation(CustomAccountTypeValidationError error) => throwsA(
  isA<CustomAccountTypeValidationException>().having(
    (e) => e.error,
    'error',
    error,
  ),
);

void main() {
  late AppDatabase database;
  late CustomAccountTypeRepository repository;
  final fixedNow = DateTime.utc(2026, 11, 17, 9, 30);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = CustomAccountTypeRepository(database, clock: () => fixedNow);
  });

  tearDown(() => database.close());

  Future<CustomAccountType> create(
    String name, [
    AccountType baseType = AccountType.savingsCash,
  ]) => repository.create(name: name, baseType: baseType);

  group('create', () {
    test('stores and returns the trimmed type', () async {
      final type = await create('  Pay later  ', AccountType.credit);

      expect(int.parse(type.id), isPositive);
      expect(type.name, 'Pay later');
      expect(type.baseType, AccountType.credit);
      expect(type.createdAt, fixedNow);
      expect(type.createdAt.isUtc, isTrue);
      expect(await repository.watchAll().first, [type]);
    });

    test('rejects empty and over-long names', () async {
      await expectLater(
        create('   '),
        throwsValidation(CustomAccountTypeValidationError.nameEmpty),
      );
      await expectLater(
        create('a' * 41),
        throwsValidation(CustomAccountTypeValidationError.nameTooLong),
      );
      expect(await create('a' * 40), isNotNull);
    });

    test('rejects a name already used, ignoring case', () async {
      await create('E-wallet');

      await expectLater(
        create('e-WALLET', AccountType.credit),
        throwsValidation(CustomAccountTypeValidationError.nameTaken),
      );
    });

    test('rejects built-in type names, ignoring case', () async {
      for (final name in ['Savings / Cash', 'credit', ' LOAN ']) {
        await expectLater(
          create(name),
          throwsValidation(CustomAccountTypeValidationError.nameTaken),
          reason: name,
        );
      }
      expect(await repository.watchAll().first, isEmpty);
    });
  });

  test('watchAll orders by name ignoring case', () async {
    await create('time deposit');
    await create('E-wallet');
    await create('Pay later', AccountType.credit);

    final names = [
      for (final type in await repository.watchAll().first) type.name,
    ];
    expect(names, ['E-wallet', 'Pay later', 'time deposit']);
  });

  group('update', () {
    test('changes the name and keeps the base type', () async {
      final type = await create('Pay later', AccountType.credit);

      final renamed = await repository.update(type.id, name: ' BNPL ');

      expect(renamed.name, 'BNPL');
      expect(renamed.baseType, AccountType.credit);
      expect(renamed.createdAt, type.createdAt);
    });

    test('allows a case-only change of its own name', () async {
      final type = await create('E-wallet');

      expect(
        (await repository.update(type.id, name: 'E-Wallet')).name,
        'E-Wallet',
      );
    });

    test('rejects names of other types and built-in types', () async {
      await create('E-wallet');
      final type = await create('Pay later', AccountType.credit);

      await expectLater(
        repository.update(type.id, name: 'e-wallet'),
        throwsValidation(CustomAccountTypeValidationError.nameTaken),
      );
      await expectLater(
        repository.update(type.id, name: 'Credit'),
        throwsValidation(CustomAccountTypeValidationError.nameTaken),
      );
    });

    test('throws StateError for a missing type', () async {
      await expectLater(
        repository.update('42', name: 'Name'),
        throwsStateError,
      );
    });

    test('changes the base type while no account uses it', () async {
      final type = await create('Pay later', AccountType.credit);

      final asLoan = await repository.update(
        type.id,
        baseType: AccountType.loan,
      );
      expect(asLoan.baseType, AccountType.loan);
      expect(asLoan.name, 'Pay later');

      final asAsset = await repository.update(
        type.id,
        name: 'Savings jar',
        baseType: AccountType.savingsCash,
      );
      expect(asAsset.name, 'Savings jar');
      expect(asAsset.baseType, AccountType.savingsCash);
      expect(await repository.watchAll().first, [asAsset]);
    });

    test('refuses a base type change while any account uses it', () async {
      final type = await create('E-wallet');
      final accounts = AccountRepository(database);
      final account = await accounts.create(
        name: 'GCash',
        type: AccountType.savingsCash,
        enteredOpeningAmount: const Money.zero('PHP'),
        customTypeId: type.id,
      );
      await accounts.setArchived(account.id, archived: true);

      await expectLater(
        repository.update(
          type.id,
          name: 'Renamed',
          baseType: AccountType.credit,
        ),
        throwsValidation(CustomAccountTypeValidationError.baseTypeInUse),
      );
      expect(await repository.watchAll().first, [
        type,
      ], reason: 'nothing changed, not even the name');
    });

    test('a type in use can still be renamed, keeping its base', () async {
      final type = await create('E-wallet');
      await AccountRepository(database).create(
        name: 'GCash',
        type: AccountType.savingsCash,
        enteredOpeningAmount: const Money.zero('PHP'),
        customTypeId: type.id,
      );

      final renamed = await repository.update(
        type.id,
        name: 'Digital wallet',
        baseType: AccountType.savingsCash,
      );

      expect(renamed.name, 'Digital wallet');
      expect(renamed.baseType, AccountType.savingsCash);
    });
  });

  group('delete', () {
    test('removes an unused type', () async {
      final type = await create('E-wallet');

      await repository.delete(type.id);

      expect(await repository.watchAll().first, isEmpty);
    });

    test('refuses while any account uses it, even archived', () async {
      final type = await create('E-wallet');
      final accounts = AccountRepository(database);
      final account = await accounts.create(
        name: 'GCash',
        type: AccountType.savingsCash,
        enteredOpeningAmount: const Money.zero('PHP'),
        customTypeId: type.id,
      );
      await accounts.setArchived(account.id, archived: true);

      await expectLater(
        repository.delete(type.id),
        throwsValidation(CustomAccountTypeValidationError.inUse),
      );
      expect(await repository.watchAll().first, [type]);
    });

    test('throws StateError for a missing type', () async {
      await expectLater(repository.delete('42'), throwsStateError);
    });
  });

  group('database constraints (backstop if Dart checks are bypassed)', () {
    Future<int> insertRaw(String name) => database
        .into(database.customAccountTypes)
        .insert(
          CustomAccountTypesCompanion.insert(
            name: name,
            baseType: AccountType.loan,
            createdAt: fixedNow,
          ),
        );

    test('rejects duplicate names ignoring ASCII case', () async {
      await insertRaw('Debt');

      expect(insertRaw('DEBT'), throwsA(isA<Exception>()));
    });

    test('rejects empty and over-long names', () {
      expect(insertRaw(''), throwsA(isA<Exception>()));
      expect(insertRaw('a' * 41), throwsA(isA<Exception>()));
    });

    test('rejects an unknown base type', () {
      expect(
        database.customStatement(
          'INSERT INTO custom_account_types (name, base_type, created_at) '
          "VALUES ('X', 'investment', 0)",
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
