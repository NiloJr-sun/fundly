import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/theme/app_colors.dart';
import 'package:fundly/app/theme/app_palette.dart';
import 'package:fundly/app/theme/app_theme.dart';

import 'app_theme_test.dart' show contrast;

void main() {
  test('an unknown or missing saved name falls back to Classic Teal', () {
    expect(AppPalette.fromName(null), AppPalette.classicTeal);
    expect(AppPalette.fromName('neonPink'), AppPalette.classicTeal);
    expect(AppPalette.fromName('oceanCalm'), AppPalette.oceanCalm);
    // Palettes from an earlier draft, never released.
    expect(AppPalette.fromName('soothingSage'), AppPalette.classicTeal);
    expect(AppPalette.fromName('tealAndGold'), AppPalette.classicTeal);
  });

  for (final palette in AppPalette.values) {
    if (palette == AppPalette.classicTeal) continue;
    for (final brightness in Brightness.values) {
      test('${palette.label} ${brightness.name}: text on the accent is the '
          "palette's dark text colour", () {
        final colors = AppTheme.build(palette, brightness).colorScheme;
        expect(colors.onTertiary, palette.light.onSurface);
      });
    }
  }

  group('Classic Teal keeps the original colours', () {
    for (final brightness in Brightness.values) {
      test('${brightness.name}: expense is the seed scheme error colour', () {
        final theme = AppTheme.build(AppPalette.classicTeal, brightness);
        expect(theme.extension<AppColors>()!.expense, theme.colorScheme.error);
      });

      test('${brightness.name}: the accent is the seed tertiary colour', () {
        final theme = AppTheme.build(AppPalette.classicTeal, brightness);
        expect(
          theme.colorScheme.tertiary,
          ColorScheme.fromSeed(
            seedColor: AppPalette.classicTeal.seed,
            brightness: brightness,
          ).tertiary,
        );
      });
    }
  });

  for (final brightness in Brightness.values) {
    test(
      '${brightness.name}: destructive red is the same in every palette',
      () {
        final errors = {
          for (final palette in AppPalette.values)
            AppTheme.build(palette, brightness).colorScheme.error,
        };
        expect(errors, hasLength(1));
      },
    );
  }

  for (final palette in AppPalette.values) {
    for (final brightness in Brightness.values) {
      final shade = palette.shade(brightness);

      test('${palette.label} ${brightness.name}: income is green and expense '
          'red', () {
        final income = HSLColor.fromColor(shade.positive).hue;
        final expense = HSLColor.fromColor(shade.expense).hue;
        expect(income, inInclusiveRange(90, 170));
        expect(expense < 20 || expense > 340, isTrue, reason: '$expense');
      });
    }

    // The dark shades were derived for this palette work: their accent and
    // money colours must read at 4.5:1 on every dark surface.
    test('${palette.label} dark: accent and money colours read at 4.5:1', () {
      final theme = AppTheme.build(palette, Brightness.dark);
      final money = theme.extension<AppColors>()!;
      final backgrounds = [
        theme.colorScheme.surface,
        theme.cardTheme.color!,
        theme.colorScheme.surfaceContainerHigh,
        ...money.backdrop.colors,
      ];
      for (final foreground in [
        theme.colorScheme.tertiary,
        money.positive,
        money.expense,
      ]) {
        for (final background in backgrounds) {
          expect(
            contrast(foreground, background),
            greaterThanOrEqualTo(4.5),
            reason: '$foreground on $background',
          );
        }
      }
    });
  }
}
