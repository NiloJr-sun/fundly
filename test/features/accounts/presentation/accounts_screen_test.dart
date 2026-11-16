import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/presentation/accounts_providers.dart';
import 'package:fundly/features/accounts/presentation/accounts_screen.dart';

import '../../../helpers/provider_overrides.dart';

Account account(int id, String name, AccountType type, int openingMinor) =>
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
  await tester.pump();
}

void main() {
  testWidgets('shows an empty state when there are no accounts', (
    tester,
  ) async {
    await pumpScreen(tester, fakeAccounts());

    expect(find.textContaining('No accounts yet.'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('groups accounts by type and shows formatted balances', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      fakeAccounts([
        account(1, 'BDO Savings', AccountType.savingsCash, 1500000),
        account(2, 'Cash Wallet', AccountType.savingsCash, 0),
        account(3, 'RCBC Credit', AccountType.credit, -300000),
        account(4, 'Car Loan', AccountType.loan, -5000000),
      ]),
    );

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .toList();
    expect(
      texts,
      containsAllInOrder([
        'Savings / Cash',
        'BDO Savings',
        '₱15,000.00',
        'Cash Wallet',
        '₱0.00',
        'Credit',
        'RCBC Credit',
        'Owed ₱3,000.00',
        'Loan',
        'Car Loan',
        'Owed ₱50,000.00',
      ]),
    );
  });

  testWidgets('omits sections for types with no accounts', (tester) async {
    await pumpScreen(
      tester,
      fakeAccounts([account(1, 'BDO Savings', AccountType.savingsCash, 0)]),
    );

    expect(find.text('Savings / Cash'), findsOneWidget);
    expect(find.text('Credit'), findsNothing);
    expect(find.text('Loan'), findsNothing);
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
}
