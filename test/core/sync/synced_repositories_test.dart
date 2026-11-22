import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/sync/synced_database.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/accounts/data/synced_account_repository.dart';
import 'package:fundly/features/accounts/domain/account_balance.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/categories/data/synced_category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/data/synced_plan_repository.dart';
import 'package:fundly/features/plans/domain/plan_deletion.dart';
import 'package:fundly/features/transactions/data/synced_transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

import '../../helpers/fake_synced_store.dart';

const _user = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);

// Readable stand-ins for server UUIDs.
const bdo = 'acc-bdo';
const wallet = 'acc-wallet';
const card = 'acc-card';
const food = 'cat-food';
const salary = 'cat-salary';
const cardRow = 'cat-card';

Money php(int minor) => Money(minorUnits: minor, currencyCode: 'PHP');

void main() {
  late FakeSyncedStore store;

  setUp(() async {
    store = FakeSyncedStore(_user);
    await store.download({
      // Children before parents: foreign keys are checked at commit.
      'transactions': [
        SyncedRows.transaction(
          'tx-lunch',
          amountMinor: 25000,
          date: '2026-11-16',
          categoryId: food,
          sourceAccountId: bdo,
          createdAt: '2026-11-16 12:00:00.000Z',
        ),
        SyncedRows.transaction(
          'tx-salary',
          type: 'inflow',
          amountMinor: 5000000,
          date: '2026-11-15',
          payee: 'Employer',
          categoryId: salary,
          destinationAccountId: bdo,
        ),
        SyncedRows.transaction(
          'tx-pay-card',
          type: 'creditCardPayment',
          amountMinor: 300000,
          date: '2026-11-16',
          payee: '',
          sourceAccountId: bdo,
          destinationAccountId: card,
          createdAt: '2026-11-16 08:00:00.000Z',
        ),
      ],
      'categories': [
        SyncedRows.category(food, 'Food', createdAt: '2026-11-01 00:00:00Z'),
        SyncedRows.category(
          salary,
          'Salary',
          kind: 'inflow',
          createdAt: '2026-11-02 00:00:00Z',
        ),
        SyncedRows.category(
          cardRow,
          'RCBC Card',
          planGroup: 'liability',
          linkedAccountId: card,
          createdAt: '2026-11-03 00:00:00Z',
        ),
      ],
      'accounts': [
        SyncedRows.account(bdo, 'BDO Savings', openingMinor: 100000),
        SyncedRows.account(wallet, 'Old wallet', archived: true),
        SyncedRows.account(
          card,
          'RCBC Card',
          type: 'credit',
          openingMinor: -50000,
        ),
      ],
      'monthly_plans': [
        SyncedRows.plan(
          'plan-food',
          categoryId: food,
          targetMinor: 800000,
          assignedMinor: 600000,
        ),
        SyncedRows.plan('plan-old', categoryId: food, month: '2026-10'),
      ],
    });
  });

  tearDown(() => store.close());

  group('accounts', () {
    test('map to the same domain values as the local store', () async {
      final accounts = await SyncedAccountRepository(store.database)
          .watchAll(includeArchived: true)
          .first;
      expect(accounts.map((a) => a.id), [bdo, wallet, card]);
      final rcbc = accounts.last;
      expect(rcbc.type, AccountType.credit);
      expect(rcbc.openingBalance, php(-50000));
      expect(rcbc.createdAt, DateTime.utc(2026, 11, 16, 9, 30));
      expect(accounts[1].isArchived, isTrue);
    });

    test('hide archived ones unless asked, like the local store', () async {
      final repository = SyncedAccountRepository(store.database);
      expect((await repository.watchAll().first).map((a) => a.name), [
        'BDO Savings',
        'RCBC Card',
      ]);
      expect((await repository.watchById(wallet).first)?.name, 'Old wallet');
      expect(await repository.watchById('missing').first, isNull);
    });

    test('balances come from the same domain rules', () async {
      final accounts = await SyncedAccountRepository(store.database)
          .watchAll(includeArchived: true)
          .first;
      final transactions = await SyncedTransactionRepository(store.database)
          .watchAll()
          .first;
      final balances = balancesFor(accounts, transactions);
      // 1,000 + 50,000 salary − 250 lunch − 3,000 card payment.
      expect(balances[bdo], php(100000 + 5000000 - 25000 - 300000));
      // Owed 500, paid 3,000.
      expect(balances[card], php(-50000 + 300000));
    });
  });

  group('categories', () {
    test('keep creation order and every flag', () async {
      final categories = await SyncedCategoryRepository(store.database)
          .watchAll()
          .first;
      expect(categories.map((c) => c.id), [food, salary, cardRow]);
      expect(categories.last.planGroup, PlanGroup.liability);
      expect(categories.last.linkedAccountId, card);
    });

    test('filter by kind', () async {
      final inflow = await SyncedCategoryRepository(store.database)
          .watchAll(kind: CategoryKind.inflow)
          .first;
      expect(inflow.map((c) => c.name), ['Salary']);
    });
  });

  group('transactions', () {
    test('newest first by date, then by creation', () async {
      final all = await SyncedTransactionRepository(store.database)
          .watchAll()
          .first;
      expect(all.map((t) => t.id), ['tx-lunch', 'tx-pay-card', 'tx-salary']);
      final lunch = all.first;
      expect(lunch.type, TransactionType.spending);
      expect(lunch.date, CalendarDate(2026, 11, 16));
      expect(lunch.categoryId, food);
      expect(lunch.sourceAccountId, bdo);
    });

    test('filter by account (either side) and by date', () async {
      final repository = SyncedTransactionRepository(store.database);
      expect(
        (await repository.watchAll(accountId: card).first).map((t) => t.id),
        ['tx-pay-card'],
      );
      expect(
        (await repository
                .watchAll(
                  from: CalendarDate(2026, 11, 15),
                  to: CalendarDate(2026, 11, 15),
                )
                .first)
            .map((t) => t.id),
        ['tx-salary'],
      );
      expect(
        (await repository.watchById('tx-salary').first)?.payee,
        'Employer',
      );
    });

    test('update when a download changes or removes a row', () async {
      final repository = SyncedTransactionRepository(store.database);
      final seen = <List<String>>[];
      final subscription = repository.watchAll().listen(
        (list) => seen.add([for (final t in list) t.id]),
      );
      await pumpEventQueue();
      await store.deleteDownloaded('transactions', 'tx-lunch');
      await pumpEventQueue();
      await subscription.cancel();
      expect(seen.last, ['tx-pay-card', 'tx-salary']);
    });
  });

  group('plans', () {
    test('only the requested month', () async {
      final plans = await SyncedPlanRepository(store.database)
          .watchForMonth(CalendarMonth(2026, 11))
          .first;
      expect(plans, hasLength(1));
      expect(plans.single.categoryId, food);
      expect(plans.single.target, php(800000));
      expect(plans.single.assigned, php(600000));
    });

    test('deletion status uses the same rules as the local store', () async {
      final repository = SyncedPlanRepository(store.database);
      expect(
        await repository.watchDeletionStatus(food).first,
        PlanDeletionStatus.notArchived,
      );
      expect(
        await repository.watchDeletionStatus('missing').first,
        PlanDeletionStatus.categoryNotFound,
      );
    });
  });

  group('download safety', () {
    test(
      'a row with a number too large for web is hidden and counted',
      () async {
        expect(await store.database.watchUnsafeNumberCount().first, 0);
        await store.download({
          'transactions': [
            SyncedRows.transaction(
              'tx-huge',
              amountMinor: maxSafeInteger + 1,
              categoryId: food,
              sourceAccountId: bdo,
            ),
          ],
        });
        final ids = (await SyncedTransactionRepository(
          store.database,
        ).watchAll().first).map((t) => t.id);
        expect(ids, isNot(contains('tx-huge')));
        expect(await store.database.watchUnsafeNumberCount().first, 1);
      },
    );

    test('a reference to a missing record fails the whole download', () async {
      await expectLater(
        store.download({
          'transactions': [
            SyncedRows.transaction(
              'tx-orphan',
              categoryId: food,
              sourceAccountId: 'acc-missing',
            ),
          ],
        }),
        throwsA(anything),
      );
      final ids = (await SyncedTransactionRepository(
        store.database,
      ).watchAll().first).map((t) => t.id);
      expect(ids, isNot(contains('tx-orphan')));
    });

    test('year 0000 arrives as PostgreSQL 1 BC', () {
      expect(parseSyncedDate('0001-01-01 BC'), CalendarDate(0, 1, 1));
      expect(parseSyncedDate('2026-11-16'), CalendarDate(2026, 11, 16));
      expect(() => parseSyncedDate('0044-03-15 BC'), throwsFormatException);
      expect(() => parseSyncedDate('16/11/2026'), throwsFormatException);
    });

    test('timestamps parse with a space or a T, always as UTC', () {
      expect(
        parseSyncedTimestamp('2026-11-16 09:30:00.123+00'),
        DateTime.utc(2026, 11, 16, 9, 30, 0, 123),
      );
      expect(
        parseSyncedTimestamp('2026-11-16T17:30:00+08:00'),
        DateTime.utc(2026, 11, 16, 9, 30),
      );
    });
  });
}
