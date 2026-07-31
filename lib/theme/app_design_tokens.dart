import 'package:flutter/material.dart';

/// Shared measurements for the renovated Veloura interface.
abstract final class AppDesignTokens {
  static const double radius = 20;
  static const double padding = 24;
  static const double cardRadius = 16;
  static const double navHeight = 92;

  static const cardBorder = Color(0xFF252B3A);
  static const subtlePink = Color(0x332D1020);

  static const surfaceShadow = BoxShadow(
    color: Color(0x52000000),
    blurRadius: 24,
    offset: Offset(0, 10),
  );
}
