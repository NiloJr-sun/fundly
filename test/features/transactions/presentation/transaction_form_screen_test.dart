import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/presentation/accounts_providers.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/categories/presentation/categories_providers.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction_rules.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';
import 'package:fundly/features/transactions/presentation/transaction_form_screen.dart';

import '../../../helpers/fake_transaction_repository.dart';
import '../domain/transaction_fixtures.dart';

void main() {
  late FakeTransactionRepository repository;

  setUp(() => repository = FakeTransactionRepository());

  final activeAccounts = [
    for (final account in accounts.values)
      if (!account.isArchived) account,
  ];
  List<Category> ofKind(CategoryKind kind) =>
      categories.values.where((c) => c.kind == kind).toList();

  /// Opens the form for [type] from a placeholder page so saving can pop.
  Future<void> openForm(
    WidgetTester tester,
    TransactionType type, {
    List<Account>? withAccounts,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeAccountsProvider.overrideWith(
            (ref) => Stream.value(withAccounts ?? activeAccounts),
          ),
          categoriesByKindProvider.overrideWith(
            (ref, kind) => Stream.value(ofKind(kind)),
          ),
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TransactionFormScreen(
                      type: type,
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

  Future<void> choose(WidgetTester tester, String label, String option) async {
    await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  group('Spending', () {
    testWidgets('saves a complete spending transaction', (tester) async {
      await openForm(tester, TransactionType.spending);
      expect(find.text('New Spending'), findsOneWidget);
      expect(find.text('Nov 16, 2026'), findsOneWidget, reason: 'today');

      await tester.enterText(field('Amount'), '1,250.50');
      await choose(tester, 'Paid from', 'RCBC Credit · Credit');
      await tester.enterText(field('Paid to'), ' Jollibee ');
      await choose(tester, 'Category', 'Food');
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
      await openForm(tester, TransactionType.spending);

      await save(tester);

      expect(find.text('Enter an amount.'), findsOneWidget);
      expect(find.text('Choose an account.'), findsOneWidget);
      expect(find.text('Enter who you paid.'), findsOneWidget);
      expect(find.text('Choose a category.'), findsOneWidget);
      expect(repository.created, isEmpty);
    });

    testWidgets('Rule 8: rejects a zero amount', (tester) async {
      await openForm(tester, TransactionType.spending);

      await tester.enterText(field('Amount'), '0');
      await save(tester);

      expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
    });

    testWidgets('offers only Savings/Cash and Credit accounts', (tester) async {
      await openForm(tester, TransactionType.spending);

      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<int>, 'Paid from'),
      );
      await tester.pumpAndSettle();

      expect(find.text('BDO Savings · Savings / Cash'), findsWidgets);
      expect(find.text('RCBC Credit · Credit'), findsWidgets);
      expect(find.text('Car Loan · Loan'), findsNothing);
      expect(find.text('Old Wallet · Savings / Cash'), findsNothing);
    });

    testWidgets('offers only spending categories', (tester) async {
      await openForm(tester, TransactionType.spending);

      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<int>, 'Category'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsWidgets);
      expect(find.text('Salary'), findsNothing);
    });

    testWidgets('a picked date is saved', (tester) async {
      await openForm(tester, TransactionType.spending);

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
        TransactionType.spending,
        withAccounts: [accounts[carLoanId]!],
      );

      expect(
        find.text('Add a Savings / Cash or Credit account first.'),
        findsOneWidget,
      );
    });

    testWidgets('shows errors the repository reports', (tester) async {
      repository.failWith = {TransactionValidationError.sourceAccountArchived};
      await openForm(tester, TransactionType.spending);

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
      await openForm(tester, TransactionType.inflow);
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
      await openForm(tester, TransactionType.inflow);

      await tester.enterText(field('Amount'), '100');
      await choose(tester, 'Deposited to', 'BDO Savings · Savings / Cash');
      await tester.enterText(field('Received from'), 'Employer');
      await choose(tester, 'Category (optional)', 'Salary');
      await save(tester);

      expect(repository.created.single.categoryId, salaryId);
    });

    testWidgets('asks who paid you', (tester) async {
      await openForm(tester, TransactionType.inflow);

      await save(tester);

      expect(find.text('Enter who paid you.'), findsOneWidget);
      expect(find.text('Choose a category.'), findsNothing);
    });
  });

  /// Opens the [label] dropdown and returns the account options it lists.
  Future<List<String>> optionsOf(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, label));
    await tester.pumpAndSettle();
    final options = tester
        .widgetList<DropdownMenuItem<int>>(find.byType(DropdownMenuItem<int>))
        .map((item) => ((item.child as Text).data!))
        .toSet()
        .toList();
    await tester.tapAt(Offset.zero); // close the menu
    await tester.pumpAndSettle();
    return options;
  }

  group('Transfer', () {
    testWidgets('moves money between asset accounts', (tester) async {
      await openForm(tester, TransactionType.transfer);
      expect(find.text('New Transfer'), findsOneWidget);
      expect(
        find.widgetWithText(DropdownButtonFormField<int>, 'Category'),
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

    testWidgets('G4: a loan payment is a transfer to the loan', (tester) async {
      await openForm(tester, TransactionType.transfer);

      await tester.enterText(field('Amount'), '5000');
      await choose(tester, 'From', 'BDO Savings · Savings / Cash');
      await choose(tester, 'To', 'Car Loan · Loan');
      await tester.enterText(field('Description (optional)'), 'November');
      await save(tester);

      final draft = repository.created.single;
      expect(draft.destinationAccountId, carLoanId);
      expect(draft.payee, 'November');
    });

    testWidgets('G5: offers no credit accounts as destination', (tester) async {
      await openForm(tester, TransactionType.transfer);

      expect(await optionsOf(tester, 'From'), [
        'BDO Savings · Savings / Cash',
        'Cash Wallet · Savings / Cash',
      ]);
      expect(await optionsOf(tester, 'To'), [
        'BDO Savings · Savings / Cash',
        'Cash Wallet · Savings / Cash',
        'Car Loan · Loan',
      ]);
    });

    testWidgets('Rule 7: rejects the same account on both sides', (
      tester,
    ) async {
      await openForm(tester, TransactionType.transfer);

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
      await openForm(tester, TransactionType.transfer);

      await tester.enterText(field('Amount'), '100');
      await save(tester);

      expect(find.text('Choose an account.'), findsNWidgets(2));
    });
  });

  group('Credit card payment', () {
    testWidgets('pays a card from a savings account', (tester) async {
      await openForm(tester, TransactionType.creditCardPayment);
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
      await openForm(tester, TransactionType.creditCardPayment);

      expect(await optionsOf(tester, 'To'), ['RCBC Credit · Credit']);
      expect(await optionsOf(tester, 'From'), [
        'BDO Savings · Savings / Cash',
        'Cash Wallet · Savings / Cash',
      ]);
    });

    testWidgets('explains when there is no credit account', (tester) async {
      await openForm(
        tester,
        TransactionType.creditCardPayment,
        withAccounts: [accounts[bdoId]!],
      );

      expect(find.text('Add a Credit account first.'), findsOneWidget);
    });
  });
}
