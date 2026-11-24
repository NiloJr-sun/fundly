import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/app.dart';
import 'package:fundly/app/app_version.dart';
import 'package:fundly/app/home_shell.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/data/local_use_choice.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/auth/presentation/animated_wallet.dart';
import 'package:fundly/features/auth/presentation/login_screen.dart';
import 'package:fundly/features/profile/presentation/profile_screen.dart';

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
  bool reduceMotion = true,
}) async {
  // An iPhone-sized screen, so the whole login page fits as it does on device.
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // The wallet floats forever, so flows that wait for the screen to settle
  // run with Reduce Motion on; the animation tests turn it off.
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
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
final profileTab = find.descendant(
  of: find.byType(NavigationBar),
  matching: find.text('Profile'),
);

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> signOutFromProfileTab(WidgetTester tester) async {
  await tapAndSettle(tester, profileTab);
  // To the version line, below Sign out, so the row is clear of the
  // navigation bar.
  await tester.scrollUntilVisible(
    find.text(appVersionText),
    200,
    scrollable: find
        .descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tapAndSettle(tester, find.text('Sign out'));
  await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Sign out'));
}

/// How visible [text] is: its nearest fade's opacity.
double opacityOf(WidgetTester tester, String text) => tester
    .widget<FadeTransition>(
      find
          .ancestor(of: find.text(text), matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

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
    expect(find.text('Explore as a guest'), findsOneWidget);
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

  testWidgets('Explore as a guest opens local data and is remembered', (
    tester,
  ) async {
    final choice = InMemoryLocalUseChoiceStore();
    await pumpApp(tester, auth: FakeAuthRepository(), choice: choice);
    await tapAndSettle(tester, find.text('Explore as a guest'));

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
    await signOutFromProfileTab(tester);

    expect(login, findsOneWidget);
    expect(home, findsNothing);
  });

  testWidgets('signing in from local data, then out, returns to the login '
      'page', (tester) async {
    final auth = FakeAuthRepository()..identityAfterSignIn = userA;
    final choice = InMemoryLocalUseChoiceStore(chosen: true);
    await pumpApp(tester, auth: auth, choice: choice);

    await tapAndSettle(tester, profileTab);
    await tapAndSettle(tester, find.text('Continue with Google'));
    expect(choice.chosen, isFalse);
    // Signing in rebuilds the app from the first tab.
    await tapAndSettle(tester, profileTab);
    expect(find.text('a@test.com'), findsOne);

    await signOutFromProfileTab(tester);
    expect(login, findsOneWidget);
  });

  testWidgets('a revoked session returns to the login page', (tester) async {
    final auth = FakeAuthRepository(initial: userA);
    await pumpApp(tester, auth: auth);
    auth.emit(const SignedOut());
    await tester.pumpAndSettle();

    expect(login, findsOneWidget);
  });

  group('wallet animation', () {
    testWidgets('the text fades in after the wallet, then the wallet floats', (
      tester,
    ) async {
      await pumpApp(tester, auth: FakeAuthRepository(), reduceMotion: false);

      expect(find.byType(AnimatedWallet), findsOneWidget);
      expect(opacityOf(tester, 'Fundly'), 0);

      await tester.pump(const Duration(milliseconds: 2600));
      expect(opacityOf(tester, 'Fundly'), 1);
      expect(opacityOf(tester, 'Your money, your way.'), 1);

      // The gentle float keeps going after the intro.
      await tester.pump(const Duration(seconds: 2));
      expect(tester.hasRunningAnimations, isTrue);

      // Buttons work while it moves.
      await tester.tap(find.text('Explore as a guest'));
      await tester.pump();
      await tester.pump();
      expect(home, findsOneWidget);
    });

    testWidgets('with Reduce Motion everything shows at once and stays still', (
      tester,
    ) async {
      await pumpApp(tester, auth: FakeAuthRepository());

      expect(opacityOf(tester, 'Fundly'), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
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
