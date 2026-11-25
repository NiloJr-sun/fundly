import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/sync/sync_queue.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/accounts/data/synced_account_repository.dart';
import 'package:fundly/features/accounts/data/synced_custom_bank_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/account_validation_exception.dart';
import 'package:fundly/features/accounts/domain/custom_bank.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/categories/data/synced_category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/categories/domain/category_validation_exception.dart';
import 'package:fundly/features/plans/data/synced_plan_repository.dart';
import 'package:fundly/features/plans/domain/plan_validation_exception.dart';
import 'package:fundly/features/transactions/data/synced_transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_rules.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';
import 'package:fundly/features/transactions/domain/transaction_validation_exception.dart';

import '../../helpers/fake_synced_store.dart';

const _user = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);

// Downloaded records (readable stand-ins for server UUIDs).
const bdo = 'acc-bdo';
const card = 'acc-card';
const food = 'cat-food';
const cardRow = 'cat-card';

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

Money php(int minor) => Money(minorUnits: minor, currencyCode: 'PHP');

DateTime _clock() => DateTime.utc(2026, 11, 22, 3);

void main() {
  late FakeSyncedStore store;

  setUp(() async {
    store = FakeSyncedStore(_user);
    await store.download({
      'accounts': [
        SyncedRows.account(bdo, 'BDO Savings', openingMinor: 100000),
        SyncedRows.account(card, 'RCBC Card', type: 'credit'),
      ],
      'categories': [
        SyncedRows.category(food, 'Food'),
        SyncedRows.category(
          cardRow,
          'RCBC Card',
          planGroup: 'liability',
          linkedAccountId: card,
        ),
      ],
    });
  });

  tearDown(() => store.close());

  Future<Map<String, Object?>> row(String table, String id) async =>
      (await store.database
              .customSelect(
                'SELECT * FROM $table WHERE id = ?',
                variables: [Variable.withString(id)],
              )
              .getSingle())
          .data;

  group('queue', () {
    test(
      'each write is one batch with a fresh UUID; reads queue nothing',
      () async {
        final transactions = SyncedTransactionRepository(store.database);
        await transactions.watchAll().first;
        expect(await store.queuedBatches(), isEmpty);
        await transactions.create(_lunch());
        await transactions.create(_lunch());
        final batches = await store.queuedBatches();
        expect(batches, hasLength(2));
        expect(batches.map((b) => b.type), everyElement(syncBatchType));
        expect(batches.map((b) => b.id), everyElement(matches(_uuid)));
        expect(batches.first.id, isNot(batches.last.id));
        expect(batches.first.envelope['version'], 1);
      },
    );

    test('a refused write changes nothing and queues nothing', () async {
      await expectLater(
        SyncedTransactionRepository(store.database).create(
          TransactionDraft(
            type: TransactionType.spending,
            amount: php(100),
            date: CalendarDate(2026, 11, 22),
            payee: 'Store',
            categoryId: food,
            sourceAccountId: bdo,
            destinationAccountId: card,
          ),
        ),
        throwsA(isA<TransactionValidationException>()),
      );
      expect(await store.queuedBatches(), isEmpty);
      expect(
        await SyncedTransactionRepository(store.database).watchAll().first,
        isEmpty,
      );
    });
  });

  group('transactions', () {
    test('create stores the row and queues transaction.create', () async {
      final created = await SyncedTransactionRepository(
        store.database,
        clock: _clock,
      ).create(_lunch(payee: '  Jollibee  '));
      expect(created.id, matches(_uuid));
      expect(created.payee, 'Jollibee');
      expect((await store.queuedItems()).single, {
        'operation': 'transaction.create',
        'id': created.id,
        'data': {
          'type': 'spending',
          'amount_minor': '25000',
          'currency_code': 'PHP',
          'date': '2026-11-22',
          'payee': 'Jollibee',
          'note': '',
          'category_id': food,
          'source_account_id': bdo,
        },
      });
      final stored = await row('transactions', created.id);
      expect(stored['revision'], 1);
      expect(stored['created_at'], '2026-11-22T03:00:00.000Z');
    });

    test('a card purchase saves and uploads with no category (R.18)', () async {
      final repository = SyncedTransactionRepository(store.database);
      final created = await repository.create(
        TransactionDraft(
          type: TransactionType.spending,
          amount: php(10000),
          date: CalendarDate(2026, 11, 22),
          payee: '7/11',
          sourceAccountId: card,
        ),
      );
      expect(created.categoryId, isNull);
      final data =
          (await store.queuedItems()).single['data']! as Map<String, Object?>;
      expect(data['category_id'], isNull);
      expect(data['source_account_id'], card);
      await expectLater(
        repository.create(
          TransactionDraft(
            type: TransactionType.spending,
            amount: php(10000),
            date: CalendarDate(2026, 11, 22),
            payee: '7/11',
            sourceAccountId: bdo,
          ),
        ),
        throwsA(
          isA<TransactionValidationException>().having(
            (e) => e.errors,
            'errors',
            {TransactionValidationError.categoryMissing},
          ),
        ),
      );
    });

    test(
      'two offline edits carry the revisions the server will hold',
      () async {
        final repository = SyncedTransactionRepository(store.database);
        final created = await repository.create(_lunch());
        await repository.update(created.id, _lunch(amount: 30000));
        await repository.update(created.id, _lunch(amount: 35000));
        final items = await store.queuedItems();
        expect(items.map((i) => i['operation']), [
          'transaction.create',
          'transaction.update',
          'transaction.update',
        ]);
        expect(items[1]['expected_revision'], '1');
        expect(items[2]['expected_revision'], '2');
        expect((await row('transactions', created.id))['revision'], 3);
      },
    );

    test('an update states every reference, a cleared one as null', () async {
      await store.download({
        'transactions': [
          SyncedRows.transaction(
            'tx-pay',
            type: 'transfer',
            payee: '',
            sourceAccountId: bdo,
            destinationAccountId: 'acc-wallet',
            revision: 4,
          ),
        ],
        'accounts': [SyncedRows.account('acc-wallet', 'Wallet')],
      });
      await SyncedTransactionRepository(store.database).update(
        'tx-pay',
        TransactionDraft(
          type: TransactionType.transfer,
          amount: php(500),
          date: CalendarDate(2026, 11, 22),
          sourceAccountId: bdo,
          destinationAccountId: 'acc-wallet',
          note: 'rent',
        ),
      );
      final item = (await store.queuedItems()).single;
      expect(item['expected_revision'], '4');
      expect(item['data'], containsPair('category_id', null));
      expect(item['data'], isNot(contains('type')));
    });

    test('delete removes the row and queues the revision', () async {
      final repository = SyncedTransactionRepository(store.database);
      final created = await repository.create(_lunch());
      await repository.delete(created.id);
      expect(await repository.watchById(created.id).first, isNull);
      expect((await store.queuedItems()).last, {
        'operation': 'transaction.delete',
        'id': created.id,
        'expected_revision': '1',
      });
    });

    test('the same rules as the local store apply', () async {
      await expectLater(
        SyncedTransactionRepository(
          store.database,
        ).create(_lunch().copyWithSource(card, type: TransactionType.transfer)),
        throwsA(
          isA<TransactionValidationException>().having(
            (e) => e.errors,
            'errors',
            contains(TransactionValidationError.destinationAccountWrongType),
          ),
        ),
      );
    });
  });

  group('accounts', () {
    test(
      'a credit account brings its Plans row, named by the client',
      () async {
        final repository = SyncedAccountRepository(store.database);
        final account = await repository.create(
          name: 'BPI Card',
          type: AccountType.credit,
          enteredOpeningAmount: php(20000),
        );
        expect(account.openingBalance, php(-20000));
        final item = (await store.queuedItems()).single;
        final data = item['data']! as Map<String, Object?>;
        expect(item['operation'], 'account.create');
        expect(data['entered_opening_amount_minor'], '20000');
        expect(data['type'], 'credit');
        final linkedId = data['linked_category_id']! as String;
        final linked = await row('categories', linkedId);
        expect(linked['name'], 'BPI Card');
        expect(linked['linked_account_id'], account.id);
        expect(linked['plan_group'], 'liability');
      },
    );

    test('a savings account sends no linked row', () async {
      await SyncedAccountRepository(store.database).create(
        name: 'Wallet',
        type: AccountType.savingsCash,
        enteredOpeningAmount: php(0),
      );
      final data = (await store.queuedItems()).single['data']!;
      expect(data, isNot(contains('linked_category_id')));
      expect(data, containsPair('custom_type_id', null));
    });

    test('a Plans row name clash gets the server suffix', () async {
      await store.download({
        'categories': [SyncedRows.category('cat-bpi', 'bpi card')],
      });
      final account = await SyncedAccountRepository(store.database).create(
        name: 'BPI Card',
        type: AccountType.loan,
        enteredOpeningAmount: php(0),
      );
      final data =
          (await store.queuedItems()).single['data']! as Map<String, Object?>;
      final linked = await row(
        'categories',
        data['linked_category_id']! as String,
      );
      expect(linked['name'], 'BPI Card (debt ${account.id.substring(0, 8)})');
    });

    test('names are unique ignoring case, as on the server', () async {
      await expectLater(
        SyncedAccountRepository(store.database).create(
          name: 'bdo savings',
          type: AccountType.savingsCash,
          enteredOpeningAmount: php(0),
        ),
        throwsA(isA<AccountValidationException>()),
      );
    });

    test('renaming a card renames its Plans row', () async {
      await SyncedAccountRepository(store.database).update(card, name: 'RCBC');
      expect((await row('categories', cardRow))['name'], 'RCBC');
      expect((await row('categories', cardRow))['revision'], 2);
      final item = (await store.queuedItems()).single;
      expect(item, {
        'operation': 'account.update',
        'id': card,
        'expected_revision': '1',
        'data': {'name': 'RCBC'},
      });
    });

    test('an update with nothing to change queues nothing', () async {
      await SyncedAccountRepository(store.database).update(bdo);
      expect(await store.queuedBatches(), isEmpty);
    });

    test('archiving the budget account clears the flag', () async {
      final repository = SyncedAccountRepository(store.database);
      await repository.setBudgetAccount(bdo);
      await repository.setArchived(bdo, archived: true);
      final stored = await row('accounts', bdo);
      expect(stored['is_budget_account'], 0);
      expect(stored['revision'], 3);
      expect((await store.queuedItems()).last, {
        'operation': 'account.set_archived',
        'id': bdo,
        'expected_revision': '2',
        'data': {'archived': true},
      });
    });

    test('budget accounts are set and cleared one at a time', () async {
      await store.download({
        'accounts': [SyncedRows.account('acc-wallet', 'Wallet')],
      });
      final repository = SyncedAccountRepository(store.database);
      await repository.setBudgetAccount(bdo);
      await repository.setBudgetAccount(bdo);
      await repository.setBudgetAccount('acc-wallet');
      expect((await row('accounts', bdo))['is_budget_account'], 1);
      expect((await row('accounts', 'acc-wallet'))['is_budget_account'], 1);
      await repository.clearBudgetAccount('acc-wallet');
      await repository.clearBudgetAccount('acc-wallet');
      expect((await row('accounts', bdo))['is_budget_account'], 1);
      expect((await row('accounts', 'acc-wallet'))['is_budget_account'], 0);
      final items = await store.queuedItems();
      expect(items, [
        {
          'operation': 'account.set_budget',
          'id': bdo,
          'expected_revision': '1',
        },
        {
          'operation': 'account.set_budget',
          'id': 'acc-wallet',
          'expected_revision': '1',
        },
        {
          'operation': 'account.clear_budget',
          'id': 'acc-wallet',
          'expected_revision': '2',
        },
      ]);
    });

    test('deleting an archived card keeps its Plans row, detached', () async {
      final repository = SyncedAccountRepository(store.database);
      await repository.setArchived(card, archived: true);
      await repository.delete(card);
      final linked = await row('categories', cardRow);
      expect(linked['linked_account_id'], isNull);
      expect((await store.queuedItems()).last['operation'], 'account.delete');
    });
  });

  group('custom account types', () {
    test('create, rename and delete queue their operations', () async {
      final repository = SyncedCustomAccountTypeRepository(store.database);
      final type = await repository.create(
        name: 'E-wallet',
        baseType: AccountType.savingsCash,
      );
      await repository.update(type.id, name: 'GCash');
      await repository.update(type.id, baseType: AccountType.savingsCash);
      await repository.delete(type.id);
      final items = await store.queuedItems();
      expect(items.map((i) => i['operation']), [
        'custom_type.create',
        'custom_type.update',
        'custom_type.delete',
      ]);
      expect(items[0]['data'], {
        'name': 'E-wallet',
        'base_type': 'savingsCash',
      });
      expect(items[2]['expected_revision'], '2');
    });
  });

  group('banks (docs/BANKS_PLAN.md)', () {
    const coop = 'bank-coop';

    setUp(
      () => store.download({
        'custom_banks': [SyncedRows.customBank(coop, 'Town Coop')],
      }),
    );

    test(
      'add, rename and delete a custom bank queue their operations',
      () async {
        final repository = SyncedCustomBankRepository(store.database);
        final bank = await repository.create(' Credit Union ');
        expect(bank.id, matches(_uuid));
        await repository.rename(bank.id, 'Credit Union');
        await repository.rename(bank.id, 'Teachers Union');
        await repository.delete(bank.id);

        final items = await store.queuedItems();
        expect(items, [
          {
            'operation': 'bank.create',
            'id': bank.id,
            'data': {'name': 'Credit Union'},
          },
          // The unchanged rename queued nothing.
          {
            'operation': 'bank.update',
            'id': bank.id,
            'expected_revision': '1',
            'data': {'name': 'Teachers Union'},
          },
          {'operation': 'bank.delete', 'id': bank.id, 'expected_revision': '2'},
        ]);
      },
    );

    test('names follow the server rules; a bank in use is kept', () async {
      final repository = SyncedCustomBankRepository(store.database);
      for (final name in ['town coop', 'GCash']) {
        await expectLater(
          repository.create(name),
          throwsA(
            isA<CustomBankValidationException>().having(
              (e) => e.error,
              'error',
              CustomBankValidationError.nameTaken,
            ),
          ),
          reason: name,
        );
      }
      await SyncedAccountRepository(store.database)
          .update(bdo, bank: (bankKey: null, customBankId: coop));
      await expectLater(
        repository.delete(coop),
        throwsA(isA<CustomBankValidationException>()),
      );
      expect(await repository.watchAll().first, hasLength(1));
    });

    test('a new account sends its bank only when it has one', () async {
      final accounts = SyncedAccountRepository(store.database);
      final withKey = await accounts.create(
        name: 'GCash Wallet',
        type: AccountType.savingsCash,
        enteredOpeningAmount: php(0),
        bankKey: 'gcash',
      );
      final withCustom = await accounts.create(
        name: 'Coop Savings',
        type: AccountType.savingsCash,
        enteredOpeningAmount: php(0),
        customBankId: coop,
      );
      await accounts.create(
        name: 'Cash',
        type: AccountType.savingsCash,
        enteredOpeningAmount: php(0),
      );

      final data = [
        for (final item in await store.queuedItems())
          item['data']! as Map<String, Object?>,
      ];
      expect(data[0], containsPair('bank_key', 'gcash'));
      expect(data[0], isNot(contains('custom_bank_id')));
      expect(data[1], containsPair('custom_bank_id', coop));
      expect(data[1], isNot(contains('bank_key')));
      expect(data[2], isNot(contains('bank_key')));
      expect(data[2], isNot(contains('custom_bank_id')));
      expect((await row('accounts', withKey.id))['bank_key'], 'gcash');
      expect((await row('accounts', withCustom.id))['custom_bank_id'], coop);
    });

    test(
      'an edit sends both bank fields, and only when the bank changes',
      () async {
        final accounts = SyncedAccountRepository(store.database);
        await accounts.update(bdo, bank: (bankKey: 'bdo', customBankId: null));
        await accounts.update(bdo, bank: (bankKey: 'bdo', customBankId: null));
        await accounts.update(bdo, name: 'BDO Payroll');
        await accounts.update(bdo, bank: (bankKey: null, customBankId: coop));
        await accounts.update(bdo, bank: (bankKey: null, customBankId: null));

        final items = await store.queuedItems();
        expect(
          [for (final item in items) item['data']],
          [
            {'bank_key': 'bdo', 'custom_bank_id': null},
            {'name': 'BDO Payroll'},
            {'bank_key': null, 'custom_bank_id': coop},
            {'bank_key': null, 'custom_bank_id': null},
          ],
        );
        expect(
          [for (final item in items) item['expected_revision']],
          ['1', '2', '3', '4'],
        );
        final account = await row('accounts', bdo);
        expect(account['bank_key'], isNull);
        expect(account['custom_bank_id'], isNull);
        expect(account['opening_balance_minor'], 100000);
      },
    );

    test('two banks, an unknown key or a missing bank are refused', () async {
      final accounts = SyncedAccountRepository(store.database);
      for (final bank in [
        (bankKey: 'bdo', customBankId: coop),
        (bankKey: 'komo', customBankId: null),
        (bankKey: null, customBankId: 'bank-missing'),
      ]) {
        await expectLater(
          accounts.update(bdo, bank: bank),
          throwsArgumentError,
          reason: '$bank',
        );
      }
      expect(await store.queuedBatches(), isEmpty);
    });

    test('a key this app does not know is kept, not re-sent', () async {
      await store.download({
        'accounts': [
          SyncedRows.account('acc-new', 'New bank', bankKey: 'newbank'),
        ],
      });
      final accounts = SyncedAccountRepository(store.database);
      final account = await accounts.update(
        'acc-new',
        name: 'Renamed',
        bank: (bankKey: 'newbank', customBankId: null),
      );
      expect(account.bankKey, 'newbank');
      expect((await store.queuedItems()).single['data'], {'name': 'Renamed'});
    });
  });

  group('categories', () {
    test('create, rename, group, archive and delete', () async {
      final repository = SyncedCategoryRepository(store.database);
      final category = await repository.create(
        name: 'Gifts',
        kind: CategoryKind.spending,
      );
      await repository.rename(category.id, 'Presents');
      await repository.setPlanGroup(category.id, PlanGroup.savings);
      await repository.setArchived(category.id, archived: true);
      await repository.delete(category.id);
      final items = await store.queuedItems();
      expect(items.map((i) => i['operation']), [
        'category.create',
        'category.update',
        'category.update',
        'category.set_archived',
        'category.delete',
      ]);
      expect(items.map((i) => i['expected_revision']), [
        null,
        '1',
        '2',
        '3',
        '4',
      ]);
    });

    test('a default Target is sent on create only when set', () async {
      final repository = SyncedCategoryRepository(store.database);
      final rent = await repository.create(
        name: 'Rent',
        kind: CategoryKind.spending,
        defaultTarget: php(500000),
      );
      await repository.create(name: 'Gifts', kind: CategoryKind.spending);

      expect(rent.defaultTarget, php(500000));
      expect(
        (await row('categories', rent.id))['default_target_minor'],
        500000,
      );
      final items = await store.queuedItems();
      expect(items.first['data'], {
        'name': 'Rent',
        'kind': 'spending',
        'plan_group': 'spending',
        'default_target_minor': '500000',
      });
      expect(
        (items.last['data']! as Map<String, Object?>).containsKey(
          'default_target_minor',
        ),
        isFalse,
      );
    });

    test('setDefaultTarget sends the amount, or null to remove it', () async {
      final repository = SyncedCategoryRepository(store.database);
      final set = await repository.setDefaultTarget(food, php(0));
      final removed = await repository.setDefaultTarget(food, null);

      expect(set.defaultTarget, php(0));
      expect(removed.defaultTarget, isNull);
      final items = await store.queuedItems();
      expect(items.map((i) => i['operation']), [
        'category.update',
        'category.update',
      ]);
      expect(items.map((i) => i['expected_revision']), ['1', '2']);
      expect(items.map((i) => i['data']), [
        {'default_target_minor': '0'},
        {'default_target_minor': null},
      ]);
      await expectLater(
        repository.setDefaultTarget(cardRow, php(100)),
        throwsStateError,
      );
    });

    test('a category in use cannot be deleted', () async {
      await SyncedTransactionRepository(store.database).create(_lunch());
      await expectLater(
        SyncedCategoryRepository(store.database).delete(food),
        throwsA(isA<CategoryValidationException>()),
      );
    });

    test('a Plans row of an account is managed through the account', () {
      expect(
        () => SyncedCategoryRepository(store.database).rename(cardRow, 'X'),
        throwsStateError,
      );
    });

    test('deleting removes its plans too, as the server does', () async {
      await store.download({
        'categories': [SyncedRows.category('cat-gifts', 'Gifts')],
        'monthly_plans': [
          SyncedRows.plan('plan-gifts', categoryId: 'cat-gifts'),
        ],
      });
      await SyncedCategoryRepository(store.database).delete('cat-gifts');
      expect(
        await SyncedPlanRepository(store.database)
            .watchForMonth(CalendarMonth(2026, 11))
            .first,
        isEmpty,
      );
    });
  });

  group('plans', () {
    final november = CalendarMonth(2026, 11);

    test('a first save sends no previous plan, a second names it', () async {
      final repository = SyncedPlanRepository(store.database);
      final plan = await repository.save(
        month: november,
        categoryId: food,
        target: null,
        assigned: php(50000),
      );
      await repository.save(
        month: november,
        categoryId: food,
        target: php(0),
        assigned: php(60000),
      );
      final items = await store.queuedItems();
      expect(items.first, {
        'operation': 'plan.save',
        'id': plan!.id,
        'data': {
          'category_id': food,
          'month': '2026-11',
          'target_amount_minor': null,
          'assigned_amount_minor': '50000',
          'previous': null,
        },
      });
      expect(items.last['id'], plan.id);
      expect((items.last['data']! as Map<String, Object?>)['previous'], {
        'id': plan.id,
        'revision': '1',
      });
      expect(
        (items.last['data']! as Map<String, Object?>)['target_amount_minor'],
        '0',
      );
    });

    test('clearing a plan removes it; with none, nothing is sent', () async {
      final repository = SyncedPlanRepository(store.database);
      await repository.save(
        month: november,
        categoryId: food,
        target: null,
        assigned: php(0),
      );
      expect(await store.queuedBatches(), isEmpty);
      await repository.save(
        month: november,
        categoryId: food,
        target: null,
        assigned: php(100),
      );
      await repository.clear(month: november, categoryId: food);
      expect(await repository.watchForMonth(november).first, isEmpty);
      expect(await store.queuedItems(), hasLength(2));
    });

    test(
      'with a default Target, clearing keeps and sends an empty plan',
      () async {
        await SyncedCategoryRepository(store.database)
            .setDefaultTarget(food, php(500000));
        final repository = SyncedPlanRepository(store.database);
        final plan = await repository.save(
          month: november,
          categoryId: food,
          target: null,
          assigned: php(0),
        );

        expect(plan!.target, isNull);
        expect(await repository.watchForMonth(november).first, [plan]);
        final last = (await store.queuedItems()).last;
        expect(last['operation'], 'plan.save');
        expect(
          (last['data']! as Map<String, Object?>)['target_amount_minor'],
          null,
        );
      },
    );

    test('archiving sends the device time zone', () async {
      final repository = SyncedPlanRepository(
        store.database,
        timeZone: () async => 'Asia/Manila',
      );
      await repository.setArchived(food, archived: true);
      await repository.setArchived(food, archived: true);
      await repository.setArchived(food, archived: false);
      final items = await store.queuedItems();
      expect(items, [
        {
          'operation': 'plan.set_archived',
          'id': food,
          'expected_revision': '1',
          'data': {'archived': true, 'timezone': 'Asia/Manila'},
        },
        {
          'operation': 'plan.set_archived',
          'id': food,
          'expected_revision': '2',
          'data': {'archived': false},
        },
      ]);
    });

    test('archiving is blocked while budget money is reserved', () async {
      final accounts = SyncedAccountRepository(store.database);
      await accounts.setBudgetAccount(bdo);
      final now = DateTime.now();
      await SyncedPlanRepository(store.database).save(
        month: CalendarMonth(now.year, now.month),
        categoryId: food,
        target: null,
        assigned: php(100),
      );
      await expectLater(
        SyncedPlanRepository(
          store.database,
          timeZone: () async => 'Asia/Manila',
        ).setArchived(food, archived: true),
        throwsA(isA<PlanArchiveBlocked>()),
      );
    });

    test('permanent deletion removes plans and flags the row', () async {
      final categories = SyncedCategoryRepository(store.database);
      await categories.setArchived(food, archived: true);
      await SyncedPlanRepository(store.database).deletePermanently(food);
      final stored = await row('categories', food);
      expect(stored['is_plan_deleted'], 1);
      expect(stored['is_plan_archived'], 1);
      expect((await store.queuedItems()).last, {
        'operation': 'plan.delete_permanently',
        'id': food,
        'expected_revision': '2',
      });
    });
  });
}

TransactionDraft _lunch({int amount = 25000, String payee = 'Lunch'}) =>
    TransactionDraft(
      type: TransactionType.spending,
      amount: php(amount),
      date: CalendarDate(2026, 11, 22),
      payee: payee,
      categoryId: food,
      sourceAccountId: bdo,
    );

extension on TransactionDraft {
  TransactionDraft copyWithSource(
    String destination, {
    required TransactionType type,
  }) => TransactionDraft(
    type: type,
    amount: amount,
    date: date,
    payee: payee,
    sourceAccountId: sourceAccountId,
    destinationAccountId: destination,
  );
}
