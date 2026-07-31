import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:veloura/theme/app_colors.dart';

/// Material theme definitions for Veloura.
abstract final class AppTheme {
  static const pinkGlow = BoxShadow(
    color: Color(0x3DFF4D7D),
    blurRadius: 24,
    spreadRadius: 1,
  );

  static ThemeData get dark {
    const colors = AppColors.dark;
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF4D7D),
        secondary: Color(0xFFC44DFF),
        tertiary: Color(0xFFFF9A3C),
        surface: Color(0xFF131722),
        error: Color(0xFFFF6B6B),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFFF7F8FB),
      ),
      textTheme: textTheme,
      dividerColor: colors.divider,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      extensions: const [AppColors.dark],
    );
  }
}
