import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/backup/data/device_data_copier.dart';
import 'package:fundly/features/profile/presentation/profile_screen.dart';
import 'package:fundly/features/spaces/data/active_space.dart';
import 'package:fundly/features/spaces/data/active_space_store.dart';
import 'package:fundly/features/spaces/data/sharing_service.dart';
import 'package:fundly/features/spaces/data/space_directory.dart';
import 'package:fundly/features/spaces/data/space_service.dart';
import 'package:fundly/features/spaces/domain/space.dart';
import 'package:fundly/features/spaces/domain/space_invite.dart';
import 'package:fundly/features/spaces/domain/space_member.dart';
import 'package:fundly/features/spaces/presentation/join_space.dart';
import 'package:fundly/features/spaces/presentation/members_screen.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_sharing_service.dart';
import '../../helpers/provider_overrides.dart';
import 'space_ui_test.dart'
    show
        FakeSpaceService,
        business,
        businessId,
        household,
        householdId,
        personal,
        user;

const bea = SpaceMember(
  userId: '9b8a7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d',
  role: SpaceRole.editor,
  email: 'bea@test.com',
  displayName: 'Bea',
);
const you = SpaceMember(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  role: SpaceRole.owner,
  email: 'nilo@test.com',
  displayName: 'Nilo',
);

