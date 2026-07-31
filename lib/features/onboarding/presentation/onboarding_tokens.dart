import 'package:flutter/material.dart';
import 'package:veloura/theme/app_design_tokens.dart';

/// Feature-scoped visual tokens for the cinematic onboarding flow.
abstract final class OnboardingTokens {
  static const pageCount = 6;
  static const setupStartIndex = 3;
  static const maxWidth = 430.0;
  static const visualHeight = 300.0;
  static const fieldHeight = 72.0;
  static const choiceHeight = 132.0;
  static const pagePadding = AppDesignTokens.padding;
  static const cardRadius = AppDesignTokens.cardRadius;

  static const background = Color(0xFF050711);
  static const elevated = Color(0xFF0D1020);
  static const border = Color(0xFF28283D);
  static const muted = Color(0xFFAAA8B5);
  static const violet = Color(0xFF8A75A8);
  static const pink = Color(0xFFFF1F68);
  static const pinkLight = Color(0xFFFF5791);

  static const glow = BoxShadow(
    color: Color(0x66FF1F68),
    blurRadius: 34,
    spreadRadius: 2,
  );

  static const backgroundGradient = RadialGradient(
    center: Alignment(0.15, -0.45),
    radius: 1.15,
    colors: [Color(0x261A0B2C), background],
  );
}
