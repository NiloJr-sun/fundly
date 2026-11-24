import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/app.dart';
import 'package:fundly/app/home_shell.dart';
import 'package:fundly/app/theme/app_colors.dart';
import 'package:fundly/app/theme/app_palette.dart';
import 'package:fundly/app/theme/app_theme.dart';
import 'package:fundly/app/theme/appearance_settings.dart';

import '../../helpers/provider_overrides.dart';

double contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppTheme', () {
    test('light theme uses the seed colour scheme in light mode', () {
      final theme = AppTheme.light();

      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
      expect(
        theme.colorScheme.primary,
        ColorScheme.fromSeed(seedColor: AppPalette.classicTeal.seed).primary,
      );
    });

    test('dark theme uses the seed colour scheme in dark mode', () {
      final theme = AppTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
      expect(
        theme.colorScheme.primary,
        ColorScheme.fromSeed(
          seedColor: AppPalette.classicTeal.seed,
          brightness: Brightness.dark,
        ).primary,
      );
    });
  });

  // Classic Teal light and every dark shade must keep body text readable
  // (4.5:1). The other palettes' light colours are the product owner's
  // values; only their main text is checked here (see app_palette_test.dart
  // for their money colours).
  for (final palette in AppPalette.values) {
    for (final brightness in Brightness.values) {
      final full =
          brightness == Brightness.dark || palette == AppPalette.classicTeal;
      test('${palette.label} ${brightness.name} keeps readable text on its '
          'surfaces', () {
        final theme = AppTheme.build(palette, brightness);
        final colors = theme.colorScheme;
        final backgrounds = [
          colors.surface,
          theme.cardTheme.color!,
          ...theme.extension<AppColors>()!.backdrop.colors,
        ];
        for (final (foreground, background) in [
          for (final background in backgrounds) ...[
            (colors.onSurface, background),
            if (full) (colors.onSurfaceVariant, background),
          ],
          (colors.onPrimary, colors.primary),
          (colors.onPrimaryContainer, colors.primaryContainer),
          (colors.onTertiaryContainer, colors.tertiaryContainer),
        ]) {
          expect(
            contrast(foreground, background),
            greaterThanOrEqualTo(4.5),
            reason: '$foreground on $background',
          );
        }
      });
    }
  }

  group('FundlyApp follows the device brightness', () {
    Future<Brightness> pumpWithDeviceBrightness(
      WidgetTester tester,
      Brightness brightness,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(
        ProviderScope(overrides: noAccounts(), child: const FundlyApp()),
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

  testWidgets('FundlyApp uses the saved palette and mode over the device', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...noAccounts(),
          appearanceStoreProvider.overrideWithValue(
            InMemoryAppearanceStore(
              const AppearanceSettings(
                palette: AppPalette.oceanCalm,
                mode: ThemeMode.dark,
              ),
            ),
          ),
        ],
        child: const FundlyApp(),
      ),
    );

    final theme = Theme.of(tester.element(find.byType(HomeShell)));
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.surface, AppPalette.oceanCalm.dark.surface);
  });
}
