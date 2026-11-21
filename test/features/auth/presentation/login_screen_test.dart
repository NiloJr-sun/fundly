import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/app.dart';
import 'package:fundly/app/home_shell.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/data/local_use_choice.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/auth/presentation/login_screen.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/provider_overrides.dart';

const userA = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);

Future<void> pumpApp(
  WidgetTester tester, {
  AuthRepository auth = const LocalOnlyAuthRepository(),
  LocalUseChoiceStore? choice,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...noAccounts(),
        authRepositoryProvider.overrideWithValue(auth),
        if (choice != null)
          localUseChoiceStoreProvider.overrideWithValue(choice),
      ],
      child: const FundlyApp(),
    ),
  );
  await tester.pump();
}

final login = find.byType(LoginScreen);
final home = find.byType(HomeShell);
final accountTab = find.descendant(
  of: find.byType(NavigationBar),
  matching: find.text('Account'),
);

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> signOutFromAccountTab(WidgetTester tester) async {
  await tapAndSettle(tester, accountTab);
  await tapAndSettle(tester, find.byTooltip('More'));
  await tapAndSettle(tester, find.text('Sign out'));
  await tapAndSettle(tester, find.widgetWithText(TextButton, 'Sign out'));
}

void main() {
  group('without sign-in, the login page never shows', () {
    testWidgets('a build without cloud config opens the tabs', (tester) async {
      await pumpApp(tester);
      expect(login, findsNothing);
      expect(home, findsOneWidget);
    });

    testWidgets('a platform that cannot sign in opens the tabs', (
      tester,
    ) async {
      await pumpApp(tester, auth: FakeAuthRepository(canSignIn: false));
      expect(login, findsNothing);
      expect(home, findsOneWidget);
    });
  });

  testWidgets('signed out with cloud config starts on the login page', (
    tester,
  ) async {
    await pumpApp(tester, auth: FakeAuthRepository());

    expect(login, findsOneWidget);
    expect(home, findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Use without an account'), findsOneWidget);
  });

  testWidgets('Continue with Google signs in and opens that user\'s tabs', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..identityAfterSignIn = userA;
    await pumpApp(tester, auth: auth);
    await tapAndSettle(tester, find.text('Continue with Google'));

    expect(auth.signInCalls, 1);
    expect(login, findsNothing);
    expect(home, findsOneWidget);
  });

  testWidgets('a cancelled sign-in stays on the login page quietly', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..signInError = const SignInCancelled();
    await pumpApp(tester, auth: auth);
    await tapAndSettle(tester, find.text('Continue with Google'));

    expect(login, findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a failed sign-in explains why and can be retried', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..signInError = const SignInFailed('Google did not answer.');
    await pumpApp(tester, auth: auth);
    await tapAndSettle(tester, find.text('Continue with Google'));

    expect(login, findsOneWidget);
    expect(
      find.text('Could not sign in. Google did not answer.'),
      findsOneWidget,
    );

    auth
      ..signInError = null
      ..identityAfterSignIn = userA;
    await tapAndSettle(tester, find.text('Continue with Google'));
    expect(auth.signInCalls, 2);
    expect(home, findsOneWidget);
  });

  testWidgets('Use without an account opens local data and is remembered', (
    tester,
  ) async {
    final choice = InMemoryLocalUseChoiceStore();
    await pumpApp(tester, auth: FakeAuthRepository(), choice: choice);
    await tapAndSettle(tester, find.text('Use without an account'));

    expect(home, findsOneWidget);
    expect(choice.chosen, isTrue);
  });

  testWidgets('a remembered choice skips the login page at launch', (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(),
      choice: InMemoryLocalUseChoiceStore(chosen: true),
    );
    expect(login, findsNothing);
    expect(home, findsOneWidget);
  });

  testWidgets('a restored session opens the tabs and clears an old choice', (
    tester,
  ) async {
    final choice = InMemoryLocalUseChoiceStore(chosen: true);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(initial: userA),
      choice: choice,
    );
    expect(home, findsOneWidget);
    expect(choice.chosen, isFalse);
  });

  testWidgets('signing out returns to the login page', (tester) async {
    await pumpApp(tester, auth: FakeAuthRepository(initial: userA));
    await signOutFromAccountTab(tester);

    expect(login, findsOneWidget);
    expect(home, findsNothing);
  });

  testWidgets('signing in from local data, then out, returns to the login '
      'page', (tester) async {
    final auth = FakeAuthRepository()..identityAfterSignIn = userA;
    final choice = InMemoryLocalUseChoiceStore(chosen: true);
    await pumpApp(tester, auth: auth, choice: choice);

    await tapAndSettle(tester, accountTab);
    await tapAndSettle(tester, find.byTooltip('More'));
    await tapAndSettle(tester, find.text('Sign in with Google'));
    expect(choice.chosen, isFalse);
    // Signing in rebuilds the app from the first tab.
    await tapAndSettle(tester, accountTab);
    expect(find.text('Signed in as a@test.com · Not syncing yet'), findsOne);

    await signOutFromAccountTab(tester);
    expect(login, findsOneWidget);
  });

  testWidgets('a revoked session returns to the login page', (tester) async {
    final auth = FakeAuthRepository(initial: userA);
    await pumpApp(tester, auth: auth);
    auth.emit(const SignedOut());
    await tester.pumpAndSettle();

    expect(login, findsOneWidget);
  });
}
