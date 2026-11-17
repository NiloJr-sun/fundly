import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/presentation/account_detail_screen.dart';
import 'package:fundly/features/accounts/presentation/account_form_screen.dart';

import '../../../helpers/fake_account_repository.dart';
import '../../../helpers/provider_overrides.dart';

Account account({
  int id = 1,
  String name = 'BDO Savings',
  AccountType type = AccountType.savingsCash,
  int openingMinor = 0,
  bool isArchived = false,
}) => Account(
  id: id,
  name: name,
  type: type,
  openingBalance: Money(minorUnits: openingMinor, currencyCode: 'PHP'),
  createdAt: DateTime.utc(2026, 11, 16, 12),
  isArchived: isArchived,
);

void main() {
  late FakeAccountRepository repository;

  setUp(() => repository = FakeAccountRepository());

  /// Opens the detail screen from a placeholder page so archiving can pop.
  Future<void> openDetail(
    WidgetTester tester,
    List<Override> overrides, {
    int accountId = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AccountDetailScreen(accountId: accountId),
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

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('shows balance and account details', (tester) async {
    await openDetail(
      tester,
      fakeAccounts([
        account(
          name: 'RCBC Credit',
          type: AccountType.credit,
          openingMinor: -300000,
        ),
      ]),
    );

    expect(find.text('RCBC Credit'), findsOneWidget);
    expect(find.text('-₱3,000.00'), findsOneWidget);
    expect(find.text('Credit'), findsOneWidget);
    expect(find.text('PHP'), findsOneWidget);
    expect(find.text('Nov 16, 2026'), findsOneWidget);
    expect(find.text('No transactions yet.'), findsOneWidget);
    expect(find.text('Archived'), findsNothing);
  });

  testWidgets('says so when the account does not exist', (tester) async {
    await openDetail(tester, noAccounts(), accountId: 42);

    expect(find.text('This account no longer exists.'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsNothing);
  });

  testWidgets('Edit opens the form for this account', (tester) async {
    await openDetail(tester, fakeAccounts([account()]));

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountFormScreen), findsOneWidget);
    expect(find.text('Edit account'), findsOneWidget);
  });

  group('archiving', () {
    testWidgets('a zero-balance account archives without confirmation', (
      tester,
    ) async {
      await openDetail(
        tester,
        fakeAccounts([account()], repository: repository),
      );

      await tapButton(tester, 'Archive account');

      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.archivedChanges, [(id: 1, archived: true)]);
      expect(find.byType(AccountDetailScreen), findsNothing);
      expect(find.text('BDO Savings archived'), findsOneWidget);
    });

    testWidgets('an account with a balance asks first; Cancel keeps it', (
      tester,
    ) async {
      await openDetail(
        tester,
        fakeAccounts([account(openingMinor: 150000)], repository: repository),
      );

      await tapButton(tester, 'Archive account');

      expect(find.text('Archive this account?'), findsOneWidget);
      expect(find.textContaining('balance: ₱1,500.00'), findsOneWidget);

      await tapButton(tester, 'Cancel');

      expect(repository.archivedChanges, isEmpty);
      expect(find.byType(AccountDetailScreen), findsOneWidget);
    });

    testWidgets('confirming archives an account with money owed', (
      tester,
    ) async {
      await openDetail(
        tester,
        fakeAccounts([
          account(type: AccountType.loan, openingMinor: -5000000),
        ], repository: repository),
      );

      await tapButton(tester, 'Archive account');
      expect(find.textContaining('balance: -₱50,000.00'), findsOneWidget);
      await tapButton(tester, 'Archive');

      expect(repository.archivedChanges, [(id: 1, archived: true)]);
      expect(find.byType(AccountDetailScreen), findsNothing);
    });

    testWidgets('an archived account shows a label and can be unarchived', (
      tester,
    ) async {
      await openDetail(
        tester,
        fakeAccounts(
          const [],
          archived: [account(openingMinor: 100, isArchived: true)],
          repository: repository,
        ),
      );

      expect(find.text('Archived'), findsOneWidget);

      await tapButton(tester, 'Unarchive account');

      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.archivedChanges, [(id: 1, archived: false)]);
      expect(find.text('BDO Savings restored'), findsOneWidget);
    });
  });
}
