import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/time/clock_provider.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/backup/presentation/restore_backup.dart';
import 'package:fundly/features/profile/presentation/profile_screen.dart';

import 'package:fundly/features/sync/presentation/edit_guard.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/provider_overrides.dart';

const userA = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'a@test.com',
);

Future<void> pumpProfile(
  WidgetTester tester, {
  AuthRepository auth = const LocalOnlyAuthRepository(),
  Future<String?> Function()? pickFile,
  DateTime? now,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...noAccounts(),
        authRepositoryProvider.overrideWithValue(auth),
        if (pickFile != null)
          pickBackupFileProvider.overrideWithValue(pickFile),
        if (now != null) clockProvider.overrideWithValue(() => now),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('a build without cloud config offers no sign-in', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Using Fundly as a guest'), findsOneWidget);
    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Restore from backup'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.text('Sign out'), findsNothing);
    expect(find.textContaining('Signed in as'), findsNothing);
  });

  testWidgets(
    'a guest with cloud config is greeted and offered Continue with Google',
    (tester) async {
      final auth = FakeAuthRepository();
      await pumpProfile(tester, auth: auth, now: DateTime(2026, 11, 22, 14));

      expect(find.text('Good afternoon'), findsOneWidget);
      expect(find.text('Using Fundly as a guest'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(auth.signInCalls, 1);
    },
  );

  testWidgets('signed in shows who and offers Sign out', (tester) async {
    await pumpProfile(tester, auth: FakeAuthRepository(initial: userA));

    expect(find.text('Signed in as a@test.com'), findsOneWidget);
    expect(find.text('Up to date · View only'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('the card greets the user by first name for the time of day', (
    tester,
  ) async {
    await pumpProfile(
      tester,
      auth: FakeAuthRepository(
        initial: const SignedIn(
          userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
          email: 'nilo@test.com',
          name: 'Nilo Castillano',
        ),
      ),
      now: DateTime(2026, 11, 22, 19, 30),
    );

    expect(find.text('Good evening, Nilo'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
    expect(find.text('Signed in as nilo@test.com'), findsOneWidget);
  });

  testWidgets('without a profile name the greeting stands alone', (
    tester,
  ) async {
    await pumpProfile(
      tester,
      auth: FakeAuthRepository(initial: userA),
      now: DateTime(2026, 11, 22, 8),
    );

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('a failed sign-in shows why and stays signed out', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..signInError = const SignInFailed('Google did not answer.');
    await pumpProfile(tester, auth: auth);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not sign in. Google did not answer.'),
      findsOneWidget,
    );
    expect(find.textContaining('Signed in as'), findsNothing);
  });

  testWidgets('a cancelled sign-in says nothing', (tester) async {
    final auth = FakeAuthRepository()..signInError = const SignInCancelled();
    await pumpProfile(tester, auth: auth);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.textContaining('Signed in as'), findsNothing);
  });

  testWidgets('sign-out asks first, and Cancel keeps the user signed in', (
    tester,
  ) async {
    final auth = FakeAuthRepository(initial: userA);
    await pumpProfile(tester, auth: auth);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(auth.signOutCalls, 0);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(auth.signOutCalls, 1);
    expect(find.textContaining('Signed in as'), findsNothing);
  });

  testWidgets('restore is blocked while signed in and never opens a file', (
    tester,
  ) async {
    var picked = 0;
    await pumpProfile(
      tester,
      auth: FakeAuthRepository(initial: userA),
      pickFile: () async {
        picked++;
        return null;
      },
    );
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
    await pumpProfile(
      tester,
      auth: FakeAuthRepository(),
      pickFile: () async {
        picked++;
        return null;
      },
    );
    await tester.tap(find.text('Restore from backup'));
    await tester.pumpAndSettle();

    expect(picked, 1);
  });

  testWidgets('export is unavailable while signed in and explains why', (
    tester,
  ) async {
    await pumpProfile(tester, auth: FakeAuthRepository(initial: userA));
    await tester.tap(find.text('Export backup'));
    await tester.pump();

    expect(find.text(signedInBackupMessage), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });
}
