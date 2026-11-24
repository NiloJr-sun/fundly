import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/accounts/presentation/account_form_screen.dart';
import 'package:fundly/features/accounts/presentation/accounts_screen.dart';
import 'package:fundly/features/auth/data/auth_repository.dart';
import 'package:fundly/features/auth/domain/auth_identity.dart';
import 'package:fundly/features/backup/data/device_data_copier.dart';
import 'package:fundly/features/plans/presentation/plans_screen.dart';
import 'package:fundly/features/profile/presentation/profile_screen.dart';
import 'package:fundly/features/spaces/data/active_space.dart';
import 'package:fundly/features/spaces/data/active_space_store.dart';
import 'package:fundly/features/spaces/data/space_service.dart';
import 'package:fundly/features/spaces/domain/space.dart';
import 'package:fundly/features/spaces/presentation/space_providers.dart';
import 'package:fundly/features/spending/presentation/spending_screen.dart';
import 'package:fundly/features/sync/presentation/edit_guard.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/provider_overrides.dart';

const user = SignedIn(
  userId: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  email: 'nilo@test.com',
  name: 'Nilo',
);
const businessId = '7c1d2e3f-4a5b-4c6d-8e7f-90a1b2c3d4e5';
const householdId = '0a1b2c3d-4e5f-4a6b-8c7d-8e9f0a1b2c3d';

const personal = Space(
  id: '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
  name: 'Personal',
  isPersonal: true,
  role: SpaceRole.owner,
  revision: 1,
);
const business = Space(
  id: businessId,
  name: 'Business',
  isPersonal: false,
  role: SpaceRole.owner,
  revision: 3,
);
const sharedWithMe = Space(
  id: '5e6f7a8b-9c0d-4e1f-a2b3-c4d5e6f7a8b9',
  name: 'Family',
  isPersonal: false,
  role: SpaceRole.viewer,
  revision: 1,
);
const household = Space(
  id: householdId,
  name: 'Household',
  isPersonal: false,
  role: SpaceRole.editor,
  revision: 1,
);

class FakeSpaceService implements SpaceService {
  final created = <({String spaceId, String name})>[];
  final renamed = <(Space, String)>[];
  final failures = <SpaceException>[];

  @override
  Future<Space> create({required String spaceId, required String name}) async {
    created.add((spaceId: spaceId, name: name));
    if (failures.isNotEmpty) throw failures.removeAt(0);
    return Space(
      id: spaceId,
      name: name,
      isPersonal: false,
      role: SpaceRole.owner,
      revision: 1,
    );
  }

  @override
  Future<Space> rename(Space space, String name) async {
    renamed.add((space, name));
    if (failures.isNotEmpty) throw failures.removeAt(0);
    return Space(
      id: space.id,
      name: name,
      isPersonal: space.isPersonal,
      role: space.role,
      revision: space.revision + 1,
    );
  }

  @override
  Future<Set<String>> memberSpaceIds() async => {personal.id, businessId};
}

