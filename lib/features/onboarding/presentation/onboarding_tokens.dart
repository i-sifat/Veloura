import 'package:flutter/material.dart';
import 'package:veloura/theme/app_design_tokens.dart';

/// Feature-scoped visual tokens for the cinematic onboarding flow.
abstract final class OnboardingTokens {
  static const pageCount = 6;
  static const setupStartIndex = 3;

  /// Index of the sex-selection page (immediately after the names page).
  static const sexPageIndex = setupStartIndex + 1;

  static const maxWidth = 430.0;
  static const fieldHeight = 72.0;
  static const choiceHeight = 132.0;
  static const pagePadding = AppDesignTokens.padding;
  static const cardRadius = AppDesignTokens.cardRadius;

  /// Vertical placement of the Veloura wordmark over the first intro
  /// illustration, expressed as an [Alignment] `y` within the image box
  /// (-1 = top edge, 0 = center, 1 = bottom edge). Kept slightly above center
  /// so the wordmark sits on the upper part of the hands. Nudge this single
  /// value if the wordmark ever drifts off the hands.
  static const brandOverlayAlignmentY = -0.1;

  static const background = Color(0xFF050711);
  static const elevated = Color(0xFF0D1020);
  static const border = Color(0xFF28283D);
  static const muted = Color(0xFFAAA8B5);
  static const violet = Color(0xFF8A75A8);

  // Brand accent. Historically pink; the palette moved to red to match the
  // app-wide red CTA/nav accent. The `pink`/`pinkLight` names are kept
  // stable so the onboarding widgets that reference them don't need to churn.
  static const pink = Color(0xFFE11D2E);
  static const pinkLight = Color(0xFFFF5A6E);

  static const glow = BoxShadow(
    color: Color(0x66E11D2E),
    blurRadius: 34,
    spreadRadius: 2,
  );

  static const backgroundGradient = RadialGradient(
    center: Alignment(0.15, -0.45),
    radius: 1.15,
    colors: [Color(0x261A0B2C), background],
  );
}
