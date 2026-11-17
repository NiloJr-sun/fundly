import 'package:flutter/material.dart';

/// Colours the Material colour scheme does not provide. Read them with
/// `AppColors.of(context)`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.positive});

  /// Positive balances. Green, dark enough to read on the light background.
  static const AppColors light = AppColors(positive: Color(0xFF388E3C));

  /// A lighter green for the dark background.
  static const AppColors dark = AppColors(positive: Color(0xFF81C784));

  final Color positive;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({Color? positive}) =>
      AppColors(positive: positive ?? this.positive);

  @override
  AppColors lerp(AppColors? other, double t) => other == null
      ? this
      : AppColors(positive: Color.lerp(positive, other.positive, t)!);
}
