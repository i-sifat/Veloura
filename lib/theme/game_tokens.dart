import 'package:flutter/material.dart';

/// Shared visual and motion constants for every game experience.
abstract final class GameTokens {
  static const bgTop = Color(0xFF120B16);
  static const bgMid = Color(0xFF2B0B36);
  static const bgBottom = Color(0xFF47124F);
  static const vignette = Color(0xFF0B0210);
  static const rose = Color(0xFFFF4D6D);
  static const roseLight = Color(0xFFFF8FA3);
  static const roseDeep = Color(0xFFC81E67);
  static const textOnLight = Color(0xFF2A0A2E);
  static const glass = Color(0x0FFFFFFF);
  static const glassStrong = Color(0x1AFFFFFF);
  static const hairline = Color(0x1FFFFFFF);
  static const sheet = Color(0xF51D1423);
  static const scrim = Color(0x9908010C);

  static const screenPadH = 20.0;
  static const gridGutter = 12.0;
  static const cardRadius = 18.0;
  static const tileRadius = 22.0;
  static const sheetRadius = 28.0;
  static const ctaHeight = 56.0;
  static const ctaRadius = 28.0;
  static const tapScaleDuration = Duration(milliseconds: 110);
  static const fadeDuration = Duration(milliseconds: 220);
  static const sheetDuration = Duration(milliseconds: 320);

  static const tileShadow = BoxShadow(
    color: Color(0x57000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
  static const ctaShadow = BoxShadow(
    color: Color(0x57FF4D6D),
    blurRadius: 18,
    offset: Offset(0, 6),
  );

  static const lustfulRolls = [Color(0xFF5B2A9D), Color(0xFF8E4BD1)];
  static const cardChallenge = [Color(0xFFB01047), Color(0xFFE5326E)];
  static const truthOrDare = [Color(0xFF6C1450), Color(0xFFA02268)];
  static const creativeConnections = [Color(0xFF7A1D8F), Color(0xFFB03CC0)];
  static const followTheTempo = [Color(0xFF22114A), Color(0xFF4B2B8F)];
  static const passionateRoleplay = [Color(0xFF8E0F3C), Color(0xFFC2185B)];
}
