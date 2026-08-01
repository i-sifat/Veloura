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
    final bodyTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );
    final textTheme = _withDisplayFont(bodyTheme);

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
        foregroundColor: Color(0xFFF7F8FB),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // `colorScheme.primary` stays vivid for icons/accents; buttons use
          // the deeper `buttonFill` so white labels clear WCAG AAA (>= 7:1).
          backgroundColor: colors.buttonFill,
          foregroundColor: Colors.white,
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

  /// Layers a premium display serif onto headline-weight styles while
  /// keeping Inter for body copy and UI chrome, so long-form/instructional
  /// text stays easy to read for non-native English speakers.
  static TextTheme _withDisplayFont(TextTheme base) => base.copyWith(
    displayLarge: GoogleFonts.playfairDisplay(textStyle: base.displayLarge),
    displayMedium: GoogleFonts.playfairDisplay(textStyle: base.displayMedium),
    displaySmall: GoogleFonts.playfairDisplay(textStyle: base.displaySmall),
    headlineLarge: GoogleFonts.playfairDisplay(textStyle: base.headlineLarge),
    headlineMedium: GoogleFonts.playfairDisplay(
      textStyle: base.headlineMedium,
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: GoogleFonts.playfairDisplay(
      textStyle: base.headlineSmall,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: GoogleFonts.playfairDisplay(
      textStyle: base.titleLarge,
      fontWeight: FontWeight.w600,
    ),
  );
}
