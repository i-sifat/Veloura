import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Minimal WCAG 2.1 relative-luminance / contrast-ratio helpers used only by
/// tests, to guard the AAA color decisions in app_colors.dart and
/// game_tokens.dart against future regressions. Not a *_test.dart file, so
/// `flutter test` does not treat it as its own suite.
double relativeLuminance(Color color) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
