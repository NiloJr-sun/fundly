import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/custom_account_type.dart';
import 'package:fundly/features/accounts/domain/custom_account_type_validation_exception.dart';
import 'package:fundly/features/accounts/presentation/account_types_screen.dart';
import 'package:fundly/features/accounts/presentation/accounts_screen.dart';

import '../../../helpers/fake_custom_account_type_repository.dart';
import '../../../helpers/provider_overrides.dart';

CustomAccountType customType(String id, String name, AccountType baseType) =>
    CustomAccountType(
      id: id,
      name: name,
      baseType: baseType,
      createdAt: DateTime.utc(2026, 11, 17),
    );

Account account(String id, CustomAccountType type) => Account(
  id: id,
  name: 'Account $id',
  type: type.baseType,
  openingBalance: const Money.zero('PHP'),
  createdAt: DateTime.utc(2026, 11, 17),
  customTypeId: type.id,
);

void main() {
  final eWallet = customType('10', 'E-wallet', AccountType.savingsCash);
  final debt = customType('11', 'Debt', AccountType.loan);
  final payLater = customType('12', 'Pay later', AccountType.credit);
  late FakeCustomAccountTypeRepository repository;

  setUp(() => repository = FakeCustomAccountTypeRepository());

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<CustomAccountType> types = const [],
    List<Account> accounts = const [],
    List<Account> archived = const [],
  }) async {
    final List<Override> overrides = fakeAccounts(
      accounts,
      archived: archived,
      customTypes: types,
      customTypeRepository: repository,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: AccountTypesScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openType(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  Finder dialogName() => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextFormField),
  );

  testWidgets('the Account tab opens it', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeAccounts(const []),
        child: const MaterialApp(home: AccountsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Account types'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountTypesScreen), findsOneWidget);
  });

  testWidgets('shows an empty state', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('No custom account types yet.'), findsOneWidget);
  });

  testWidgets('lists types under their class with what they work like', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      types: [debt, eWallet, payLater],
      accounts: [account('1', eWallet), account('2', eWallet)],
      archived: [account('3', debt)],
    );

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .toList();
    expect(
      texts,
      containsAllInOrder([
        'Assets',
        'E-wallet',
        'Works like Savings / Cash · 2 accounts',
        'Liabilities',
        'Debt',
        // Archived accounts count too.
        'Works like a loan · 1 account',
        'Pay later',
        'Works like a credit card · no accounts',
      ]),
    );
  });

  testWidgets('Add type opens the new type dialog', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Add type'));
    await tester.pumpAndSettle();
    await tester.enterText(dialogName(), 'E-wallet');
    await tester.tap(find.widgetWithText(FilledButton, 'Add type'));
    await tester.pumpAndSettle();

    expect(repository.created.single.name, 'E-wallet');
    expect(repository.created.single.baseType, AccountType.savingsCash);
  });

  group('editing an unused type', () {
    testWidgets('renames it and changes its class', (tester) async {
      await pumpScreen(tester, types: [payLater]);
      await openType(tester, 'Pay later');

      expect(find.text('Edit account type'), findsOneWidget);
      expect(find.text('Pay later'), findsNWidgets(2), reason: 'pre-filled');
      await tester.enterText(dialogName(), 'Family debt');
      await tester.tap(find.text('Loan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.updated.single, (
        id: payLater.id,
        name: 'Family debt',
        baseType: AccountType.loan,
      ));
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('can become an asset', (tester) async {
      await pumpScreen(tester, types: [payLater]);
      await openType(tester, 'Pay later');

      await tester.tap(find.text('Asset'));
      await tester.pumpAndSettle();
      expect(find.text('Works like'), findsNothing);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.updated.single.baseType, AccountType.savingsCash);
    });

    testWidgets('deletes it after confirming', (tester) async {
      await pumpScreen(tester, types: [eWallet]);
      await openType(tester, 'E-wallet');

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete E-wallet?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(repository.deleted, [eWallet.id]);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('cancelling the confirmation deletes nothing', (tester) async {
      await pumpScreen(tester, types: [eWallet]);
      await openType(tester, 'E-wallet');

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(repository.deleted, isEmpty);
      expect(find.text('Edit account type'), findsOneWidget);
    });
  });

  group('editing a type in use', () {
    testWidgets('can be renamed; class is locked and not sent', (tester) async {
      await pumpScreen(
        tester,
        types: [payLater],
        accounts: [account('1', payLater)],
      );
      await openType(tester, 'Pay later');

      expect(
        find.text(
          'Liability: works like a credit card. 1 account uses this type, '
          "so its class can't change.",
        ),
        findsOneWidget,
      );
      expect(find.text('Delete'), findsNothing);
      final classButton = tester.widget<SegmentedButton<AccountClass>>(
        find.byType(SegmentedButton<AccountClass>),
      );
      expect(classButton.onSelectionChanged, isNull, reason: 'disabled');

      await tester.enterText(dialogName(), 'BNPL');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.updated.single, (
        id: payLater.id,
        name: 'BNPL',
        baseType: null,
      ));
    });

    testWidgets('shows a class change refused by the repository', (
      tester,
    ) async {
      // The type came into use after the screen loaded.
      await pumpScreen(tester, types: [payLater]);
      await openType(tester, 'Pay later');
      repository.failWith = CustomAccountTypeValidationError.baseTypeInUse;

      await tester.tap(find.text('Loan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text("Accounts use this type, so its class can't change."),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  testWidgets('shows a taken name on the name field', (tester) async {
    await pumpScreen(tester, types: [eWallet]);
    await openType(tester, 'E-wallet');
    repository.failWith = CustomAccountTypeValidationError.nameTaken;

    await tester.enterText(dialogName(), 'Loan');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('An account type with this name already exists.'),
      findsOneWidget,
    );
  });
}
