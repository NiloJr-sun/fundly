import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/custom_account_type.dart';
import 'package:fundly/features/accounts/presentation/account_detail_screen.dart';
import 'package:fundly/features/accounts/presentation/account_form_screen.dart';
import 'package:fundly/features/accounts/presentation/accounts_providers.dart';
import 'package:fundly/features/accounts/presentation/accounts_screen.dart';

import '../../../helpers/provider_overrides.dart';

Account account(String id, String name, AccountType type, int openingMinor) =>
    Account(
      id: id,
      name: name,
      type: type,
      openingBalance: Money(minorUnits: openingMinor, currencyCode: 'PHP'),
      createdAt: DateTime.utc(2026, 11, 16),
    );

Future<void> pumpScreen(WidgetTester tester, List<Override> overrides) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      // Show errors immediately instead of retrying in the background.
      retry: (_, _) => null,
      child: const MaterialApp(home: AccountsScreen()),
    ),
  );
  // One frame for the accounts, one for the custom types the list waits for.
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows an empty state when there are no accounts', (
    tester,
  ) async {
    await pumpScreen(tester, noAccounts());

    expect(find.textContaining('No accounts yet.'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('groups accounts by type and shows formatted balances', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      fakeAccounts([
        account('1', 'BDO Savings', AccountType.savingsCash, 1500000),
        account('2', 'Cash Wallet', AccountType.savingsCash, 0),
        account('3', 'RCBC Credit', AccountType.credit, -300000),
        account('4', 'Car Loan', AccountType.loan, -5000000),
      ]),
    );

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .toList();
    expect(
      texts,
      containsAllInOrder([
        'Assets',
        'Savings / Cash',
        'BDO Savings',
        '₱15,000.00',
        'Cash Wallet',
        '₱0.00',
        'Liabilities',
        'Credit',
        'RCBC Credit',
        '-₱3,000.00',
        'Loan',
        'Car Loan',
        '-₱50,000.00',
      ]),
    );
  });

  group('sections', () {
    final mixed = [
      account('1', 'BDO Savings', AccountType.savingsCash, 1500000),
      account('2', 'Cash Wallet', AccountType.savingsCash, 250050),
      account('3', 'RCBC Credit', AccountType.credit, -300000),
      account('4', 'BPI Credit', AccountType.credit, -125000),
      account('5', 'Car Loan', AccountType.loan, -5000000),
    ];

    /// The text on the right of the [title] section header.
    String headerTotal(WidgetTester tester, String title) {
      final header = find.ancestor(
        of: find.text(title),
        matching: find.byType(ListTile),
      );
      return tester
          .widgetList<Text>(
            find.descendant(of: header, matching: find.byType(Text)),
          )
          .map((text) => text.data)
          .singleWhere((data) => data != title)!;
    }

    testWidgets('show the total of their accounts', (tester) async {
      await pumpScreen(tester, fakeAccounts(mixed));
      await tester.pumpAndSettle();

      expect(headerTotal(tester, 'Savings / Cash'), '₱17,500.50');
      expect(headerTotal(tester, 'Credit'), '-₱4,250.00');
      expect(headerTotal(tester, 'Loan'), '-₱50,000.00');
    });

    testWidgets('collapse and expand, keeping the total', (tester) async {
      await pumpScreen(tester, fakeAccounts(mixed));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Credit'));
      await tester.pumpAndSettle();

      expect(find.text('RCBC Credit'), findsNothing);
      expect(find.text('BPI Credit'), findsNothing);
      expect(headerTotal(tester, 'Credit'), '-₱4,250.00');
      // Other sections stay open.
      expect(find.text('BDO Savings'), findsOneWidget);
      expect(find.text('Car Loan'), findsOneWidget);

      await tester.tap(find.text('Credit'));
      await tester.pumpAndSettle();

      expect(find.text('RCBC Credit'), findsOneWidget);
    });
  });

  testWidgets('labels the budget account', (tester) async {
    await pumpScreen(
      tester,
      fakeAccounts([
        Account(
          id: '1',
          name: 'BDO Savings',
          type: AccountType.savingsCash,
          openingBalance: const Money(minorUnits: 0, currencyCode: 'PHP'),
          createdAt: DateTime.utc(2026, 11, 16),
          isBudgetAccount: true,
        ),
        account('2', 'Cash Wallet', AccountType.savingsCash, 0),
      ]),
    );

    String? subtitleOf(String name) =>
        (tester.widget<ListTile>(find.widgetWithText(ListTile, name)).subtitle
                as Text?)
            ?.data;
    expect(subtitleOf('BDO Savings'), 'Budget account');
    expect(subtitleOf('Cash Wallet'), isNull);
  });

  testWidgets('omits sections for types with no accounts', (tester) async {
    await pumpScreen(
      tester,
      fakeAccounts([account('1', 'BDO Savings', AccountType.savingsCash, 0)]),
    );

    expect(find.text('Assets'), findsOneWidget);
    expect(find.text('Savings / Cash'), findsOneWidget);
    expect(find.text('Liabilities'), findsNothing);
    expect(find.text('Credit'), findsNothing);
    expect(find.text('Loan'), findsNothing);
  });

  group('custom account types', () {
    final eWallet = CustomAccountType(
      id: '10',
      name: 'E-wallet',
      baseType: AccountType.savingsCash,
      createdAt: DateTime.utc(2026, 11, 17),
    );
    final payLater = CustomAccountType(
      id: '11',
      name: 'Pay later',
      baseType: AccountType.credit,
      createdAt: DateTime.utc(2026, 11, 17),
    );
    final debt = CustomAccountType(
      id: '12',
      name: 'Debt',
      baseType: AccountType.loan,
      createdAt: DateTime.utc(2026, 11, 17),
    );

    Account custom(Account account, CustomAccountType type) => Account(
      id: account.id,
      name: account.name,
      type: account.type,
      openingBalance: account.openingBalance,
      createdAt: account.createdAt,
      customTypeId: type.id,
    );

    testWidgets('get their own section under their class, with a total', (
      tester,
    ) async {
      // Tall enough for every section; the list builds only visible rows.
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpScreen(
        tester,
        fakeAccounts(
          [
            account('1', 'BDO Savings', AccountType.savingsCash, 1500000),
            custom(
              account('2', 'GCash', AccountType.savingsCash, 120000),
              eWallet,
            ),
            custom(
              account('3', 'Maya', AccountType.savingsCash, 30000),
              eWallet,
            ),
            account('4', 'RCBC Credit', AccountType.credit, -300000),
            custom(
              account('5', 'SPayLater', AccountType.credit, -50000),
              payLater,
            ),
            custom(account('6', 'From Mom', AccountType.loan, -1000000), debt),
          ],
          customTypes: [debt, eWallet, payLater],
        ),
      );

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .toList();
      expect(
        texts,
        containsAllInOrder([
          'Assets',
          'Savings / Cash',
          '₱15,000.00',
          'BDO Savings',
          'E-wallet',
          '₱1,500.00',
          'GCash',
          'Maya',
          'Liabilities',
          'Credit',
          'RCBC Credit',
          // Built-in types first, then custom types by name.
          'Debt',
          '-₱10,000.00',
          'From Mom',
          'Pay later',
          '-₱500.00',
          'SPayLater',
        ]),
      );
      expect(find.text('Loan'), findsNothing, reason: 'no Loan accounts');
    });

    testWidgets('a class shows only when it has accounts', (tester) async {
      await pumpScreen(
        tester,
        fakeAccounts(
          [custom(account('1', 'GCash', AccountType.savingsCash, 0), eWallet)],
          customTypes: [eWallet, payLater],
        ),
      );

      expect(find.text('Assets'), findsOneWidget);
      expect(find.text('E-wallet'), findsOneWidget);
      expect(find.text('Savings / Cash'), findsNothing);
      expect(find.text('Liabilities'), findsNothing);
      expect(find.text('Pay later'), findsNothing);
    });
  });

  testWidgets('shows a progress indicator while loading', (tester) async {
    final neverEmits = StreamController<List<Account>>();
    addTearDown(neverEmits.close);

    await pumpScreen(tester, [
      activeAccountsProvider.overrideWith((ref) => neverEmits.stream),
    ]);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error message when loading fails', (tester) async {
    await pumpScreen(tester, [
      activeAccountsProvider.overrideWith(
        (ref) => Stream<List<Account>>.error(Exception('disk full')),
      ),
    ]);

    expect(find.textContaining('could not be loaded'), findsOneWidget);
  });

  testWidgets('the Add account button opens the form', (tester) async {
    await pumpScreen(tester, noAccounts());

    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountFormScreen), findsOneWidget);
    expect(find.text('New account'), findsOneWidget);
  });

  testWidgets('tapping an account opens its details', (tester) async {
    await pumpScreen(
      tester,
      fakeAccounts([account('1', 'BDO Savings', AccountType.savingsCash, 0)]),
    );

    await tester.tap(find.text('BDO Savings'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountDetailScreen), findsOneWidget);
  });
}
