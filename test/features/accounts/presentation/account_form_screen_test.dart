import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/account_validation_exception.dart';
import 'package:fundly/features/accounts/domain/custom_account_type.dart';
import 'package:fundly/features/accounts/domain/custom_account_type_validation_exception.dart';
import 'package:fundly/features/accounts/presentation/account_form_screen.dart';
import 'package:fundly/features/accounts/presentation/accounts_providers.dart';

import '../../../helpers/fake_account_repository.dart';
import '../../../helpers/fake_custom_account_type_repository.dart';
import '../../../helpers/provider_overrides.dart';

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

void main() {
  late FakeAccountRepository repository;
  late FakeCustomAccountTypeRepository typeRepository;

  setUp(() {
    repository = FakeAccountRepository();
    typeRepository = FakeCustomAccountTypeRepository();
  });

  /// Opens the form from a placeholder page so a successful save can pop.
  Future<void> openForm(
    WidgetTester tester, {
    Account? account,
    List<CustomAccountType> customTypes = const [],
    List<Account> existingAccounts = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(repository),
          ...fakeCustomAccountTypes(customTypes, repository: typeRepository),
          allAccountsProvider.overrideWith(
            (ref) => Stream.value(existingAccounts),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AccountFormScreen(account: account),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> selectType(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<Object>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pumpAndSettle();
  }

  group('creating', () {
    testWidgets('saves a Savings/Cash account and closes', (tester) async {
      await openForm(tester);
      expect(find.text('New account'), findsOneWidget);

      await tester.enterText(field('Name'), 'BDO Savings');
      await tester.enterText(field('Opening balance'), '15,000.50');
      await tapSave(tester, 'Add account');

      final created = repository.created.single;
      expect(created.name, 'BDO Savings');
      expect(created.type, AccountType.savingsCash);
      expect(created.entered, php(1500050));
      expect(find.byType(AccountFormScreen), findsNothing);
    });

    testWidgets('a credit account sends the positive amount owed', (
      tester,
    ) async {
      await openForm(tester);

      await selectType(tester, 'Credit');
      expect(field('Amount owed'), findsOneWidget);

      await tester.enterText(field('Name'), 'RCBC Credit');
      await tester.enterText(field('Amount owed'), '3000');
      await tapSave(tester, 'Add account');

      final created = repository.created.single;
      expect(created.type, AccountType.credit);
      expect(created.entered, php(300000));
    });

    testWidgets('a blank opening balance saves as zero', (tester) async {
      await openForm(tester);

      await tester.enterText(field('Name'), 'Cash Wallet');
      await tapSave(tester, 'Add account');

      expect(repository.created.single.entered, php(0));
    });

    testWidgets('shows field errors and does not save invalid input', (
      tester,
    ) async {
      await openForm(tester);

      await tester.enterText(field('Opening balance'), '10.555');
      await tapSave(tester, 'Add account');

      expect(find.text('Enter a name.'), findsOneWidget);
      expect(find.text('Use at most 2 decimal places.'), findsOneWidget);
      expect(repository.created, isEmpty);
      expect(find.byType(AccountFormScreen), findsOneWidget);
    });

    testWidgets('rejects a minus sign and malformed amounts', (tester) async {
      await openForm(tester);
      await tester.enterText(field('Name'), 'BDO');

      await tester.enterText(field('Opening balance'), '-5');
      await tapSave(tester, 'Add account');
      expect(
        find.text('Enter the amount without a minus sign.'),
        findsOneWidget,
      );

      await tester.enterText(field('Opening balance'), '1.2.3');
      await tapSave(tester, 'Add account');
      expect(find.text('Enter an amount like 1,234.50.'), findsOneWidget);

      expect(repository.created, isEmpty);
    });

    testWidgets('shows a duplicate-name error from the repository', (
      tester,
    ) async {
      repository.failWith = AccountValidationError.nameTaken;
      await openForm(tester);

      await tester.enterText(field('Name'), 'bdo savings');
      await tapSave(tester, 'Add account');

      expect(
        find.text('You already have an account with this name.'),
        findsOneWidget,
      );
      expect(repository.created, isEmpty);
      expect(find.byType(AccountFormScreen), findsOneWidget);
    });
  });

  group('custom account types', () {
    final eWallet = CustomAccountType(
      id: 10,
      name: 'E-wallet',
      baseType: AccountType.savingsCash,
      createdAt: DateTime.utc(2026, 11, 17),
    );
    final payLater = CustomAccountType(
      id: 11,
      name: 'Pay later',
      baseType: AccountType.credit,
      createdAt: DateTime.utc(2026, 11, 17),
    );

    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byType(DropdownButtonFormField<Object>));
      await tester.pumpAndSettle();
    }

    testWidgets('lists types under Assets and Liabilities, then New', (
      tester,
    ) async {
      await openForm(tester, customTypes: [eWallet, payLater]);
      await openMenu(tester);

      final menuTexts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(Scrollable).last,
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .toList();
      expect(menuTexts, [
        'Assets',
        'Savings / Cash',
        'E-wallet',
        'Liabilities',
        'Credit',
        'Loan',
        'Pay later',
        'New account type…',
      ]);
    });

    testWidgets('saves an account with a custom type and its base type', (
      tester,
    ) async {
      await openForm(tester, customTypes: [eWallet, payLater]);

      await selectType(tester, 'Pay later');
      expect(field('Amount owed'), findsOneWidget, reason: 'liability');
      expect(find.text('Liability: works like a credit card.'), findsOneWidget);

      await tester.enterText(field('Name'), 'SPayLater');
      await tester.enterText(field('Amount owed'), '500');
      await tapSave(tester, 'Add account');

      final created = repository.created.single;
      expect(created.type, AccountType.credit);
      expect(created.customTypeId, payLater.id);
      expect(created.entered, php(50000));
    });

    testWidgets('a built-in type saves with no custom type', (tester) async {
      await openForm(tester, customTypes: [eWallet]);

      await tester.enterText(field('Name'), 'BDO Savings');
      await tapSave(tester, 'Add account');

      expect(repository.created.single.customTypeId, isNull);
    });

    testWidgets('New account type creates a liability type and selects it', (
      tester,
    ) async {
      await openForm(tester);

      await selectType(tester, 'New account type…');
      expect(find.text('New account type'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        'Personal debt',
      );
      await tester.tap(find.text('Liability'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Loan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add type'));
      await tester.pumpAndSettle();

      final type = typeRepository.created.single;
      expect(type.name, 'Personal debt');
      expect(type.baseType, AccountType.loan);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Personal debt'), findsOneWidget, reason: 'selected');
      expect(field('Amount owed'), findsOneWidget);

      await tester.enterText(field('Name'), 'From Mom');
      await tapSave(tester, 'Add account');

      final created = repository.created.single;
      expect(created.type, AccountType.loan);
      expect(created.customTypeId, type.id);
    });

    testWidgets('an Asset type needs no "works like" choice', (tester) async {
      await openForm(tester);

      await selectType(tester, 'New account type…');
      expect(find.text('Works like'), findsNothing);
      await tester.tap(find.text('Liability'));
      await tester.pumpAndSettle();
      expect(find.text('Works like'), findsOneWidget);
      await tester.tap(find.text('Asset'));
      await tester.pumpAndSettle();
      expect(find.text('Works like'), findsNothing);

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        'E-wallet',
      );
      await tester.tap(find.text('Add type'));
      await tester.pumpAndSettle();

      expect(typeRepository.created.single.baseType, AccountType.savingsCash);
    });

    testWidgets('the dialog shows a taken name and stays open', (tester) async {
      await openForm(tester);
      typeRepository.failWith = CustomAccountTypeValidationError.nameTaken;

      await selectType(tester, 'New account type…');
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        'Credit',
      );
      await tester.tap(find.text('Add type'));
      await tester.pumpAndSettle();

      expect(
        find.text('An account type with this name already exists.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('cancelling New account type keeps the previous type', (
      tester,
    ) async {
      await openForm(tester);
      await selectType(tester, 'Credit');

      await selectType(tester, 'New account type…');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Credit'), findsOneWidget);
      expect(find.text('New account type…'), findsNothing);
      await tester.enterText(field('Name'), 'RCBC');
      await tapSave(tester, 'Add account');
      expect(repository.created.single.type, AccountType.credit);
    });

    testWidgets('editing offers only types with the same base type', (
      tester,
    ) async {
      final wallet = Account(
        id: 5,
        name: 'GCash',
        type: AccountType.savingsCash,
        openingBalance: php(0),
        createdAt: DateTime.utc(2026, 11, 16),
        customTypeId: eWallet.id,
      );
      await openForm(tester, account: wallet, customTypes: [eWallet, payLater]);

      expect(find.text('E-wallet'), findsOneWidget);
      expect(
        find.text('Can change only to a type that works the same way.'),
        findsOneWidget,
      );
      await openMenu(tester);
      expect(find.text('Savings / Cash'), findsWidgets);
      expect(find.text('Pay later'), findsNothing);
      expect(find.text('Credit'), findsNothing);
      expect(find.text('New account type…'), findsNothing);
      await tester.tap(find.text('Savings / Cash').last);
      await tester.pumpAndSettle();

      await tapSave(tester, 'Save changes');

      expect(repository.updated.single.customType, (id: null));
    });
  });

  group('budget account', () {
    final bdo = Account(
      id: 1,
      name: 'BDO Savings',
      type: AccountType.savingsCash,
      openingBalance: php(0),
      createdAt: DateTime.utc(2026, 11, 16),
      isBudgetAccount: true,
    );
    final bpi = Account(
      id: 2,
      name: 'BPI Savings',
      type: AccountType.savingsCash,
      openingBalance: php(0),
      createdAt: DateTime.utc(2026, 11, 16),
    );
    Finder budgetSwitch() =>
        find.widgetWithText(SwitchListTile, 'Use as budget account');

    testWidgets('only asset accounts offer the switch', (tester) async {
      await openForm(tester);
      expect(budgetSwitch(), findsOneWidget);

      await selectType(tester, 'Credit');
      expect(budgetSwitch(), findsNothing);
      await selectType(tester, 'Loan');
      expect(budgetSwitch(), findsNothing);
    });

    testWidgets('a new account can be the first budget account', (
      tester,
    ) async {
      await openForm(tester);

      await tester.enterText(field('Name'), 'BDO Savings');
      await tester.tap(budgetSwitch());
      await tester.pumpAndSettle();
      await tapSave(tester, 'Add account');

      expect(find.byType(AlertDialog), findsNothing, reason: 'nothing to move');
      expect(repository.budgetAccountChanges, [repository.created.length]);
      expect(find.byType(AccountFormScreen), findsNothing);
    });

    testWidgets('moving the tag asks first, then moves it', (tester) async {
      await openForm(tester, account: bpi, existingAccounts: [bdo, bpi]);

      await tester.tap(budgetSwitch());
      await tester.pumpAndSettle();
      await tapSave(tester, 'Save changes');

      expect(
        find.text(
          'Make BPI Savings your budget account instead of BDO Savings? '
          'Ready to assign on Plans will count money coming into BPI '
          'Savings.',
        ),
        findsOneWidget,
      );
      expect(repository.updated, isEmpty, reason: 'nothing saved yet');

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(repository.updated.single.id, bpi.id);
      expect(repository.budgetAccountChanges, [bpi.id]);
      expect(find.byType(AccountFormScreen), findsNothing);
    });

    testWidgets('cancelling the move saves nothing', (tester) async {
      await openForm(tester, account: bpi, existingAccounts: [bdo, bpi]);

      await tester.tap(budgetSwitch());
      await tester.pumpAndSettle();
      await tapSave(tester, 'Save changes');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.updated, isEmpty);
      expect(repository.budgetAccountChanges, isEmpty);
      expect(find.byType(AccountFormScreen), findsOneWidget);
    });

    testWidgets('the budget account starts switched on; off clears it', (
      tester,
    ) async {
      await openForm(tester, account: bdo, existingAccounts: [bdo, bpi]);

      final tile = tester.widget<SwitchListTile>(budgetSwitch());
      expect(tile.value, isTrue);

      await tester.tap(budgetSwitch());
      await tester.pumpAndSettle();
      await tapSave(tester, 'Save changes');

      expect(repository.budgetAccountChanges, [null]);
    });

    testWidgets('saving the budget account unchanged keeps the tag', (
      tester,
    ) async {
      await openForm(tester, account: bdo, existingAccounts: [bdo, bpi]);

      await tester.enterText(field('Name'), 'BDO Payroll');
      await tapSave(tester, 'Save changes');

      expect(repository.updated.single.name, 'BDO Payroll');
      expect(repository.budgetAccountChanges, isEmpty);
    });
  });

  group('editing', () {
    final card = Account(
      id: 7,
      name: 'RCBC Credit',
      type: AccountType.credit,
      openingBalance: php(-300000),
      createdAt: DateTime.utc(2026, 11, 16),
    );

    testWidgets('pre-fills the name and the positive amount owed', (
      tester,
    ) async {
      await openForm(tester, account: card);

      expect(find.text('Edit account'), findsOneWidget);
      expect(find.text('RCBC Credit'), findsOneWidget);
      expect(find.text('3000.00'), findsOneWidget);
      expect(field('Amount owed'), findsOneWidget);
    });

    testWidgets('locks the account type', (tester) async {
      await openForm(tester, account: card);

      expect(find.text("An account's type can't be changed."), findsOneWidget);
      final dropdown = tester.widget<DropdownButton<Object>>(
        find.byType(DropdownButton<Object>),
      );
      expect(dropdown.onChanged, isNull, reason: 'disabled');
      expect(dropdown.value, (type: AccountType.credit, customTypeId: null));
      // update() has no type parameter, so a save cannot change it either.
    });

    testWidgets('saves a new name and amount', (tester) async {
      await openForm(tester, account: card);

      await tester.enterText(field('Name'), 'RCBC Visa');
      await tester.enterText(field('Amount owed'), '4,500.25');
      await tapSave(tester, 'Save changes');

      final updated = repository.updated.single;
      expect(updated.id, card.id);
      expect(updated.name, 'RCBC Visa');
      expect(updated.entered, php(450025));
      expect(find.byType(AccountFormScreen), findsNothing);
    });

    testWidgets('a zero opening balance starts empty with a 0.00 hint', (
      tester,
    ) async {
      final wallet = Account(
        id: 8,
        name: 'Cash Wallet',
        type: AccountType.savingsCash,
        openingBalance: php(0),
        createdAt: DateTime.utc(2026, 11, 16),
      );
      await openForm(tester, account: wallet);

      final amount = tester.widget<TextField>(
        find.descendant(
          of: field('Opening balance'),
          matching: find.byType(TextField),
        ),
      );
      expect(amount.controller!.text, isEmpty);
      expect(amount.decoration!.hintText, '0.00');

      await tapSave(tester, 'Save changes');
      expect(repository.updated.single.entered, php(0));
    });
  });
}
