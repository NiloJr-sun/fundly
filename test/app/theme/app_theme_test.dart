import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/app.dart';
import 'package:fundly/app/home_shell.dart';
import 'package:fundly/app/theme/app_theme.dart';

import '../../helpers/provider_overrides.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses the seed colour scheme in light mode', () {
      final theme = AppTheme.light();

      expect(theme.brightness, Brightness.light);
      expect(
        theme.colorScheme.primary,
        ColorScheme.fromSeed(seedColor: AppTheme.seedColor).primary,
      );
    });

    test('dark theme uses the seed colour scheme in dark mode', () {
      final theme = AppTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(
        theme.colorScheme.primary,
        ColorScheme.fromSeed(
          seedColor: AppTheme.seedColor,
          brightness: Brightness.dark,
        ).primary,
      );
    });
  });

  group('FundlyApp follows the device brightness', () {
    Future<Brightness> pumpWithDeviceBrightness(
      WidgetTester tester,
      Brightness brightness,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(
        ProviderScope(overrides: fakeAccounts(), child: const FundlyApp()),
      );

      return Theme.of(tester.element(find.byType(HomeShell))).brightness;
    }

    testWidgets('renders in light mode', (tester) async {
      expect(
        await pumpWithDeviceBrightness(tester, Brightness.light),
        Brightness.light,
      );
    });

    testWidgets('renders in dark mode', (tester) async {
      expect(
        await pumpWithDeviceBrightness(tester, Brightness.dark),
        Brightness.dark,
      );
    });
  });
}
