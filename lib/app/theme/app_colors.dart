import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Colours the Material colour scheme does not provide. Read them with
/// `AppColors.of(context)`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.positive,
    required this.expense,
    required this.warning,
    required this.backdrop,
  });

  /// The money and status colours of one shade of a palette.
  AppColors.fromShade(PaletteShade shade)
    : positive = shade.positive,
      expense = shade.expense,
      warning = shade.warning,
      backdrop = shade.backdrop;

  /// Money in and positive balances; green in every palette.
  final Color positive;

  /// Money out: overspent, over-assigned and unassigned amounts; red in every
  /// palette. Destructive actions use `colorScheme.error` instead, which no
  /// palette changes.
  final Color expense;

  /// Partially assigned plans. Dark yellow on light backgrounds for contrast.
  final Color warning;

  /// The canvas behind the main tabs.
  final LinearGradient backdrop;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ??
      AppColors.fromShade(AppPalette.fallback.light);

  @override
  AppColors copyWith({
    Color? positive,
    Color? expense,
    Color? warning,
    LinearGradient? backdrop,
  }) => AppColors(
    positive: positive ?? this.positive,
    expense: expense ?? this.expense,
    warning: warning ?? this.warning,
    backdrop: backdrop ?? this.backdrop,
  );

  @override
  AppColors lerp(AppColors? other, double t) => other == null
      ? this
      : AppColors(
          positive: Color.lerp(positive, other.positive, t)!,
          expense: Color.lerp(expense, other.expense, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          backdrop: LinearGradient.lerp(backdrop, other.backdrop, t)!,
        );
}
