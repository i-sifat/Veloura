import 'package:flutter/material.dart';

/// Veloura's semantic color palette.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.success,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
  });

  static const dark = AppColors(
    background: Color(0xFF120B16),
    surface: Color(0xFF1D1423),
    card: Color(0xFF2A1D31),
    primary: Color(0xFFFF4D6D),
    secondary: Color(0xFFFF8FA3),
    accent: Color(0xFFFFB703),
    success: Color(0xFF54D67A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB9B3C5),
    divider: Color(0xFF392A42),
  );

  /// Reserved light-mode palette. Light mode is not exposed in v1.
  static const light = AppColors(
    background: Color(0xFFFFF7FA),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFEAF0),
    primary: Color(0xFFD92E52),
    secondary: Color(0xFFB84B68),
    accent: Color(0xFF9A6500),
    success: Color(0xFF237A43),
    textPrimary: Color(0xFF21151F),
    textSecondary: Color(0xFF675B65),
    divider: Color(0xFFE6D7DF),
  );

  final Color background;
  final Color surface;
  final Color card;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color success;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? dark;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? success,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
