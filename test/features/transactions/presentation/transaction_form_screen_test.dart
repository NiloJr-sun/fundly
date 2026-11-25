import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/custom_account_type.dart';
import 'package:fundly/features/accounts/presentation/accounts_providers.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/categories/presentation/categories_providers.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_kind.dart';
import 'package:fundly/features/transactions/domain/transaction_rules.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';
import 'package:fundly/features/transactions/presentation/account_picker_field.dart';
import 'package:fundly/features/transactions/presentation/transaction_form_screen.dart';

import '../../../helpers/fake_transaction_repository.dart';
import '../../../helpers/provider_overrides.dart';
import '../domain/transaction_fixtures.dart';

void main() {
  late FakeTransactionRepository repository;

  setUp(() => repository = FakeTransactionRepository());

  List<Category> ofKind(CategoryKind kind) =>
      categories.values.where((c) => c.kind == kind).toList();

  /// Opens the form for [kind] (or [editing] an existing transaction of that
  /// kind) from a placeholder page so saving can pop.
  Future<void> openForm(
    WidgetTester tester,
    TransactionKind kind, {
    List<Account>? withAccounts,
    Transaction? editing,
    List<CustomAccountType> customTypes = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allAccountsProvider.overrideWith(
            (ref) => Stream.value(withAccounts ?? accounts.values.toList()),
          ),
          categoriesByKindProvider.overrideWith(
            (ref, kind) => Stream.value(ofKind(kind)),
          ),
          transactionRepositoryProvider.overrideWithValue(repository),
          ...fakeCustomAccountTypes(customTypes),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => editing != null
                        ? TransactionFormScreen.edit(
                            transaction: editing,
                            kind: kind,
                          )
                        : TransactionFormScreen(
                            kind: kind,
                            clock: () => DateTime(2026, 11, 16, 10),
                          ),
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

  Finder accountField(String label) =>
      find.widgetWithText(AccountPickerField, label);

  /// Picks [option] in the [label] field. An account option is written as
  /// "name · type", as the field shows it; its sheet lists the name.
  Future<void> choose(WidgetTester tester, String label, String option) async {
    final isAccount = accountField(label).evaluate().isNotEmpty;
    await tester.tap(
      isAccount
          ? accountField(label)
          : find.widgetWithText(DropdownButtonFormField<String>, label),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(isAccount ? option.split(' · ').first : option).last,
    );
    await tester.pumpAndSettle();
  }

  /// Opens the [label] account field and returns its options as
  /// "name · type", then closes the sheet.
  Future<List<String>> optionsOf(WidgetTester tester, String label) async {
    await tester.tap(accountField(label));
    await tester.pumpAndSettle();
    final options = tester
        .widgetList<ListTile>(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(ListTile),
          ),
        )
        .map(
          (tile) =>
              '${(tile.title! as Text).data} · ${(tile.subtitle! as Text).data}',
        )
        .toList();
    await tester.tapAt(Offset.zero); // close the sheet
    await tester.pumpAndSettle();
    return options;
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  group('Spending', () {
    testWidgets('a card purchase saves without a category (R.18)', (
      tester,
    ) async {
      const hint =
          'Optional. Its budgeted amount moves to the card on Plans; '
          'without a category it is not covered.';
      await openForm(tester, TransactionKind.spending);
      await choose(tester, 'Paid from', 'BDO Savings · Savings / Cash');
      expect(find.text(hint), findsNothing);
      expect(find.text('Category (optional)'), findsNothing);

      await choose(tester, 'Paid from', 'RCBC Credit · Credit');
      expect(find.text(hint), findsOneWidget);
      expect(find.text('Category (optional)'), findsOneWidget);
      await tester.enterText(field('Amount'), '100');
      await tester.enterText(field('Paid to'), '7/11');
      await save(tester);

      final draft = repository.created.single;
      expect(draft.sourceAccountId, rcbcCardId);
      expect(draft.categoryId, isNull);
    });

    testWidgets('a cash purchase still needs a category', (tester) async {
      await openForm(tester, TransactionKind.spending);
      await choose(tester, 'Paid from', 'BDO Savings · Savings / Cash');
      await tester.enterText(field('Amount'), '100');
      await tester.enterText(field('Paid to'), '7/11');
      await save(tester);

      expect(repository.created, isEmpty);
      expect(find.text('Choose a category.'), findsOneWidget);
    });

    testWidgets('saves a complete spending transaction', (tester) async {
      await openForm(tester, TransactionKind.spending);
      expect(find.text('New Spending'), findsOneWidget);
      expect(find.text('Nov 16, 2026'), findsOneWidget, reason: 'today');

      await tester.enterText(field('Amount'), '1,250.50');
      await choose(tester, 'Paid from', 'RCBC Credit · Credit');
      await tester.enterText(field('Paid to'), ' Jollibee ');
      // Optional for a card purchase (R.18), but still saved when chosen.
      await choose(tester, 'Category (optional)', 'Food');
      await tester.enterText(field('Note (optional)'), 'Lunch');
      await save(tester);

      final draft = repository.created.single;
      expect(draft.type, TransactionType.spending);
      expect(draft.amount, php(125050));
      expect(draft.date, CalendarDate(2026, 11, 16));
      expect(draft.sourceAccountId, rcbcCardId);
      expect(draft.destinationAccountId, isNull);
      expect(draft.payee, ' Jollibee ', reason: 'the repository trims');
      expect(draft.categoryId, foodId);
      expect(draft.note, 'Lunch');
      expect(find.byType(TransactionFormScreen), findsNothing);
      expect(find.text('Spending saved'), findsOneWidget);
    });

    testWidgets('shows every missing field at once and saves nothing', (
      tester,
    ) async {
      await openForm(tester, TransactionKind.spending);

      await save(tester);

      expect(find.text('Enter an amount.'), findsOneWidget);
      expect(find.text('Choose an account.'), findsOneWidget);
      expect(find.text('Enter who you paid.'), findsOneWidget);
      expect(find.text('Choose a category.'), findsOneWidget);
      expect(repository.created, isEmpty);
    });

    testWidgets('Rule 8: rejects a zero amount', (tester) async {
      await openForm(tester, TransactionKind.spending);

      await tester.enterText(field('Amount'), '0');
      await save(tester);

      expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
    });

    testWidgets('offers only Savings/Cash and Credit accounts', (tester) async {
      await openForm(tester, TransactionKind.spending);

      final options = await optionsOf(tester, 'Paid from');

      expect(options, contains('BDO Savings · Savings / Cash'));
      expect(options, contains('RCBC Credit · Credit'));
      expect(options, isNot(contains('Car Loan · Loan')));
      expect(
        options.where((option) => option.startsWith('Old Wallet')),
        isEmpty,
      );
    });

    testWidgets('offers only spending categories', (tester) async {
      await openForm(tester, TransactionKind.spending);

      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Category'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsWidgets);
      expect(find.text('Salary'), findsNothing);
    });

    testWidgets('hides archived categories', (tester) async {
      await openForm(tester, TransactionKind.spending);

      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Category'),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Gifts'), findsNothing);
    });

    testWidgets('a picked date is saved', (tester) async {
      await openForm(tester, TransactionKind.spending);

      await tester.tap(find.text('Nov 16, 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Nov 3, 2026'), findsOneWidget);

      await tester.enterText(field('Amount'), '10');
      await choose(tester, 'Paid from', 'BDO Savings · Savings / Cash');
      await tester.enterText(field('Paid to'), 'Grab');
      await choose(tester, 'Category', 'Food');
      await save(tester);

      expect(repository.created.single.date, CalendarDate(2026, 11, 3));
    });

    testWidgets('explains when no usable account exists', (tester) async {
      await openForm(
        tester,
        TransactionKind.spending,
        withAccounts: [accounts[carLoanId]!],
      );

      expect(
        find.text('Add a Savings / Cash or Credit account first.'),
        findsOneWidget,
      );
    });

    testWidgets('shows errors the repository reports', (tester) async {
      repository.failWith = {TransactionValidationError.sourceAccountArchived};
      await openForm(tester, TransactionKind.spending);

      await tester.enterText(field('Amount'), '10');
      await choose(tester, 'Paid from', 'BDO Savings · Savings / Cash');
      await tester.enterText(field('Paid to'), 'Grab');
      await choose(tester, 'Category', 'Food');
      await save(tester);

      expect(find.text('This account is archived.'), findsOneWidget);
      expect(find.byType(TransactionFormScreen), findsOneWidget);
    });
  });

  group('Inflow', () {
    testWidgets('saves without a category', (tester) async {
      await openForm(tester, TransactionKind.inflow);
      expect(find.text('New Inflow'), findsOneWidget);

      await tester.enterText(field('Amount'), '30000');
      await choose(tester, 'Deposited to', 'BDO Savings · Savings / Cash');
      await tester.enterText(field('Received from'), 'Employer');
      await save(tester);

      final draft = repository.created.single;
      expect(draft.type, TransactionType.inflow);
      expect(draft.amount, php(3000000));
      expect(draft.destinationAccountId, bdoId);
      expect(draft.sourceAccountId, isNull);
      expect(draft.categoryId, isNull);
      expect(find.text('Inflow saved'), findsOneWidget);
    });

    testWidgets('saves with an inflow category', (tester) async {
      await openForm(tester, TransactionKind.inflow);

      await tester.enterText(field('Amount'), '100');
      await choose(tester, 'Deposited to', 'BDO Savings · Savings / Cash');
      await tester.enterText(field('Received from'), 'Employer');
      await choose(tester, 'Category (optional)', 'Salary');
      await save(tester);

      expect(repository.created.single.categoryId, salaryId);
    });

    testWidgets('asks who paid you', (tester) async {
      await openForm(tester, TransactionKind.inflow);

      await save(tester);

      expect(find.text('Enter who paid you.'), findsOneWidget);
      expect(find.text('Choose a category.'), findsNothing);
    });
  });

  group('Account sheet', () {
    Finder sheetTile(String name) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.widgetWithText(ListTile, name),
    );

    testWidgets('searches by account name or type, and picks a result', (
      tester,
    ) async {
      await openForm(tester, TransactionKind.spending);
      await tester.tap(accountField('Paid from'));
      await tester.pumpAndSettle();
      expect(sheetTile('BDO Savings'), findsOneWidget);
      expect(sheetTile('RCBC Credit'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'bdo');
      await tester.pumpAndSettle();
      expect(sheetTile('BDO Savings'), findsOneWidget);
      expect(sheetTile('RCBC Credit'), findsNothing);

      await tester.enterText(find.byType(TextField).last, 'CREDIT');
      await tester.pumpAndSettle();
      expect(sheetTile('RCBC Credit'), findsOneWidget, reason: 'by type');
      expect(sheetTile('BDO Savings'), findsNothing);

      await tester.enterText(find.byType(TextField).last, 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No account matches "zzz".'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'rcbc');
      await tester.pumpAndSettle();
      await tester.tap(sheetTile('RCBC Credit'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('RCBC Credit · Credit'), findsOneWidget);
    });

    testWidgets('ticks the chosen account and keeps it when dismissed', (
      tester,
    ) async {
      await openForm(tester, TransactionKind.spending);
      await choose(tester, 'Paid from', 'BDO Savings · Savings / Cash');

      await tester.tap(accountField('Paid from'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: sheetTile('BDO Savings'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sheetTile('RCBC Credit'),
          matching: find.byIcon(Icons.check),
        ),
        findsNothing,
      );
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      expect(find.text('BDO Savings · Savings / Cash'), findsOneWidget);
    });
  });

  group('Transfer', () {
    testWidgets('moves money between asset accounts', (tester) async {
      await openForm(tester, TransactionKind.transfer);
      expect(find.text('New Transfer'), findsOneWidget);
      expect(
        find.widgetWithText(DropdownButtonFormField<String>, 'Category'),
        findsNothing,
      );

      await tester.enterText(field('Amount'), '2,000');
      await choose(tester, 'From', 'BDO Savings · Savings / Cash');
      await choose(tester, 'To', 'Cash Wallet · Savings / Cash');
      await save(tester);

      final draft = repository.created.single;
      expect(draft.type, TransactionType.transfer);
      expect(draft.amount, php(200000));
      expect(draft.sourceAccountId, bdoId);
      expect(draft.destinationAccountId, walletId);
      expect(draft.categoryId, isNull);
      expect(draft.payee, isEmpty, reason: 'description is optional');
      expect(find.text('Transfer saved'), findsOneWidget);
    });

    testWidgets('G5: offers no credit or loan accounts as destination', (
      tester,
    ) async {
      await openForm(tester, TransactionKind.transfer);

      expect(await optionsOf(tester, 'From'), [
        'BDO Savings · Savings / Cash',
        'Cash Wallet · Savings / Cash',
        'RCBC Credit · Credit',
      ]);
      // Loans are paid with Loan payment.
      expect(await optionsOf(tester, 'To'), [
        'BDO Savings · Savings / Cash',
        'Cash Wallet · Savings / Cash',
      ]);
    });

    testWidgets('a cash advance goes from a credit account to Savings/Cash', (
      tester,
    ) async {
      await openForm(tester, TransactionKind.transfer);

      await tester.enterText(field('Amount'), '2,600');
      await choose(tester, 'From', 'RCBC Credit · Credit');
      // The list also holds the chosen From account, so check what is left out.
      final destinations = await optionsOf(tester, 'To');
      expect(destinations, contains('BDO Savings · Savings / Cash'));
      expect(destinations, contains('Cash Wallet · Savings / Cash'));
      expect(destinations, isNot(contains('Car Loan · Loan')));
      await choose(tester, 'To', 'BDO Savings · Savings / Cash');
      await save(tester);

      final draft = repository.created.single;
      expect(draft.type, TransactionType.transfer);
      expect(draft.amount, php(260000));
      expect(draft.sourceAccountId, rcbcCardId);
      expect(draft.destinationAccountId, bdoId);
    });

    testWidgets('choosing a credit source keeps a Savings/Cash destination', (
      tester,
    ) async {
      await openForm(tester, TransactionKind.transfer);

      await tester.enterText(field('Amount'), '100');
      await choose(tester, 'From', 'BDO Savings · Savings / Cash');
      await choose(tester, 'To', 'Cash Wallet · Savings / Cash');
      await choose(tester, 'From', 'RCBC Credit · Credit');
      await save(tester);

      expect(repository.created.single.destinationAccountId, walletId);
    });

    testWidgets('Rule 7: rejects the same account on both sides', (
      tester,
    ) async {
      await openForm(tester, TransactionKind.transfer);

      await tester.enterText(field('Amount'), '100');
      await choose(tester, 'From', 'BDO Savings · Savings / Cash');
      await choose(tester, 'To', 'BDO Savings · Savings / Cash');
      await save(tester);

      expect(
        find.text("Choose a different account from the 'From' account."),
        findsOneWidget,
      );
      expect(repository.created, isEmpty);
    });

    testWidgets('requires both accounts', (tester) async {
      await openForm(tester, TransactionKind.transfer);

      await tester.enterText(field('Amount'), '100');
      await save(tester);

      expect(find.text('Choose an account.'), findsNWidgets(2));
    });
  });

  group('Loan payment', () {
    testWidgets('G4: saves a transfer from Savings/Cash to the loan', (
      tester,
    ) async {
      await openForm(tester, TransactionKind.loanPayment);
      expect(find.text('New Loan payment'), findsOneWidget);

      await tester.enterText(field('Amount'), '5000');
      await choose(tester, 'From', 'BDO Savings · Savings / Cash');
      await choose(tester, 'To', 'Car Loan · Loan');
      await tester.enterText(field('Description (optional)'), 'November');
      await save(tester);

      final draft = repository.created.single;
      expect(draft.type, TransactionType.transfer);
      expect(draft.amount, php(500000));
      expect(draft.sourceAccountId, bdoId);
      expect(draft.destinationAccountId, carLoanId);
      expect(draft.categoryId, isNull);
      expect(draft.payee, 'November');
      expect(find.text('Loan payment saved'), findsOneWidget);
    });

    testWidgets('offers only Savings/Cash sources and loan destinations', (
      tester,
    ) async {
      await openForm(tester, TransactionKind.loanPayment);

      expect(await optionsOf(tester, 'From'), [
        'BDO Savings · Savings / Cash',
        'Cash Wallet · Savings / Cash',
      ]);
      expect(await optionsOf(tester, 'To'), ['Car Loan · Loan']);
    });

    testWidgets('explains when there is no loan account', (tester) async {
      await openForm(
        tester,
        TransactionKind.loanPayment,
        withAccounts: [accounts[bdoId]!],
      );

      expect(find.text('Add a Loan account first.'), findsOneWidget);
    });

    testWidgets('edits an existing transfer into a loan', (tester) async {
      final payment = saved(
        transfer(from: bdoId, to: carLoanId, amount: 500000),
        id: '12',
      );
      await openForm(tester, TransactionKind.loanPayment, editing: payment);

      expect(find.text('Edit Loan payment'), findsOneWidget);
      expect(find.text('Car Loan · Loan'), findsOneWidget);

      await tester.enterText(field('Amount'), '6000');
      await save(tester);

      final update = repository.updated.single;
      expect(update.draft.type, TransactionType.transfer);
      expect(update.draft.destinationAccountId, carLoanId);
      expect(update.draft.amount, php(600000));
    });
  });

  group('Credit card payment', () {
    testWidgets('pays a card from a savings account', (tester) async {
      await openForm(tester, TransactionKind.creditCardPayment);
      expect(find.text('New Credit card payment'), findsOneWidget);

      await tester.enterText(field('Amount'), '3,000');
      await choose(tester, 'From', 'BDO Savings · Savings / Cash');
      await choose(tester, 'To', 'RCBC Credit · Credit');
      await save(tester);

      final draft = repository.created.single;
      expect(draft.type, TransactionType.creditCardPayment);
      expect(draft.amount, php(300000));
      expect(draft.sourceAccountId, bdoId);
      expect(draft.destinationAccountId, rcbcCardId);
      expect(draft.categoryId, isNull);
      expect(find.text('Credit card payment saved'), findsOneWidget);
    });

    testWidgets('offers only credit accounts as destination', (tester) async {
      await openForm(tester, TransactionKind.creditCardPayment);

      expect(await optionsOf(tester, 'To'), ['RCBC Credit · Credit']);
      expect(await optionsOf(tester, 'From'), [
        'BDO Savings · Savings / Cash',
        'Cash Wallet · Savings / Cash',
      ]);
    });

    testWidgets('explains when there is no credit account', (tester) async {
      await openForm(
        tester,
        TransactionKind.creditCardPayment,
        withAccounts: [accounts[bdoId]!],
      );

      expect(find.text('Add a Credit account first.'), findsOneWidget);
    });

    testWidgets('names custom types that would work too', (tester) async {
      await openForm(
        tester,
        TransactionKind.creditCardPayment,
        withAccounts: [accounts[bdoId]!],
        customTypes: [
          CustomAccountType(
            id: '10',
            name: 'Pay later',
            baseType: AccountType.credit,
            createdAt: DateTime.utc(2026, 11, 17),
          ),
          CustomAccountType(
            id: '11',
            name: 'Debt',
            baseType: AccountType.loan,
            createdAt: DateTime.utc(2026, 11, 17),
          ),
        ],
      );

      expect(find.text('Add a Credit or Pay later account first.'), findsOne);
    });
  });

  group('Editing', () {
    final original = saved(
      spending(
        amount: 50000,
        from: bdoId,
        payee: 'SM Supermarket',
        date: CalendarDate(2026, 11, 2),
        note: 'Weekly',
      ),
      id: '7',
    );

    testWidgets('fills in the existing values', (tester) async {
      await openForm(tester, TransactionKind.spending, editing: original);

      expect(find.text('Edit Spending'), findsOneWidget);
      expect(find.text('500.00'), findsOneWidget);
      expect(find.text('Nov 2, 2026'), findsOneWidget);
      expect(find.text('BDO Savings · Savings / Cash'), findsOneWidget);
      expect(find.text('SM Supermarket'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
    });

    testWidgets('saves changes with update, keeping the type', (tester) async {
      await openForm(tester, TransactionKind.spending, editing: original);

      await tester.enterText(field('Amount'), '750');
      await choose(tester, 'Paid from', 'RCBC Credit · Credit');
      await save(tester);

      expect(repository.created, isEmpty);
      final update = repository.updated.single;
      expect(update.id, '7');
      expect(update.draft.type, TransactionType.spending);
      expect(update.draft.amount, php(75000));
      expect(update.draft.sourceAccountId, rcbcCardId);
      expect(update.draft.date, CalendarDate(2026, 11, 2));
      expect(find.text('Changes saved'), findsOneWidget);
      expect(find.byType(TransactionFormScreen), findsNothing);
    });

    testWidgets('G7: keeps an archived account the transaction uses', (
      tester,
    ) async {
      final fromOld = saved(spending(from: oldWalletId), id: '8');
      await openForm(tester, TransactionKind.spending, editing: fromOld);

      expect(
        find.text('Old Wallet · Savings / Cash (archived)'),
        findsOneWidget,
      );

      await tester.enterText(field('Amount'), '1');
      await save(tester);

      expect(repository.updated.single.draft.sourceAccountId, oldWalletId);
    });

    testWidgets('keeps an archived category the transaction uses', (
      tester,
    ) async {
      final gift = saved(spending(category: giftsId), id: '9');
      await openForm(tester, TransactionKind.spending, editing: gift);

      expect(find.text('Gifts (archived)'), findsOneWidget);

      await tester.enterText(field('Amount'), '1');
      await save(tester);

      expect(repository.updated.single.draft.categoryId, giftsId);
    });

    testWidgets('validates edits like new transactions', (tester) async {
      await openForm(tester, TransactionKind.spending, editing: original);

      await tester.enterText(field('Amount'), '0');
      await tester.enterText(field('Paid to'), '');
      await save(tester);

      expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
      expect(find.text('Enter who you paid.'), findsOneWidget);
      expect(repository.updated, isEmpty);
    });
  });
}
