import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/presentation/account_detail_screen.dart';
import 'package:fundly/features/accounts/presentation/accounts_screen.dart';
import 'package:fundly/features/accounts/presentation/archived_accounts_screen.dart';

import '../../../helpers/provider_overrides.dart';

void main() {
  final oldWallet = Account(
    id: '9',
    name: 'Old Wallet',
    type: AccountType.savingsCash,
    openingBalance: const Money(minorUnits: 0, currencyCode: 'PHP'),
    createdAt: DateTime.utc(2026, 11, 16),
    isArchived: true,
  );

  testWidgets('opens from the Account tab and lists archived accounts', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeAccounts(const [], archived: [oldWallet]),
        child: const MaterialApp(home: AccountsScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Archived accounts'));
    await tester.pumpAndSettle();

    expect(find.byType(ArchivedAccountsScreen), findsOneWidget);
    expect(find.text('Old Wallet'), findsOneWidget);
    // Archived accounts are left out of totals (G7): only the row's
    // balance shows.
    expect(find.text('₱0.00'), findsOneWidget);

    await tester.tap(find.text('Old Wallet'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountDetailScreen), findsOneWidget);
    expect(find.text('Unarchive account'), findsOneWidget);
  });

  testWidgets('shows an empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: noAccounts(),
        child: const MaterialApp(home: ArchivedAccountsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('No archived accounts.'), findsOneWidget);
  });
}
