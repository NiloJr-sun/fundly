import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/sync/sync_queue.dart' show newRecordId;
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/accounts/data/synced_account_repository.dart';
import 'package:fundly/features/accounts/data/synced_custom_bank_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/backup/data/backup_importer.dart';
import 'package:fundly/features/backup/data/cloud_data_resetter.dart';
import 'package:fundly/features/backup/data/dataset_request.dart';
import 'package:fundly/features/categories/data/synced_category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/data/synced_plan_repository.dart';
import 'package:fundly/features/transactions/data/synced_transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

import '../../helpers/fake_import_server.dart';
import '../../helpers/fake_synced_store.dart';

Money php(int m) => Money(minorUnits: m, currencyCode: 'PHP');

/// A realistic offline session through every synchronized write. The queue
/// it produces and the rows the device then shows are the client side of the
/// contract check `supabase/tests/client_contract_test.py`, which replays the
/// queue on the local server and compares the rows (revisions included).
/// Set FUNDLY_CONTRACT_OUT to a file path to write them.
void main() {
  test('every write kind queues one batch', () async {
    final store = FakeSyncedStore(const SignedIn(userId: 'u', email: 'e'));
    final db = store.database;
    final accounts = SyncedAccountRepository(db);
    final types = SyncedCustomAccountTypeRepository(db);
    final categories = SyncedCategoryRepository(db);
    final transactions = SyncedTransactionRepository(db);
    final plans = SyncedPlanRepository(db, timeZone: () async => 'Asia/Manila');

    final ewallet = await types.create(
      name: 'E-wallet',
      baseType: AccountType.savingsCash,
    );
    await types.update(ewallet.id, name: 'GCash type');
    final bdo = await accounts.create(
      name: 'BDO',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(100000),
    );
    final gcash = await accounts.create(
      name: 'GCash',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(0),
      customTypeId: ewallet.id,
    );
    final food = await categories.create(
      name: 'Food',
      kind: CategoryKind.spending,
    );
    await categories.create(name: 'BPI card', kind: CategoryKind.spending);
    final card = await accounts.create(
      name: 'BPI Card',
      type: AccountType.credit,
      enteredOpeningAmount: php(5000),
    );
    final loan = await accounts.create(
      name: 'Car loan',
      type: AccountType.loan,
      enteredOpeningAmount: php(0),
    );
    await accounts.update(
      card.id,
      name: 'BPI Gold',
      enteredOpeningAmount: php(6000),
    );
    await accounts.update(gcash.id, customType: (id: null));
    await accounts.setBudgetAccount(bdo.id);
    await accounts.setBudgetAccount(gcash.id);
    await accounts.setBudgetAccount(bdo.id);
    final lunch = await transactions.create(
      TransactionDraft(
        type: TransactionType.spending,
        amount: php(25000),
        date: CalendarDate(2026, 11, 22),
        payee: 'Lunch',
        categoryId: food.id,
        sourceAccountId: bdo.id,
      ),
    );
    await transactions.update(
      lunch.id,
      TransactionDraft(
        type: TransactionType.spending,
        amount: php(26000),
        date: CalendarDate(2026, 11, 22),
        payee: 'Lunch',
        categoryId: food.id,
        sourceAccountId: bdo.id,
        note: 'x',
      ),
    );
    await transactions.update(
      lunch.id,
      TransactionDraft(
        type: TransactionType.spending,
        amount: php(27000),
        date: CalendarDate(2026, 11, 22),
        payee: 'Lunch',
        categoryId: food.id,
        sourceAccountId: bdo.id,
      ),
    );
    await transactions.create(
      TransactionDraft(
        type: TransactionType.creditCardPayment,
        amount: php(1000),
        date: CalendarDate(2026, 11, 22),
        sourceAccountId: bdo.id,
        destinationAccountId: card.id,
      ),
    );
    final tmp = await transactions.create(
      TransactionDraft(
        type: TransactionType.transfer,
        amount: php(500),
        date: CalendarDate(2026, 11, 22),
        sourceAccountId: bdo.id,
        destinationAccountId: gcash.id,
      ),
    );
    await transactions.delete(tmp.id);
    final cardRow = (await categories.watchAll().first).firstWhere(
      (c) => c.linkedAccountId == card.id,
    );
    await plans.save(
      month: CalendarMonth(2026, 10),
      categoryId: food.id,
      target: php(1000),
      assigned: php(0),
    );
    await plans.save(
      month: CalendarMonth(2026, 10),
      categoryId: food.id,
      target: php(2000),
      assigned: php(0),
    );
    await plans.save(
      month: CalendarMonth(2026, 12),
      categoryId: cardRow.id,
      target: null,
      assigned: php(300),
    );
    await plans.save(
      month: CalendarMonth(2026, 12),
      categoryId: cardRow.id,
      target: null,
      assigned: php(0),
    );
    await categories.rename(food.id, 'Food & Groceries');
    await categories.setPlanGroup(food.id, PlanGroup.savings);
    final gifts = await categories.create(
      name: 'Gifts',
      kind: CategoryKind.spending,
    );
    // A default Target (1.4.0): set on create, changed, removed, and an
    // empty plan kept while one is set.
    final rent = await categories.create(
      name: 'House rent',
      kind: CategoryKind.spending,
      defaultTarget: php(500000),
    );
    await plans.save(
      month: CalendarMonth(2026, 11),
      categoryId: rent.id,
      target: null,
      assigned: php(0),
    );
    await categories.setDefaultTarget(rent.id, php(0));
    await categories.setDefaultTarget(food.id, php(250000));
    await categories.setDefaultTarget(food.id, null);
    await plans.setArchived(gifts.id, archived: true);
    await plans.setArchived(gifts.id, archived: false);
    await categories.setArchived(gifts.id, archived: true);
    await plans.deletePermanently(gifts.id);
    await accounts.setArchived(loan.id, archived: true);
    await accounts.setArchived(loan.id, archived: false);
    await accounts.setArchived(loan.id, archived: true);
    await accounts.delete(loan.id);
    await accounts.setArchived(bdo.id, archived: true);
    await accounts.setArchived(bdo.id, archived: false);
    await accounts.setBudgetAccount(bdo.id);
    await accounts.clearBudgetAccount(gcash.id);
    final g2 = await types.create(name: 'Temp', baseType: AccountType.loan);
    await types.delete(g2.id);
    // Banks (docs/BANKS_PLAN.md): custom banks, and accounts with a built-in
    // bank, a custom bank, a switch, an edit that keeps it, and a clear.
    final banks = SyncedCustomBankRepository(db);
    final coop = await banks.create('Town Coop');
    await banks.rename(coop.id, 'Town Coop Bank');
    final tempBank = await banks.create('Temp bank');
    final maya = await accounts.create(
      name: 'Maya wallet',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(2500),
      bankKey: 'maya',
    );
    await accounts.create(
      name: 'Coop savings',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(0),
      customBankId: coop.id,
    );
    await accounts.update(
      maya.id,
      bank: (bankKey: null, customBankId: coop.id),
    );
    await accounts.update(card.id, bank: (bankKey: 'bpi', customBankId: null));
    await accounts.update(card.id, name: 'BPI Platinum');
    await accounts.update(
      gcash.id,
      bank: (bankKey: 'gcash', customBankId: null),
    );
    await accounts.update(gcash.id, bank: (bankKey: null, customBankId: null));
    await banks.delete(tempBank.id);

    final batches = [
      for (final b in await store.queuedBatches())
        {'id': b.id, 'envelope': b.envelope},
    ];
    final state = <String, Object?>{};
    for (final table in [
      'custom_account_types',
      'custom_banks',
      'accounts',
      'categories',
      'transactions',
      'monthly_plans',
    ]) {
      state[table] = [
        for (final r
            in await db.customSelect('SELECT * FROM $table ORDER BY id').get())
          r.data,
      ];
    }
    // The exact request Reset all data sends for this account (reset B2).
    final reset = {
      'importId': newRecordId(),
      'request': resetRequest(
        expected: await watchSyncedCounts(db).first,
        newId: newRecordId,
      ),
    };
    // The requests copying this device's data sends (S6.2): into an empty
    // account, then replacing it with a second copy (fresh IDs).
    final firstCopy = datasetRequestFor(sampleDeviceRecords());
    final secondCopy = datasetRequestFor(sampleDeviceRecords());
    final copy = {
      'importId': newRecordId(),
      'request': importRequest(replace: false, dataset: firstCopy.dataset),
      'againId': newRecordId(),
      'again': importRequest(
        replace: true,
        dataset: secondCopy.dataset,
        expected: countsOf(sampleDeviceRecords()),
      ),
    };
    // Restoring backup files while signed in (S6.3): a format 7 file and an
    // old format 3 file, as parsed and sent by the app.
    Future<Map<String, Object?>> restoreOf(Map<String, Object?> file) async =>
        importRequest(
          replace: false,
          dataset: datasetRequestFor(parseBackup(jsonEncode(file)).records)
              .dataset,
        );
    copy['restores'] = {
      'format7': await restoreOf(await sampleBackupJson()),
      'format3': await restoreOf(await sampleFormat3Json()),
    };
    final out = Platform.environment['FUNDLY_CONTRACT_OUT'];
    if (out != null) {
      File(out).writeAsStringSync(
        jsonEncode({
          'batches': batches,
          'state': state,
          'reset': reset,
          'copy': copy,
        }),
      );
    }
    // Setting BDO again while it is already a budget account queues nothing.
    expect(batches, hasLength(55));
    await store.close();
  });
}