void main() {
  late FakeSpaceService service;
  late InMemoryActiveSpaceStore remembered;

  setUp(() {
    service = FakeSpaceService();
    remembered = InMemoryActiveSpaceStore();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget home, {
    List<Space> spaces = const [personal, business, household],
    bool deviceHasData = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeAccounts(const [], spaces: spaces),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(initial: user),
          ),
          activeSpaceStoreProvider.overrideWithValue(remembered),
          spaceServiceProvider.overrideWithValue(service),
          deviceHasDataProvider.overrideWith((ref) async => deviceHasData),
        ],
        child: MaterialApp(home: home),
      ),
    );
    await tester.pump();
    await tester.pump();
    return ProviderScope.containerOf(
      tester.element(find.byType(home.runtimeType)),
    );
  }

  group('Profile card', () {
    testWidgets('shows the active space and role, and opens the sheet', (
      tester,
    ) async {
      await pump(tester, const ProfileScreen());

      expect(find.text('Personal · Owner'), findsOneWidget);
      await tester.tap(find.byKey(const Key('space-switcher')));
      await tester.pumpAndSettle();

      expect(find.text('Your spaces'), findsOneWidget);
      expect(find.text('Owner · Personal'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Editor'), findsOneWidget);
      expect(find.text('Create space'), findsOneWidget);
      expect(find.byTooltip('Rename Business'), findsOneWidget);
      expect(find.byTooltip('Rename Household'), findsNothing);
    });

    testWidgets('tapping a space switches to it and remembers it', (
      tester,
    ) async {
      final container = await pump(tester, const ProfileScreen());
      await tester.tap(find.byKey(const Key('space-switcher')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Business'));
      await tester.pumpAndSettle();

      expect(container.read(activeSpaceIdProvider), businessId);
      expect(remembered.remembered(user.userId), businessId);
      expect(find.text('Your spaces'), findsNothing);
    });

    testWidgets('the sheet says when the list has not downloaded yet', (
      tester,
    ) async {
      await pump(tester, const ProfileScreen(), spaces: const []);
      expect(find.text('Loading space…'), findsOneWidget);
      await tester.tap(find.byKey(const Key('space-switcher')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Loading your spaces…'), findsOneWidget);
    });
  });

  group('Create space', () {
    Future<void> openCreate(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('space-switcher')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create space'));
      await tester.pumpAndSettle();
    }

    testWidgets('checks the name before asking the server', (tester) async {
      await pump(tester, const ProfileScreen());
      await openCreate(tester);

      await tester.tap(find.text('Create'));
      await tester.pump();
      expect(find.text('Enter a name'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  business ');
      await tester.tap(find.text('Create'));
      await tester.pump();
      expect(
        find.text('You already have a space called Business'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'Household');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      // Household is someone else's (editor): the name is still free.
      expect(service.created.single.name, 'Household');
    });

    testWidgets('creates the space, switches to it and closes', (tester) async {
      final container = await pump(tester, const ProfileScreen());
      await openCreate(tester);
      await tester.enterText(find.byType(TextField), '  Side job ');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      final created = service.created.single;
      expect(created.name, 'Side job');
      expect(container.read(activeSpaceIdProvider), created.spaceId);
      expect(find.text('New space'), findsNothing);
      expect(find.text('Your spaces'), findsNothing);
    });

    testWidgets('offline says so; a retry reuses the same id', (tester) async {
      service.failures.add(const SpaceException(SpaceProblem.offline));
      await pump(tester, const ProfileScreen());
      await openCreate(tester);
      await tester.enterText(find.byType(TextField), 'Side job');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Couldn't reach the server. Creating a space needs a connection.",
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(service.created, hasLength(2));
      expect(service.created[1].spaceId, service.created[0].spaceId);
    });

    testWidgets('the limit is explained', (tester) async {
      service.failures.add(const SpaceException(SpaceProblem.limitReached));
      await pump(tester, const ProfileScreen());
      await openCreate(tester);
      await tester.enterText(find.byType(TextField), 'Eleventh');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(find.text('You can have up to 10 spaces'), findsOneWidget);
    });
  });

  group('Rename space', () {
    testWidgets('renames with the revision the device has', (tester) async {
      await pump(tester, const ProfileScreen());
      await tester.tap(find.byKey(const Key('space-switcher')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Rename Business'));
      await tester.pumpAndSettle();

      expect(find.text('Rename space'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Shop');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(service.renamed.single.$1, business);
      expect(service.renamed.single.$2, 'Shop');
      expect(find.text('Rename space'), findsNothing);
    });

    testWidgets('a change elsewhere is explained', (tester) async {
      service.failures.add(const SpaceException(SpaceProblem.changed));
      await pump(tester, const ProfileScreen());
      await tester.tap(find.byKey(const Key('space-switcher')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Rename Business'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Shop');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('just changed on another device'),
        findsOneWidget,
      );
    });

    testWidgets('keeping its own name with another case is allowed', (
      tester,
    ) async {
      expect(
        spaceNameProblem('BUSINESS', const [business], exceptId: businessId),
        isNull,
      );
      expect(
        spaceNameProblem('x' * 41, const []),
        'Use 40 characters or fewer',
      );
    });
  });

  group('which space a screen shows', () {
    testWidgets('only Personal: titles and actions look as before spaces', (
      tester,
    ) async {
      await pump(tester, const SpendingScreen(), spaces: const [personal]);
      expect(find.byKey(const Key('screen-title-space')), findsNothing);
    });

    testWidgets('several spaces: Spending and Plans name the active one', (
      tester,
    ) async {
      await remembered.remember(user.userId, businessId);
      await pump(tester, const SpendingScreen());
      expect(
        tester.widget<Text>(find.byKey(const Key('screen-title-space'))).data,
        'Business',
      );
      await pump(tester, const PlansScreen());
      expect(find.byKey(const Key('screen-title-space')), findsOneWidget);
    });

    testWidgets('Profile actions name the space, and copying device data '
        'waits for Personal', (tester) async {
      await remembered.remember(user.userId, businessId);
      await pump(tester, const ProfileScreen(), deviceHasData: true);

      expect(
        find.text('Save all records in Business to a file'),
        findsOneWidget,
      );
      expect(find.text('Delete every record in Business'), findsOneWidget);
      expect(find.text("Copy this device's data"), findsNothing);
    });

    testWidgets('in Personal the copy row is offered', (tester) async {
      await pump(tester, const ProfileScreen(), deviceHasData: true);
      expect(find.text("Copy this device's data"), findsOneWidget);
      expect(
        find.text('Save all records in Personal to a file'),
        findsOneWidget,
      );
    });
  });

  group('view-only gate (C3.3)', () {
    const spaces = [personal, business, household, sharedWithMe];

    // The app keeps the spaces list live (spaceRemovalsProvider listens to
    // it), so a screen that does not show it still knows the role.
    Future<void> pumpIn(Space space, WidgetTester tester, Widget home) async {
      await remembered.remember(user.userId, space.id);
      final container = await pump(tester, home, spaces: spaces);
      container.listen(canEditProvider, (_, _) {});
      await tester.pump();
    }

    Future<void> expectViewOnly(WidgetTester tester) async {
      await tester.pump();
      expect(find.text(viewOnlyMessage), findsOneWidget);
    }

    testWidgets('a viewer cannot add a transaction', (tester) async {
      await pumpIn(sharedWithMe, tester, const SpendingScreen());
      await tester.tap(find.text('Add transaction'));
      await expectViewOnly(tester);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('a viewer cannot add an account', (tester) async {
      await pumpIn(sharedWithMe, tester, const AccountsScreen());
      await tester.tap(find.text('Add account'));
      await expectViewOnly(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AccountFormScreen), findsNothing);
    });

    testWidgets('a viewer cannot restore or reset; export stays', (
      tester,
    ) async {
      await pumpIn(sharedWithMe, tester, const ProfileScreen());
      for (final action in ['Restore from backup', 'Reset all data']) {
        await tester.scrollUntilVisible(find.text(action), 100);
        await tester.tap(find.text(action));
        await expectViewOnly(tester);
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing, reason: action);
      }
    });

    testWidgets('an editor adds as before', (tester) async {
      await pumpIn(household, tester, const SpendingScreen());
      await tester.tap(find.text('Add transaction'));
      await tester.pumpAndSettle();
      expect(find.text(viewOnlyMessage), findsNothing);
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    for (final (space, shown) in [
      (sharedWithMe, 'Family · Viewer'),
      (household, 'Household · Editor'),
      (business, 'Business'),
    ]) {
      testWidgets('the title shows the role unless owner: $shown', (
        tester,
      ) async {
        await pumpIn(space, tester, const SpendingScreen());
        expect(
          tester.widget<Text>(find.byKey(const Key('screen-title-space'))).data,
          shown,
        );
      });
    }
  });
}
