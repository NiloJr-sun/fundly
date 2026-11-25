import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/date_range.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/data/card_funding.dart';
import 'package:fundly/features/accounts/data/synced_account_repository.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_balance.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/account_validation_exception.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/spending/domain/period_summary.dart';
import 'package:fundly/features/transactions/data/synced_transaction_repository.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';
import 'package:fundly/features/transactions/domain/transaction_validation_exception.dart';

import '../../../helpers/fake_synced_store.dart';

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

DateTime _clock() => DateTime(2026, 11, 26, 15, 20);

void main() {
  group('local store', () {
    late AppDatabase database;
    late AccountRepository accounts;
    late TransactionRepository transactions;
    late CardFunding funding;
    late Account card;
    late Account savings;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      accounts = AccountRepository(database);
      transactions = TransactionRepository(database);
      funding = CardFunding(
        accounts: accounts,
        transactions: transactions,
        atomically: database.transaction,
        clock: _clock,
      );
      card = await accounts.create(
        name: 'Metrobank CC',
        type: AccountType.credit,
        enteredOpeningAmount: php(0),
      );
      savings = await accounts.create(
        name: 'BDO Savings',
        type: AccountType.savingsCash,
        enteredOpeningAmount: php(500000),
      );
    });

    tearDown(() => database.close());

    Future<Map<String, Money>> balances() async => balancesFor(
      await accounts.watchAll(includeArchived: true).first,
      await transactions.watchAll().first,
    );

    test(
      'create: zero opening balance and a Transfer from the card dated today',
      () async {
        final created = await funding.create(
          name: 'Credit Cc',
          type: AccountType.savingsCash,
          amount: php(100000),
          cardId: card.id,
        );

        expect(created.openingBalance, php(0));
        final recorded = await transactions.watchAll().first;
        expect(recorded, hasLength(1));
        final transfer = recorded.single;
        expect(transfer.type, TransactionType.transfer);
        expect(transfer.amount, php(100000));
        expect(transfer.sourceAccountId, card.id);
        expect(transfer.destinationAccountId, created.id);
        expect(transfer.date, CalendarDate(2026, 11, 26));
        expect(transfer.note, cardFundingNote);

        final result = await balances();
        expect(result[created.id], php(100000));
        expect(result[card.id], php(-100000), reason: 'owed rises');
        expect(result[savings.id], php(500000));
      },
    );

    test('spending from the account counts once; the Transfer never', () async {
      final created = await funding.create(
        name: 'Credit Cc',
        type: AccountType.savingsCash,
        amount: php(100000),
        cardId: card.id,
      );
      final totals = periodTotals(
        await transactions.watchAll().first,
        DateRange.monthOf(CalendarDate(2026, 11, 26)),
      );
      expect(totals.spending, php(0));
      expect(totals.inflow, php(0));
      expect((await balances())[created.id], php(100000));
    });

    test('a refused Transfer leaves no account behind', () async {
      // Savings/Cash is not a card: a Transfer from it to a new account is
      // allowed, so use an archived card, which takes no new transactions.
      await accounts.setArchived(card.id, archived: true);

      await expectLater(
        funding.create(
          name: 'Credit Cc',
          type: AccountType.savingsCash,
          amount: php(100000),
          cardId: card.id,
        ),
        throwsA(isA<TransactionValidationException>()),
      );
      final names = (await accounts.watchAll(includeArchived: true).first).map(
        (account) => account.name,
      );
      expect(names, isNot(contains('Credit Cc')));
      expect(await transactions.watchAll().first, isEmpty);
    });

    test('a refused account name records no Transfer', () async {
      await expectLater(
        funding.create(
          name: 'bdo savings',
          type: AccountType.savingsCash,
          amount: php(100000),
          cardId: card.id,
        ),
        throwsA(isA<AccountValidationException>()),
      );
      expect(await transactions.watchAll().first, isEmpty);
    });

    test('the source must be a credit account', () async {
      final loan = await accounts.create(
        name: 'Car loan',
        type: AccountType.loan,
        enteredOpeningAmount: php(0),
      );
      await expectLater(
        funding.create(
          name: 'Credit Cc',
          type: AccountType.savingsCash,
          amount: php(100000),
          cardId: loan.id,
        ),
        throwsA(isA<TransactionValidationException>()),
      );
      expect(await transactions.watchAll().first, isEmpty);
    });

    test('refuses a liability account and a zero amount', () async {
      expect(
        () => funding.create(
          name: 'Credit Cc',
          type: AccountType.credit,
          amount: php(100000),
          cardId: card.id,
        ),
        throwsArgumentError,
      );
      expect(
        () => funding.create(
          name: 'Credit Cc',
          type: AccountType.savingsCash,
          amount: php(0),
          cardId: card.id,
        ),
        throwsArgumentError,
      );
    });

    test(
      'update: opening balance becomes zero and moves to a Transfer',
      () async {
        final existing = await accounts.create(
          name: 'Credit Cc',
          type: AccountType.savingsCash,
          enteredOpeningAmount: php(100000),
        );
        await transactions.watchAll().first;

        final updated = await funding.update(
          existing.id,
          name: 'Credit Cc',
          amount: php(100000),
          cardId: card.id,
        );

        expect(updated.openingBalance, php(0));
        final result = await balances();
        expect(result[existing.id], php(100000), reason: 'balance unchanged');
        expect(result[card.id], php(-100000));
      },
    );

    test('update: a refused Transfer keeps the opening balance', () async {
      final existing = await accounts.create(
        name: 'Credit Cc',
        type: AccountType.savingsCash,
        enteredOpeningAmount: php(100000),
      );
      await accounts.setArchived(card.id, archived: true);

      await expectLater(
        funding.update(existing.id, amount: php(100000), cardId: card.id),
        throwsA(isA<TransactionValidationException>()),
      );
      final reloaded = await accounts.watchById(existing.id).first;
      expect(reloaded!.openingBalance, php(100000));
    });
  });

  group('synchronized store', () {
    const user = SignedIn(
      userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
      email: 'a@test.com',
    );
    const card = 'acc-card';
    late FakeSyncedStore store;
    late SyncedAccountRepository accounts;
    late SyncedTransactionRepository transactions;
    late CardFunding funding;

    setUp(() async {
      store = FakeSyncedStore(user);
      await store.download({
        'accounts': [SyncedRows.account(card, 'RCBC Card', type: 'credit')],
        'categories': [
          SyncedRows.category(
            'cat-card',
            'RCBC Card',
            planGroup: 'liability',
            linkedAccountId: card,
          ),
        ],
      });
      accounts = SyncedAccountRepository(store.database);
      transactions = SyncedTransactionRepository(store.database);
      funding = CardFunding(
        accounts: accounts,
        transactions: transactions,
        atomically: store.database.transaction,
        clock: _clock,
      );
    });

    tearDown(() => store.close());

    test('queues the account then the Transfer from the card', () async {
      final created = await funding.create(
        name: 'Credit Cc',
        type: AccountType.savingsCash,
        amount: php(100000),
        cardId: card,
      );

      final items = await store.queuedItems();
      expect(items.map((item) => item['operation']), [
        'account.create',
        'transaction.create',
      ]);
      final accountData = items.first['data']! as Map<String, Object?>;
      expect(accountData['entered_opening_amount_minor'], anyOf(0, '0'));
      final transferData = items.last['data']! as Map<String, Object?>;
      expect(transferData['type'], 'transfer');
      expect(transferData['source_account_id'], card);
      expect(transferData['destination_account_id'], created.id);
    });

    test('a refused Transfer writes and queues nothing', () async {
      await accounts.setArchived(card, archived: true);
      final queuedBefore = (await store.queuedItems()).length;

      await expectLater(
        funding.create(
          name: 'Credit Cc',
          type: AccountType.savingsCash,
          amount: php(100000),
          cardId: card,
        ),
        throwsA(isA<TransactionValidationException>()),
      );
      expect(await store.queuedItems(), hasLength(queuedBefore));
      final names = (await accounts.watchAll(includeArchived: true).first).map(
        (account) => account.name,
      );
      expect(names, isNot(contains('Credit Cc')));
    });
  });
}
