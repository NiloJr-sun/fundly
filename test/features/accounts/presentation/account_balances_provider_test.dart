import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/presentation/accounts_providers.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

/// End-to-end: real repositories on an in-memory database, through the
/// providers screens use.
void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    // Keep the provider alive and listening for the whole test.
    container.listen(accountBalancesProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  /// Waits for stream updates to reach the provider, then reads balances.
  Future<Map<int, Money>> balances() async {
    await pumpEventQueue();
    return container.read(accountBalancesProvider).requireValue;
  }

  test('Rule 11: balances follow create, edit and delete', () async {
    final accounts = container.read(accountRepositoryProvider);
    final transactions = container.read(transactionRepositoryProvider);
    final bdo = await accounts.create(
      name: 'BDO Savings',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(1500000),
    );
    final card = await accounts.create(
      name: 'RCBC Credit',
      type: AccountType.credit,
      enteredOpeningAmount: php(300000),
    );

    expect(await balances(), {bdo.id: php(1500000), card.id: php(-300000)});

    final payment = await transactions.create(
      TransactionDraft(
        type: TransactionType.creditCardPayment,
        amount: php(100000),
        date: CalendarDate(2026, 11, 16),
        sourceAccountId: bdo.id,
        destinationAccountId: card.id,
      ),
    );
    expect(await balances(), {bdo.id: php(1400000), card.id: php(-200000)});

    await transactions.update(
      payment.id,
      TransactionDraft(
        type: TransactionType.creditCardPayment,
        amount: php(300000),
        date: CalendarDate(2026, 11, 16),
        sourceAccountId: bdo.id,
        destinationAccountId: card.id,
      ),
    );
    expect(await balances(), {bdo.id: php(1200000), card.id: php(0)});

    await transactions.delete(payment.id);
    expect(await balances(), {bdo.id: php(1500000), card.id: php(-300000)});
  });

  test('editing an opening balance recalculates too', () async {
    final accounts = container.read(accountRepositoryProvider);
    final wallet = await accounts.create(
      name: 'Cash Wallet',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(1000),
    );

    await accounts.update(wallet.id, enteredOpeningAmount: php(2500));

    expect((await balances())[wallet.id], php(2500));
  });

  test('archived accounts still have balances', () async {
    final accounts = container.read(accountRepositoryProvider);
    final old = await accounts.create(
      name: 'Old Wallet',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(700),
    );

    await accounts.setArchived(old.id, archived: true);

    expect((await balances())[old.id], php(700));
  });
}
