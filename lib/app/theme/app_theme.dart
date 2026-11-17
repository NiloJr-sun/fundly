import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'spacing.dart';

/// Teal Material 3 themes with neutral surfaces and shared component styles.
/// Financial status colours stay in [AppColors]; typography uses M3 defaults.
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF00796B);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors =
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
        ).copyWith(
          surface: isDark ? const Color(0xFF101714) : const Color(0xFFF4F7F6),
          surfaceContainerLowest: isDark
              ? const Color(0xFF0B120F)
              : Colors.white,
          surfaceContainerLow: isDark
              ? const Color(0xFF17211D)
              : const Color(0xFFEFF5F2),
          surfaceContainer: isDark
              ? const Color(0xFF1B2722)
              : const Color(0xFFE9F0ED),
          surfaceContainerHigh: isDark
              ? const Color(0xFF24312B)
              : const Color(0xFFE2EBE7),
          surfaceContainerHighest: isDark
              ? const Color(0xFF2F3D35)
              : const Color(0xFFDAE5E0),
          outlineVariant: isDark
              ? const Color(0xFF33473D)
              : const Color(0xFFCDDAD4),
        );
    final panel = isDark
        ? colors.surfaceContainerLow
        : colors.surfaceContainerLowest;
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant),
        ),
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: controlShape,
          minimumSize: const Size(64, 48),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
      extensions: [isDark ? AppColors.dark : AppColors.light],
    );
  }
}