void main() {
  late FakeSharingService sharing;

  setUp(() => sharing = FakeSharingService());

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    AuthIdentity identity = user,
    String? pageInvite,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeAccounts(
            const [],
            spaces: const [personal, business, household],
          ),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(initial: identity),
          ),
          initialInviteSecretProvider.overrideWithValue(pageInvite),
          activeSpaceStoreProvider.overrideWithValue(
            InMemoryActiveSpaceStore(),
          ),
          spaceServiceProvider.overrideWithValue(FakeSpaceService()),
          sharingServiceProvider.overrideWithValue(sharing),
          deviceHasDataProvider.overrideWith((ref) async => false),
          spaceMembersProvider.overrideWith(
            (ref, spaceId) => Stream.value(
              spaceId == householdId
                  ? [
                      bea.withRole(SpaceRole.owner),
                      you.withRole(SpaceRole.editor),
                    ]
                  : [you, bea],
            ),
          ),
        ],
        child: MaterialApp(home: home),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> openMenu(WidgetTester tester, String space) async {
    await pump(tester, const ProfileScreen());
    await tester.tap(find.byKey(const Key('space-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for $space'));
    await tester.pumpAndSettle();
  }

  const allActions = [
    'Members',
    'Invite',
    'Rename',
    'Leave space',
    'Delete space',
  ];

  group('space menu', () {
    for (final (space, shown) in [
      ('Personal', ['Rename']),
      ('Business', allActions),
      ('Household', ['Members', 'Leave space']),
    ]) {
      testWidgets('$space offers ${shown.join(', ')}', (tester) async {
        await openMenu(tester, space);
        for (final action in allActions) {
          expect(
            find.text(action),
            shown.contains(action) ? findsOneWidget : findsNothing,
            reason: action,
          );
        }
      });
    }
  });

  group('invite', () {
    Future<void> openInvite(WidgetTester tester) async {
      await openMenu(tester, 'Business');
      await tester.tap(find.text('Invite'));
      await tester.pumpAndSettle();
    }

    testWidgets('checks the email before asking the server', (tester) async {
      await openInvite(tester);
      await tester.enterText(find.byType(TextField), 'not an email');
      await tester.tap(find.text('Create link'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email'), findsOneWidget);

      await tester.enterText(find.byType(TextField), ' BEA@test.com ');
      await tester.tap(find.text('Create link'));
      await tester.pumpAndSettle();
      expect(find.text('Already a member of this space'), findsOneWidget);
      expect(sharing.calls, isEmpty);
    });

    testWidgets('creates the invite and shows its link once', (tester) async {
      await openInvite(tester);
      await tester.enterText(find.byType(TextField), ' Cy@Test.com ');
      await tester.tap(find.text('Viewer'));
      await tester.pump();
      expect(find.text('Viewers only see records.'), findsOneWidget);
      await tester.tap(find.text('Create link'));
      await tester.pumpAndSettle();

      expect(sharing.calls, ['invite $businessId cy@test.com viewer']);
      expect(find.text('Invite link'), findsOneWidget);
      expect(
        tester
            .widget<SelectableText>(find.byKey(const Key('invite-link')))
            .data,
        'https://fundly-budget.vercel.app/join#${'ab' * 31}01',
      );
      expect(find.textContaining('Send this link to cy@test.com'), findsOne);
      expect(find.textContaining("isn't shown again"), findsOneWidget);
    });

    testWidgets("explains the server's refusal", (tester) async {
      sharing.failures.add(
        const SharingException(SharingProblem.inviteLimitReached),
      );
      await openInvite(tester);
      await tester.enterText(find.byType(TextField), 'cy@test.com');
      await tester.tap(find.text('Create link'));
      await tester.pumpAndSettle();
      expect(find.textContaining('20 pending invites'), findsOneWidget);
      expect(find.text('Invite link'), findsNothing);
    });
  });

  group('leave and delete', () {
    testWidgets('leaving asks first, then closes the sheet', (tester) async {
      await openMenu(tester, 'Household');
      await tester.tap(find.text('Leave space'));
      await tester.pumpAndSettle();
      expect(find.text('Leave Household?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Leave'));
      await tester.pumpAndSettle();

      expect(sharing.calls, ['leave $householdId']);
      expect(find.text('Your spaces'), findsNothing);
      expect(find.text('You left Household.'), findsOneWidget);
    });

    testWidgets('the last owner is told why they cannot leave', (tester) async {
      sharing.failures.add(const SharingException(SharingProblem.lastOwner));
      await openMenu(tester, 'Business');
      await tester.tap(find.text('Leave space'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Leave'));
      await tester.pumpAndSettle();

      expect(find.textContaining('A space needs an owner'), findsOneWidget);
      expect(find.text('Leave Business?'), findsOneWidget);
    });

    testWidgets('deleting needs the name typed, ignoring case and spaces', (
      tester,
    ) async {
      await openMenu(tester, 'Business');
      await tester.tap(find.text('Delete space'));
      await tester.pumpAndSettle();
      FilledButton delete() =>
          tester.widget(find.widgetWithText(FilledButton, 'Delete'));

      expect(delete().onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'Busines');
      await tester.pump();
      expect(delete().onPressed, isNull);
      await tester.enterText(find.byType(TextField), '  business ');
      await tester.pump();
      expect(delete().onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(sharing.calls, ['delete $businessId   business ']);
      expect(find.text('Business was deleted.'), findsOneWidget);
    });
  });

  group('members', () {
    testWidgets('an owner manages others, not themselves', (tester) async {
      await pump(tester, const MembersScreen(spaceId: businessId));
      await tester.pumpAndSettle();

      expect(find.text('Members of Business'), findsOneWidget);
      expect(find.text('Nilo (you)'), findsOneWidget);
      expect(find.text('Editor · bea@test.com'), findsOneWidget);
      expect(find.byTooltip('Manage Nilo'), findsNothing);

      await tester.tap(find.byTooltip('Manage Bea'));
      await tester.pumpAndSettle();
      expect(find.text('Make editor'), findsNothing);
      await tester.tap(find.text('Make viewer'));
      await tester.pumpAndSettle();
      expect(sharing.calls.last, 'role $businessId ${bea.userId} viewer');
      expect(find.text('Bea is now Viewer.'), findsOneWidget);

      await tester.tap(find.byTooltip('Manage Bea'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from space'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await tester.pumpAndSettle();
      expect(sharing.calls.last, 'remove $businessId ${bea.userId}');
    });

    testWidgets('an owner sees pending invites, revokes and renews them', (
      tester,
    ) async {
      sharing.invites = [
        SpaceInvite(
          id: 'i1',
          email: 'cy@test.com',
          role: SpaceRole.viewer,
          createdAt: DateTime.utc(2026, 11, 24),
          expiresAt: DateTime.utc(2026, 12, 1),
        ),
      ];
      await pump(tester, const MembersScreen(spaceId: businessId));
      await tester.pumpAndSettle();
      expect(find.text('cy@test.com'), findsOneWidget);
      expect(find.textContaining('Viewer · expires'), findsOneWidget);

      await tester.tap(find.byTooltip('Manage invite to cy@test.com'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New link'));
      await tester.pumpAndSettle();
      expect(sharing.calls, contains('invite $businessId cy@test.com viewer'));
      expect(find.text('Invite link'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Manage invite to cy@test.com'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revoke'));
      await tester.pumpAndSettle();
      expect(sharing.calls, contains('revoke i1'));
      expect(find.text('Invite to cy@test.com revoked.'), findsOneWidget);
    });

    testWidgets('an editor only sees who is there', (tester) async {
      await pump(tester, const MembersScreen(spaceId: householdId));
      await tester.pumpAndSettle();

      expect(find.text('Bea'), findsOneWidget);
      expect(find.text('Nilo (you)'), findsOneWidget);
      expect(find.byType(PopupMenuButton<Object>), findsNothing);
      expect(find.text('Invite'), findsNothing);
      expect(find.text('Pending invites'), findsNothing);
      expect(sharing.calls, isEmpty);
    });
  });
  group('join (C3.3 part C)', () {
    const gardenId = '1d2e3f4a-5b6c-4d7e-8f9a-0b1c2d3e4f5a';
    final secret = 'cd' * 32;
    InvitePreview preview({bool alreadyMember = false}) => InvitePreview(
      spaceId: gardenId,
      spaceName: 'Garden',
      role: SpaceRole.viewer,
      expiresAt: DateTime.utc(2026, 12, 1),
      alreadyMember: alreadyMember,
      inviterName: 'Bea',
    );

    Future<void> pasteLink(WidgetTester tester, String text) async {
      await pump(tester, const ProfileScreen());
      await tester.tap(find.byKey(const Key('space-switcher')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Join a space'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Join a space'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), text);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    String? activeSpace(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(ProfileScreen)))
            .read(activeSpaceIdProvider);

    testWidgets('a paste without a link is explained', (tester) async {
      await pasteLink(tester, 'join my budget please');
      expect(find.text('Paste the invite link you were sent'), findsOneWidget);
      expect(sharing.calls, isEmpty);
    });

    testWidgets('the link inside a message opens the invite; accepting '
        'switches to the space', (tester) async {
      sharing.preview = preview();
      await pasteLink(
        tester,
        'Join Garden on Fundly: https://fundly-budget.vercel.app/join#$secret',
      );
      expect(find.text('Join Garden?'), findsOneWidget);
      expect(find.text('Bea invited you to Garden as Viewer.'), findsOneWidget);
      expect(find.textContaining('and can change them'), findsNothing);

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(sharing.calls, ['preview $secret', 'accept $secret']);
      expect(find.text('Join Garden?'), findsNothing);
      expect(activeSpace(tester), gardenId);
    });

    testWidgets('declining says so and stays put', (tester) async {
      sharing.preview = preview();
      await pasteLink(tester, secret.toUpperCase());
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();
      expect(sharing.calls.last, 'decline $secret');
      expect(find.text('Invite declined.'), findsOneWidget);
      expect(activeSpace(tester), user.userId);
    });

    testWidgets('an invite for another email reveals nothing', (tester) async {
      sharing.failures.add(
        const SharingException(SharingProblem.inviteOtherEmail),
      );
      await pasteLink(tester, secret);
      expect(find.textContaining('This invite is for another email'), findsOne);
      expect(find.text('Accept'), findsNothing);
      expect(find.textContaining('Garden'), findsNothing);
    });

    testWidgets('already a member: Open switches without accepting', (
      tester,
    ) async {
      sharing.preview = preview(alreadyMember: true);
      await pasteLink(tester, secret);
      expect(find.text("You're already a member of Garden."), findsOneWidget);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(sharing.calls, ['preview $secret']);
      expect(activeSpace(tester), gardenId);
    });

    testWidgets('a web page opened with an invite shows it once', (
      tester,
    ) async {
      sharing.preview = preview(alreadyMember: true);
      await pump(
        tester,
        const PendingInviteHandler(child: ProfileScreen()),
        pageInvite: secret,
      );
      await tester.pumpAndSettle();
      expect(find.text("You're already a member of Garden."), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text("You're already a member of Garden."), findsNothing);
      expect(sharing.calls, ['preview $secret']);
    });

    testWidgets('signed out, the page invite waits for sign-in', (
      tester,
    ) async {
      sharing.preview = preview();
      await pump(
        tester,
        const PendingInviteHandler(child: Scaffold(body: Text('home'))),
        identity: const SignedOut(),
        pageInvite: secret,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('You have an invite to a space'), findsOne);
      expect(find.text('Join Garden?'), findsNothing);
      expect(sharing.calls, isEmpty);
    });
  });
}

extension on SpaceMember {
  SpaceMember withRole(SpaceRole role) => SpaceMember(
    userId: userId,
    role: role,
    email: email,
    displayName: displayName,
  );
}
