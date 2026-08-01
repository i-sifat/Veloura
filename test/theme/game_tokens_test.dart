import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/theme/game_tokens.dart';

import 'wcag_contrast.dart';

void main() {
  test('primary CTA gradient clears WCAG AAA for a white label at both stops', () {
    const white = Color(0xFFFFFFFF);
    expect(
      contrastRatio(white, GameTokens.ctaGradientStart),
      greaterThanOrEqualTo(7),
    );
    expect(
      contrastRatio(white, GameTokens.ctaGradientEnd),
      greaterThanOrEqualTo(7),
    );
  });
}
