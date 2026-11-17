import 'package:flutter/material.dart';

/// Colours the Material colour scheme does not provide. Read them with
/// `AppColors.of(context)`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.positive, required this.warning});

  /// Positive balances. Green, dark enough to read on the light background.
  static const AppColors light = AppColors(
    positive: Color(0xFF388E3C),
    warning: Color(0xFF8D6E00),
  );

  /// A lighter green for the dark background.
  static const AppColors dark = AppColors(
    positive: Color(0xFF81C784),
    warning: Color(0xFFFFD54F),
  );

  final Color positive;

  /// Partially assigned plans. Dark yellow on light backgrounds for contrast.
  final Color warning;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({Color? positive, Color? warning}) => AppColors(
    positive: positive ?? this.positive,
    warning: warning ?? this.warning,
  );

  @override
  AppColors lerp(AppColors? other, double t) => other == null
      ? this
      : AppColors(
          positive: Color.lerp(positive, other.positive, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
        );
}
