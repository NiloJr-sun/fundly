import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/custom_bank.dart';
import 'package:fundly/features/accounts/presentation/account_detail_screen.dart';
import 'package:fundly/features/accounts/presentation/accounts_screen.dart';
import 'package:fundly/features/accounts/presentation/archived_accounts_screen.dart';
import 'package:fundly/features/accounts/presentation/bank_display.dart';

import '../../../helpers/provider_overrides.dart';

// Where bank logos show (docs/BANKS_PLAN.md, B-4, B-9).

Account account(
  String id,
  String name, {
  AccountType type = AccountType.savingsCash,
  String? bankKey,
  String? customBankId,
  bool archived = false,
}) => Account(
  id: id,
  name: name,
  type: type,
  openingBalance: const Money.zero('PHP'),
  createdAt: DateTime.utc(2026, 11, 25),
  bankKey: bankKey,
  customBankId: customBankId,
  isArchived: archived,
);

Finder logo(String name) => find.byWidgetPredicate(
  (widget) => widget is BankAvatar && widget.badge?.name == name,
);

Finder noBankIcon(IconData icon) => find.byWidgetPredicate(
  (widget) =>
      widget is BankAvatar &&
      widget.badge == null &&
      widget.fallbackIcon == icon,
);

void main() {
  final coop = CustomBank(
    id: '30',
    name: 'Town Coop',
    createdAt: DateTime.utc(2026, 11, 25),
  );

  Future<void> pump(
    WidgetTester tester,
    Widget home,
    List<Override> overrides,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the Account tab shows each account with its logo or type '
      'icon', (tester) async {
    await pump(
      tester,
      const AccountsScreen(),
      fakeAccounts(
        [
          account('1', 'BDO Savings', bankKey: 'bdo'),
          account('2', 'Coop Savings', customBankId: '30'),
          account('3', 'Cash Wallet'),
          account('4', 'Car Loan', type: AccountType.loan),
          account('5', 'Komo Savings', bankKey: 'komo'),
        ],
        customBanks: [coop],
      ),
    );

    expect(logo('BDO'), findsOneWidget);
    expect(logo('Town Coop'), findsOneWidget);
    expect(
      noBankIcon(Icons.account_balance_wallet_outlined),
      findsNWidgets(2),
      reason: 'the cash wallet, and an unknown key from a later app',
    );
    expect(noBankIcon(Icons.request_quote_outlined), findsOneWidget);
  });

  testWidgets('Archived accounts show logos too', (tester) async {
    await pump(
      tester,
      const ArchivedAccountsScreen(),
      fakeAccounts(
        const [],
        archived: [
          account(
            '1',
            'Old BPI Card',
            type: AccountType.credit,
            bankKey: 'bpi',
            archived: true,
          ),
        ],
      ),
    );

    expect(logo('BPI'), findsOneWidget);
  });

  testWidgets('the account detail header names the bank', (tester) async {
    await pump(
      tester,
      const AccountDetailScreen(accountId: '2'),
      fakeAccounts(
        [account('2', 'Coop Savings', customBankId: '30')],
        customBanks: [coop],
      ),
    );

    expect(logo('Town Coop'), findsOneWidget);
    expect(find.text('Town Coop'), findsOneWidget);
  });

  testWidgets('the detail header says No bank without one', (tester) async {
    await pump(
      tester,
      const AccountDetailScreen(accountId: '3'),
      fakeAccounts([account('3', 'Cash Wallet')]),
    );

    expect(find.text('No bank'), findsOneWidget);
  });
}
