import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/accounts/presentation/account_form_screen.dart';
import 'package:fundly/features/accounts/presentation/accounts_screen.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/sync/presentation/edit_guard.dart';

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
  testWidgets('signed in, Add account explains instead of opening a form', (
    tester,
  ) async {
    await pumpAccounts(tester, _user);
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();

    expect(find.text(readOnlyMessage), findsOneWidget);
    expect(find.byType(AccountFormScreen), findsNothing);
  });

  testWidgets('signed out, Add account opens the form as before', (
    tester,
  ) async {
    await pumpAccounts(tester, const SignedOut());
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();

    expect(find.text(readOnlyMessage), findsNothing);
    expect(find.byType(AccountFormScreen), findsOneWidget);
  });
}
