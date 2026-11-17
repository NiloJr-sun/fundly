import 'package:flutter/material.dart';

/// Colours the Material colour scheme does not provide. Read them with
/// `AppColors.of(context)`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.positive,
    required this.warning,
    required this.backdrop,
  });

  /// Positive balances. Green, dark enough to read on the light background.
  static const AppColors light = AppColors(
    positive: Color(0xFF388E3C),
    warning: Color(0xFF8D6E00),
    backdrop: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF88D3CA), Color(0xFFB9EDD9), Color(0xFFF4F7F6)],
      stops: [0, 0.42, 1],
    ),
  );

  /// A lighter green for the dark background.
  static const AppColors dark = AppColors(
    positive: Color(0xFF81C784),
    warning: Color(0xFFFFD54F),
    backdrop: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF064E4B), Color(0xFF14362E), Color(0xFF101714)],
      stops: [0, 0.42, 1],
    ),
  );

  final Color positive;

  /// Partially assigned plans. Dark yellow on light backgrounds for contrast.
  final Color warning;

  /// Teal-to-neutral canvas behind the main tabs.
  final LinearGradient backdrop;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? positive,
    Color? warning,
    LinearGradient? backdrop,
  }) => AppColors(
    positive: positive ?? this.positive,
    warning: warning ?? this.warning,
    backdrop: backdrop ?? this.backdrop,
  );

  @override
  AppColors lerp(AppColors? other, double t) => other == null
      ? this
      : AppColors(
          positive: Color.lerp(positive, other.positive, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          backdrop: LinearGradient.lerp(backdrop, other.backdrop, t)!,
        );
}
