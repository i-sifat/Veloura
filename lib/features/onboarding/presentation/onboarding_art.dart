import 'package:flutter/material.dart';
import 'package:veloura/features/onboarding/presentation/onboarding_tokens.dart';

/// Branded artwork for the three introduction pages, backed by the supplied
/// onboarding illustrations.
class OnboardingArt extends StatelessWidget {
  const OnboardingArt({required this.variant, super.key});

  final int variant;

  /// Per-page illustrations. The first and third files intentionally carry a
  /// double `.png.png` extension to match the committed asset filenames.
  static const _assets = <String>[
    'assets/onboarding/onboarding_first_page.png.png',
    'assets/onboarding/onboarding_second_page.png',
    'assets/onboarding/onboarding_third_trackyourconnection_page.png.png',
  ];

  @override
  Widget build(BuildContext context) {
    final asset = _assets[variant.clamp(0, _assets.length - 1)];
    return SizedBox(
      height: OnboardingTokens.visualHeight,
      child: Center(
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.favorite_border_rounded,
            size: 140,
            color: OnboardingTokens.pinkLight,
            shadows: [OnboardingTokens.glow],
          ),
        ),
      ),
    );
  }
}
