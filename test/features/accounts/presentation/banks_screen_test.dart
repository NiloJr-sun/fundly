import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/custom_bank.dart';
import 'package:fundly/features/accounts/presentation/accounts_screen.dart';
import 'package:fundly/features/accounts/presentation/banks_screen.dart';

import '../../../helpers/fake_custom_bank_repository.dart';
import '../../../helpers/provider_overrides.dart';

// The Banks screen (docs/BANKS_PLAN.md, B-8).

CustomBank bank(String id, String name) =>
    CustomBank(id: id, name: name, createdAt: DateTime.utc(2026, 11, 25));

Account account(String id, {String? customBankId, bool archived = false}) =>
    Account(
      id: id,
      name: 'Account $id',
      type: AccountType.savingsCash,
      openingBalance: const Money.zero('PHP'),
      createdAt: DateTime.utc(2026, 11, 25),
      customBankId: customBankId,
      isArchived: archived,
    );

void main() {
  final coop = bank('30', 'Town Coop');
  final iba = bank('31', 'Rural Bank of Iba');
  late FakeCustomBankRepository repository;

  setUp(() => repository = FakeCustomBankRepository());

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<CustomBank> banks = const [],
    List<Account> accounts = const [],
    List<Account> archived = const [],
    Widget home = const BanksScreen(),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeAccounts(
          accounts,
          archived: archived,
          customBanks: banks,
          customBankRepository: repository,
        ),
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens from the Account tab', (tester) async {
    await pumpScreen(tester, home: const AccountsScreen());

    await tester.tap(find.byTooltip('Banks'));
    await tester.pumpAndSettle();

    expect(find.byType(BanksScreen), findsOneWidget);
  });

  testWidgets('says built-in banks are already listed when none is added', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.textContaining('No banks added yet.'), findsOneWidget);
  });

  testWidgets('lists banks with how many accounts, archived included, use '
      'each', (tester) async {
    await pumpScreen(
      tester,
      banks: [iba, coop],
      accounts: [account('1', customBankId: '30')],
      archived: [account('2', customBankId: '30', archived: true)],
    );

    expect(find.text('Town Coop'), findsOneWidget);
    expect(find.text('TC'), findsOneWidget, reason: 'its monogram');
    expect(find.text('2 accounts'), findsOneWidget);
    expect(find.text('No accounts'), findsOneWidget);
  });

  testWidgets('adds a bank', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Add bank'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '  Town Coop ');
    await tester.tap(find.widgetWithText(FilledButton, 'Add bank'));
    await tester.pumpAndSettle();

    expect(repository.created.single.name, 'Town Coop');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('rejects an empty name before saving', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Add bank'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add bank'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a name.'), findsOneWidget);
    expect(repository.created, isEmpty);
  });

  testWidgets('renames a bank and shows a taken name', (tester) async {
    await pumpScreen(tester, banks: [coop]);

    await tester.tap(find.text('Town Coop'));
    await tester.pumpAndSettle();
    repository.failWith = CustomBankValidationError.nameTaken;
    await tester.enterText(find.byType(TextFormField), 'GCash');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('A bank with this name is already in the list.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField), 'Town Cooperative');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(repository.renamed.single, (id: '30', name: 'Town Cooperative'));
  });

  testWidgets('deletes an unused bank after confirming', (tester) async {
    await pumpScreen(tester, banks: [coop]);

    await tester.tap(find.text('Town Coop'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Town Coop?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository.deleted, ['30']);
  });

  testWidgets('a bank in use cannot be deleted', (tester) async {
    await pumpScreen(
      tester,
      banks: [coop],
      archived: [account('2', customBankId: '30', archived: true)],
    );

    await tester.tap(find.text('Town Coop'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, 'Delete'), findsNothing);
    expect(
      find.text("1 account belongs to this bank, so it can't be deleted."),
      findsOneWidget,
    );
  });

  testWidgets('a bank that came into use meanwhile is not deleted', (
    tester,
  ) async {
    await pumpScreen(tester, banks: [coop]);

    await tester.tap(find.text('Town Coop'));
    await tester.pumpAndSettle();
    repository.failWith = CustomBankValidationError.inUse;
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      find.text('Accounts belong to this bank, so it cannot be deleted.'),
      findsOneWidget,
    );
    expect(repository.deleted, isEmpty);
  });
}
