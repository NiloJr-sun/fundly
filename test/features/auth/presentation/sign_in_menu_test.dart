import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/app.dart';
import 'package:fundly/features/accounts/presentation/accounts_screen.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/backup/presentation/restore_backup.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/provider_overrides.dart';

const userA = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);

Future<void> pumpAccounts(
  WidgetTester tester, {
  AuthRepository auth = const LocalOnlyAuthRepository(),
  Future<String?> Function()? pickFile,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...noAccounts(),
        authRepositoryProvider.overrideWithValue(auth),
        if (pickFile != null)
          pickBackupFileProvider.overrideWithValue(pickFile),
      ],
      child: const MaterialApp(home: AccountsScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> openMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('More'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a build without cloud config offers no sign-in', (tester) async {
    await pumpAccounts(tester);
    await openMenu(tester);

    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Restore from backup'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
    expect(find.text('Sign out'), findsNothing);
    expect(find.textContaining('Signed in as'), findsNothing);
  });

  testWidgets('signed out with cloud config offers Sign in with Google', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpAccounts(tester, auth: auth);
    await openMenu(tester);

    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);

    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();
    expect(auth.signInCalls, 1);
  });

  testWidgets('signed in shows who and offers Sign out', (tester) async {
    await pumpAccounts(tester, auth: FakeAuthRepository(initial: userA));

    expect(
      find.text('Signed in as a@test.com · Not syncing yet'),
      findsOneWidget,
    );
    await openMenu(tester);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
  });

  testWidgets('a failed sign-in shows why and stays signed out', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..signInError = const SignInFailed('Google did not answer.');
    await pumpAccounts(tester, auth: auth);
    await openMenu(tester);
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not sign in. Google did not answer.'),
      findsOneWidget,
    );
    expect(find.textContaining('Signed in as'), findsNothing);
  });

  testWidgets('a cancelled sign-in says nothing', (tester) async {
    final auth = FakeAuthRepository()..signInError = const SignInCancelled();
    await pumpAccounts(tester, auth: auth);
    await openMenu(tester);
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.textContaining('Signed in as'), findsNothing);
  });

  testWidgets('sign-out asks first, and Cancel keeps the user signed in', (
    tester,
  ) async {
    final auth = FakeAuthRepository(initial: userA);
    await pumpAccounts(tester, auth: auth);
    await openMenu(tester);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(auth.signOutCalls, 0);

    await openMenu(tester);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(auth.signOutCalls, 1);
    expect(find.textContaining('Signed in as'), findsNothing);
  });

  testWidgets('restore is blocked while signed in and never opens a file', (
    tester,
  ) async {
    var picked = 0;
    await pumpAccounts(
      tester,
      auth: FakeAuthRepository(initial: userA),
      pickFile: () async {
        picked++;
        return null;
      },
    );
    await openMenu(tester);
    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();

    expect(
      find.text('Restore is not available while signed in'),
      findsOneWidget,
    );
    expect(picked, 0);
  });

  testWidgets('restore still opens the file picker while signed out', (
    tester,
  ) async {
    var picked = 0;
    await pumpAccounts(
      tester,
      auth: FakeAuthRepository(),
      pickFile: () async {
        picked++;
        return null;
      },
    );
    await openMenu(tester);
    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();

    expect(picked, 1);
  });

  testWidgets('switching identity closes open screens and returns home', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    // Signed out opens the login page; keep its wallet still so the screen
    // can settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...noAccounts(),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: const FundlyApp(),
      ),
    );
    await tester.pump();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Previous user screen')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Previous user screen'), findsOneWidget);

    auth.emit(userA);
    await tester.pumpAndSettle();
    expect(find.text('Previous user screen'), findsNothing);
  });
}
