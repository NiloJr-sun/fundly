import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/accounts/presentation/account_form_screen.dart';
import 'package:fundly/features/accounts/presentation/accounts_screen.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/provider_overrides.dart';

const _user = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);

Future<void> pumpAccounts(WidgetTester tester, AuthIdentity identity) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...noAccounts(),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(initial: identity),
        ),
      ],
      child: const MaterialApp(home: AccountsScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  // Signed in, the synchronized store accepts changes (cloud sync S5.3), so
  // every entry point opens its form exactly as when signed out.
  for (final identity in [_user, const SignedOut()]) {
    testWidgets('${identity.runtimeType}: Add account opens the form', (
      tester,
    ) async {
      await pumpAccounts(tester, identity);
      await tester.tap(find.text('Add account'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountFormScreen), findsOneWidget);
    });
  }
}
