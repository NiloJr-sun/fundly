import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/categories/data/category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_rules.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';
import 'package:fundly/features/transactions/domain/transaction_validation_exception.dart';

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

Matcher throwsValidation(Set<TransactionValidationError> errors) => throwsA(
  isA<TransactionValidationException>().having(
    (e) => e.errors,
    'errors',
    errors,
  ),
);

void main() {
  late AppDatabase database;
  late TransactionRepository repository;
  late AccountRepository accounts;
  late String bdo, wallet, card, loan;
  late String food, salary;
  var clockTime = DateTime.utc(2026, 11, 16, 9);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    clockTime = DateTime.utc(2026, 11, 16, 9);
    repository = TransactionRepository(database, clock: () => clockTime);
    accounts = AccountRepository(database);

    Future<String> account(String name, AccountType type) async =>
        (await accounts.create(
          name: name,
          type: type,
          enteredOpeningAmount: php(0),
        )).id;
    bdo = await account('BDO Savings', AccountType.savingsCash);
    wallet = await account('Cash Wallet', AccountType.savingsCash);
    card = await account('RCBC Credit', AccountType.credit);
    loan = await account('Car Loan', AccountType.loan);

    final categories = await CategoryRepository(database).watchAll().first;
    food = categories.firstWhere((c) => c.name == 'Food & Groceries').id;
    salary = categories
        .firstWhere((c) => c.kind == CategoryKind.inflow && c.name == 'Salary')
        .id;
  });

  tearDown(() => database.close());

  TransactionDraft spending({
    int amount = 50000,
    String? from,
    CalendarDate? date,
    String payee = 'SM Supermarket',
    String note = '',
  }) => TransactionDraft(
    type: TransactionType.spending,
    amount: php(amount),
    date: date ?? CalendarDate(2026, 11, 16),
    payee: payee,
    categoryId: food,
    sourceAccountId: from ?? bdo,
    note: note,
  );

  TransactionDraft transfer({int amount = 200000, String? from, String? to}) =>
      TransactionDraft(
        type: TransactionType.transfer,
        amount: php(amount),
        date: CalendarDate(2026, 11, 16),
        sourceAccountId: from ?? bdo,
        destinationAccountId: to ?? wallet,
      );

  group('create', () {
    test('saves and returns every field, trimming text', () async {
      final saved = await repository.create(
        spending(payee: '  SM Supermarket ', note: ' weekly groceries '),
      );

      expect(int.parse(saved.id), isPositive);
      expect(saved.type, TransactionType.spending);
      expect(saved.amount, php(50000));
      expect(saved.date, CalendarDate(2026, 11, 16));
      expect(saved.payee, 'SM Supermarket');
      expect(saved.note, 'weekly groceries');
      expect(saved.categoryId, food);
      expect(saved.sourceAccountId, bdo);
      expect(saved.destinationAccountId, isNull);
      expect(saved.createdAt, clockTime);
      expect(saved.updatedAt, clockTime);
      expect(await repository.watchById(saved.id).first, saved);
    });

    test('saves all four types', () async {
      await repository.create(spending(from: card));
      await repository.create(
        TransactionDraft(
          type: TransactionType.inflow,
          amount: php(3000000),
          date: CalendarDate(2026, 11, 15),
          payee: 'Employer',
          categoryId: salary,
          destinationAccountId: bdo,
        ),
      );
      await repository.create(transfer(to: loan));
      await repository.create(
        TransactionDraft(
          type: TransactionType.creditCardPayment,
          amount: php(50000),
          date: CalendarDate(2026, 11, 16),
          sourceAccountId: bdo,
          destinationAccountId: card,
        ),
      );

      final types = (await repository.watchAll().first).map((t) => t.type);
      expect(types, containsAll(TransactionType.values));
    });

    test(
      'Rule 12: rejects invalid drafts with every error, saving nothing',
      () async {
        final draft = TransactionDraft(
          type: TransactionType.spending,
          amount: php(0),
          date: CalendarDate(2026, 11, 16),
          categoryId: salary,
          sourceAccountId: loan,
        );

        await expectLater(
          repository.create(draft),
          throwsValidation({
            TransactionValidationError.amountNotPositive,
            TransactionValidationError.sourceAccountWrongType,
            TransactionValidationError.payeeMissing,
            TransactionValidationError.categoryWrongKind,
          }),
        );
        expect(await repository.watchAll().first, isEmpty);
      },
    );

    test('Rule 7 and G5 are enforced on save', () async {
      await expectLater(
        repository.create(transfer(from: bdo, to: bdo)),
        throwsValidation({TransactionValidationError.sameSourceAndDestination}),
      );
      await expectLater(
        repository.create(transfer(to: card)),
        throwsValidation({
          TransactionValidationError.destinationAccountWrongType,
        }),
      );
    });

    test('G7: rejects an archived account', () async {
      await accounts.setArchived(wallet, archived: true);

      await expectLater(
        repository.create(transfer(to: wallet)),
        throwsValidation({
          TransactionValidationError.destinationAccountArchived,
        }),
      );
    });

    test('rejects unknown accounts and categories', () async {
      await expectLater(
        repository.create(spending(from: '999')),
        throwsValidation({TransactionValidationError.sourceAccountNotFound}),
      );
    });
  });

  group('update', () {
    test('saves changes and bumps updatedAt only', () async {
      final original = await repository.create(spending());
      clockTime = clockTime.add(const Duration(hours: 1));

      final updated = await repository.update(
        original.id,
        spending(amount: 75000, from: wallet, payee: 'Jollibee'),
      );

      expect(updated.id, original.id);
      expect(updated.amount, php(75000));
      expect(updated.sourceAccountId, wallet);
      expect(updated.payee, 'Jollibee');
      expect(updated.createdAt, original.createdAt);
      expect(updated.updatedAt, clockTime);
    });

    test('G8: cannot change the type', () async {
      final original = await repository.create(transfer());

      await expectLater(
        repository.update(
          original.id,
          TransactionDraft(
            type: TransactionType.creditCardPayment,
            amount: php(200000),
            date: CalendarDate(2026, 11, 16),
            sourceAccountId: bdo,
            destinationAccountId: card,
          ),
        ),
        throwsValidation({TransactionValidationError.typeChanged}),
      );
      expect(
        (await repository.watchById(original.id).first)!.type,
        TransactionType.transfer,
      );
    });

    test('G7: may keep an archived account it already uses', () async {
      final original = await repository.create(spending(from: wallet));
      await accounts.setArchived(wallet, archived: true);

      final updated = await repository.update(
        original.id,
        spending(from: wallet, amount: 1),
      );

      expect(updated.amount, php(1));
    });

    test('may keep an archived category it already uses', () async {
      final original = await repository.create(spending());
      await CategoryRepository(database).setArchived(food, archived: true);

      final updated = await repository.update(original.id, spending(amount: 1));

      expect(updated.categoryId, food);
      await expectLater(
        repository.create(spending()),
        throwsValidation({TransactionValidationError.categoryArchived}),
      );
    });

    test('G7: may not move to an archived account', () async {
      final original = await repository.create(spending());
      await accounts.setArchived(wallet, archived: true);

      await expectLater(
        repository.update(original.id, spending(from: wallet)),
        throwsValidation({TransactionValidationError.sourceAccountArchived}),
      );
    });

    test('throws for an unknown id', () {
      expect(repository.update('999', spending()), throwsStateError);
    });
  });

  group('delete', () {
    test('removes the transaction', () async {
      final saved = await repository.create(spending());

      await repository.delete(saved.id);

      expect(await repository.watchById(saved.id).first, isNull);
      expect(await repository.watchAll().first, isEmpty);
    });

    test('throws for an unknown id', () {
      expect(repository.delete('999'), throwsStateError);
    });
  });

  group('watchAll', () {
    test('orders newest first by date, then by id', () async {
      final older = await repository.create(
        spending(date: CalendarDate(2026, 11, 1)),
      );
      final first = await repository.create(spending());
      final second = await repository.create(spending());

      final ids = (await repository.watchAll().first).map((t) => t.id);
      expect(ids, [second.id, first.id, older.id]);
    });

    test('filters by account on either side', () async {
      final fromBdo = await repository.create(spending());
      final intoWallet = await repository.create(transfer());
      await repository.create(spending(from: card));

      final bdoIds = (await repository.watchAll(accountId: bdo).first).map(
        (t) => t.id,
      );
      final walletIds = (await repository.watchAll(accountId: wallet).first)
          .map((t) => t.id);

      expect(bdoIds, unorderedEquals([fromBdo.id, intoWallet.id]));
      expect(walletIds, [intoWallet.id]);
    });

    test('filters by inclusive date range', () async {
      for (final day in [1, 15, 16, 30]) {
        await repository.create(spending(date: CalendarDate(2026, 11, day)));
      }

      final dates =
          (await repository
                  .watchAll(
                    from: CalendarDate(2026, 11, 15),
                    to: CalendarDate(2026, 11, 16),
                  )
                  .first)
              .map((t) => t.date.day);

      expect(dates, [16, 15]);
    });

    test('emits again after create, update and delete', () async {
      final amounts = repository.watchAll().map(
        (list) => list.map((t) => t.amount.minorUnits).toList(),
      );
      final expectation = expectLater(
        amounts,
        emitsInOrder([
          <int>[],
          [100],
          [200],
          <int>[],
        ]),
      );

      final saved = await repository.create(spending(amount: 100));
      await repository.update(saved.id, spending(amount: 200));
      await repository.delete(saved.id);

      await expectation;
    });
  });

  group('database constraints (backstop if Dart checks are bypassed)', () {
    Future<void> insertRaw(String columnsAndValues) => database.customStatement(
      'INSERT INTO transactions '
      '(type, amount_minor, currency_code, date, created_at, updated_at, '
      '$columnsAndValues)',
    );

    String row(String type, int amount, String rest) =>
        'source_account_id, destination_account_id, category_id) VALUES '
        "('$type', $amount, 'PHP', '2026-11-16', 'x', 'x', $rest)";

    test('rejects a non-positive amount', () {
      expect(
        insertRaw(row('spending', 0, '$bdo, NULL, $food')),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects the same source and destination', () {
      expect(
        insertRaw(row('transfer', 100, '$bdo, $bdo, NULL')),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects columns that do not fit the type', () {
      expect(
        insertRaw(row('spending', 100, '$bdo, $wallet, $food')),
        throwsA(isA<Exception>()),
        reason: 'spending has no destination',
      );
      expect(
        insertRaw(row('transfer', 100, '$bdo, $wallet, $food')),
        throwsA(isA<Exception>()),
        reason: 'transfers have no category',
      );
      expect(
        insertRaw(row('inflow', 100, 'NULL, NULL, NULL')),
        throwsA(isA<Exception>()),
        reason: 'inflow needs a destination',
      );
    });

    test('rejects a malformed date', () {
      expect(
        database.customStatement(
          'INSERT INTO transactions (type, amount_minor, currency_code, date, '
          'created_at, updated_at, source_account_id, category_id) VALUES '
          "('spending', 100, 'PHP', '16/11/2026', 'x', 'x', $bdo, $food)",
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects unknown account ids (foreign key)', () {
      expect(
        insertRaw(row('spending', 100, '999, NULL, $food')),
        throwsA(isA<Exception>()),
      );
    });

    test('G7: an account with transactions cannot be deleted', () async {
      await repository.create(spending());

      expect(
        database.customStatement('DELETE FROM accounts WHERE id = $bdo'),
        throwsA(isA<Exception>()),
      );
    });

    test('an account without transactions can be deleted', () async {
      await database.customStatement('DELETE FROM accounts WHERE id = $loan');

      expect(await accounts.watchById(loan).first, isNull);
    });
  });
}
