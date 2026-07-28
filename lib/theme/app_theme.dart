import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:veloura/theme/app_colors.dart';

/// Material theme definitions for Veloura.
abstract final class AppTheme {
  static const pinkGlow = BoxShadow(
    color: Color(0x66FF4D6D),
    blurRadius: 24,
    spreadRadius: 1,
  );

  static ThemeData get dark {
    const colors = AppColors.dark;
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      colorScheme: const ColorScheme.dark(
        primary: colors.primary,
        secondary: colors.secondary,
        tertiary: colors.accent,
        surface: colors.surface,
        error: Color(0xFFFF6B6B),
        onPrimary: colors.textPrimary,
        onSecondary: Color(0xFF2B1018),
        onSurface: colors.textPrimary,
      ),
      textTheme: textTheme,
      dividerColor: colors.divider,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      ),
      extensions: const [colors],
    );
  }
}
