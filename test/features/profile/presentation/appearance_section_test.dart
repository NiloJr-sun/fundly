import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/app.dart';
import 'package:fundly/app/app_version.dart';
import 'package:fundly/app/theme/app_palette.dart';
import 'package:fundly/app/theme/appearance_settings.dart';
import 'package:fundly/features/profile/presentation/profile_screen.dart';

import '../../../helpers/provider_overrides.dart';

void main() {
  Future<InMemoryAppearanceStore> pumpApp(WidgetTester tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final store = InMemoryAppearanceStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...noAccounts(),
          appearanceStoreProvider.overrideWithValue(store),
        ],
        child: const FundlyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    // The version line is last, so the Appearance rows are clear of the
    // navigation bar.
    await tester.scrollUntilVisible(find.text(appVersionText), 200);
    await tester.pumpAndSettle();
    return store;
  }

  Finder inProfile(Finder finder) =>
      find.descendant(of: find.byType(ProfileScreen), matching: finder);

  testWidgets('Appearance sits between Your data and the version line', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('Color theme'), findsOneWidget);
    expect(inProfile(find.text('Classic Teal')), findsOneWidget);
    expect(inProfile(find.text('System')), findsOneWidget);
    final yourData = tester.getTopLeft(find.text('Reset all data')).dy;
    final appearance = tester.getTopLeft(find.text('APPEARANCE')).dy;
    expect(appearance, greaterThan(yourData));
  });

  testWidgets('picking a palette applies it at once and closes the sheet', (
    tester,
  ) async {
    final store = await pumpApp(tester);

    await tester.tap(find.text('Color theme'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
    for (final palette in AppPalette.values) {
      expect(find.text(palette.label), findsWidgets);
    }

    await tester.tap(find.text('Ocean Calm'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(inProfile(find.text('Ocean Calm')), findsOneWidget);
    expect(store.load().palette, AppPalette.oceanCalm);
    final theme = Theme.of(tester.element(find.text('Color theme')));
    expect(theme.colorScheme.surface, AppPalette.oceanCalm.light.surface);
  });

  testWidgets('picking Dark switches the app to dark at once', (tester) async {
    final store = await pumpApp(tester);

    await tester.tap(find.text('Appearance mode'));
    await tester.pumpAndSettle();
    expect(find.text('Light'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(inProfile(find.text('Dark')), findsOneWidget);
    expect(store.load().mode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('Color theme'))).brightness,
      Brightness.dark,
    );
  });
}
