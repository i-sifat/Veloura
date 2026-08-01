import 'package:flutter/material.dart';

/// Shared measurements for the renovated Veloura interface.
///
/// Every gap, padding, and typography adjustment in the app should resolve
/// to one of these tokens instead of a one-off literal, so spacing and type
/// stay consistent across screens.
abstract final class AppDesignTokens {
  static const double radius = 20;
  static const double padding = 24;
  static const double cardRadius = 16;
  static const double navHeight = 92;

  /// 4pt spacing scale used for every gap and padding value in the app.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double spaceXxl = 24;
  static const double spaceXxxl = 32;

  /// Diameter of a decorative step-progress dot (see [StepProgressBar]).
  static const double stepDotSize = 26;

  /// Tight line-height for large multi-line display headlines.
  static const double lineHeightTight = 1.12;

  /// Slightly negative tracking for large display headlines.
  static const double letterSpacingTight = -0.5;

  static const cardBorder = Color(0xFF252B3A);
  static const subtlePink = Color(0x332D1020);

  static const surfaceShadow = BoxShadow(
    color: Color(0x52000000),
    blurRadius: 24,
    offset: Offset(0, 10),
  );
}
