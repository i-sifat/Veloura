import 'package:flutter/material.dart';
import 'package:veloura/features/onboarding/presentation/onboarding_tokens.dart';

/// Full-bleed onboarding illustration used as the page background for the
/// three intro screens.
///
/// The artwork fills the full screen width edge to edge with [BoxFit.fitWidth]
/// (never stretched or distorted) and is pinned to the top, so it reads as the
/// whole-screen backdrop rather than a small centered graphic. On the brand
/// page ([variant] 0) the Veloura wordmark is overlaid onto the upper part of
/// the illustration's hands; its vertical position is driven by
/// [OnboardingTokens.brandOverlayAlignmentY] and locked to the image box, so
/// it tracks the artwork across screen sizes.
class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({required this.variant, super.key});

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
    // The brand page's illustration sits a bit lower so the hands read as
    // centered artwork rather than pinned to the very top of the screen, and
    // the second page's illustration is vertically centered.
    final drop = variant == 0 ? MediaQuery.sizeOf(context).height * 0.13 : 0.0;
    final imageAlignment = variant == 1 ? Alignment.center : Alignment.topCenter;
    return Align(
      alignment: imageAlignment,
      child: Transform.translate(
        offset: Offset(0, drop),
        child: Stack(
          children: [
          Image.asset(
            asset,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            alignment: imageAlignment,
            errorBuilder: (_, _, _) => const SizedBox.expand(),
          ),
          // Soft bottom scrim so the page title/body copy stays legible where
          // it overlaps the lower part of the illustration.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, OnboardingTokens.background],
                ),
              ),
            ),
          ),
          if (variant == 0)
            const Positioned.fill(
              child: Align(
                alignment: Alignment(0, OnboardingTokens.brandOverlayAlignmentY),
                child: _BrandWordmark(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Veloura brand lockup overlaid on the first intro illustration.
class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'Veloura',
        style: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 2)),
          ],
        ),
      ),
      Text(
        'Play. Connect. Grow together.',
        style: TextStyle(
          color: OnboardingTokens.pinkLight,
          fontSize: 13,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 1)),
          ],
        ),
      ),
    ],
  );
}
