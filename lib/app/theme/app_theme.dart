import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'spacing.dart';

/// Material 3 themes for an [AppPalette], with its surfaces and shared
/// component styles. Money and status colours are in [AppColors];
/// typography uses M3 defaults.
abstract final class AppTheme {
  static ThemeData light([AppPalette palette = AppPalette.fallback]) =>
      build(palette, Brightness.light);

  static ThemeData dark([AppPalette palette = AppPalette.fallback]) =>
      build(palette, Brightness.dark);

  static ThemeData build(AppPalette palette, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final shade = palette.shade(brightness);
    final seeded = ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: brightness,
    );
    final panel = isDark
        ? shade.surfaceContainerLow
        : shade.surfaceContainerLowest;
    final onSurface = shade.onSurface ?? seeded.onSurface;
    final accent = shade.accent;
    final colors = seeded.copyWith(
      surface: shade.surface,
      surfaceContainerLowest: shade.surfaceContainerLowest,
      surfaceContainerLow: shade.surfaceContainerLow,
      surfaceContainer: shade.surfaceContainer,
      surfaceContainerHigh: shade.surfaceContainerHigh,
      surfaceContainerHighest: shade.surfaceContainerHighest,
      outlineVariant: shade.outlineVariant,
      onSurface: onSurface,
      onSurfaceVariant: shade.onSurfaceVariant,
      // Accents are light in both brightnesses, so the palette's dark text
      // colour sits on them; their containers are a soft tint on the panel.
      tertiary: accent,
      onTertiary: accent == null ? null : palette.light.onSurface,
      tertiaryContainer: accent == null
          ? null
          : Color.alphaBlend(accent.withValues(alpha: 0.28), panel),
      onTertiaryContainer: accent == null ? null : onSurface,
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel,
        indicatorColor: colors.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: panel,
        contentPadding: const EdgeInsets.all(Spacing.md),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: controlShape,
          minimumSize: const Size(64, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: controlShape,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: controlShape,
          minimumSize: const Size(64, 48),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: panel,
        foregroundColor: colors.primary,
        elevation: 2,
        shape: const StadiumBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        iconColor: colors.primary,
        titleTextStyle: _textTheme(brightness).titleLarge
            ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
        contentTextStyle: _textTheme(brightness).bodyMedium
            ?.copyWith(color: colors.onSurfaceVariant, height: 1.45),
        actionsPadding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          0,
          Spacing.lg,
          Spacing.lg - Spacing.xs,
        ),
      ),
      // ⋮ menus: a soft rounded panel just below the button.
      popupMenuTheme: PopupMenuThemeData(
        color: isDark
            ? colors.surfaceContainerHigh
            : colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        position: PopupMenuPosition.under,
        menuPadding: const EdgeInsets.symmetric(vertical: 6),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
      extensions: [AppColors.fromShade(shade)],
    );
  }

  /// The M3 default text styles for this platform, with their sizes, so
  /// component themes can build on them (ThemeData adds sizes only later).
  static TextTheme _textTheme(Brightness brightness) {
    final typography = Typography.material2021(platform: defaultTargetPlatform);
    final colored = brightness == Brightness.dark
        ? typography.white
        : typography.black;
    return typography.englishLike.merge(colored);
  }
}
