import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Light and dark Material 3 themes for Fundly.
///
/// Colours come from a single seed via [ColorScheme.fromSeed]. Typography uses
/// the Material 3 defaults; read styles with `Theme.of(context).textTheme`
/// instead of creating ad-hoc [TextStyle]s in widgets.
abstract final class AppTheme {
  static const Color seedColor = Colors.teal;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      extensions: [
        brightness == Brightness.light ? AppColors.light : AppColors.dark,
      ],
    );
  }
}
