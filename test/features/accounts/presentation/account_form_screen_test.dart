import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/account_validation_exception.dart';
import 'package:fundly/features/accounts/presentation/account_form_screen.dart';

import '../../../helpers/fake_account_repository.dart';

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

void main() {
  late FakeAccountRepository repository;

  setUp(() => repository = FakeAccountRepository());

  /// Opens the form from a placeholder page so a successful save can pop.
  Future<void> openForm(WidgetTester tester, {Account? account}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [accountRepositoryProvider.overrideWithValue(repository)],
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
    await tester.tap(find.byType(DropdownButtonFormField<AccountType>));
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
      final dropdown = tester.widget<DropdownButton<AccountType>>(
        find.byType(DropdownButton<AccountType>),
      );
      expect(dropdown.onChanged, isNull, reason: 'disabled');
      expect(dropdown.value, AccountType.credit);
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
  });
}
