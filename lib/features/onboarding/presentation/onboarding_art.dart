import 'package:flutter/material.dart';
import 'package:veloura/features/onboarding/presentation/onboarding_tokens.dart';

/// Branded artwork used by the three introduction pages.
class OnboardingArt extends StatelessWidget {
  const OnboardingArt({required this.variant, super.key});

  final int variant;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: OnboardingTokens.visualHeight,
    child: Center(
      child: switch (variant) {
        0 => const _TogetherArt(),
        1 => const _PlayArt(),
        _ => const _JourneyArt(),
      },
    ),
  );
}

class _TogetherArt extends StatelessWidget {
  const _TogetherArt();

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      const _GlowOrb(size: 210),
      Icon(
        Icons.favorite_border_rounded,
        size: 154,
        color: OnboardingTokens.pinkLight.withValues(alpha: 0.95),
        shadows: const [OnboardingTokens.glow],
      ),
      const Positioned(
        bottom: 42,
        child: Icon(Icons.people_alt_rounded, size: 82, color: Colors.white),
      ),
    ],
  );
}

class _PlayArt extends StatelessWidget {
  const _PlayArt();

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      const _GlowOrb(size: 230),
      Transform.rotate(
        angle: -0.18,
        child: const _Dice(icon: Icons.favorite_rounded, color: Color(0xFF20162B)),
      ),
      Transform.translate(
        offset: const Offset(62, 38),
        child: Transform.rotate(
          angle: 0.18,
          child: const _Dice(icon: Icons.favorite_rounded, color: OnboardingTokens.pink),
        ),
      ),
    ],
  );
}

class _Dice extends StatelessWidget {
  const _Dice({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 112,
    height: 112,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: OnboardingTokens.pink.withValues(alpha: 0.45)),
      boxShadow: const [OnboardingTokens.glow],
    ),
    child: Icon(icon, color: OnboardingTokens.pinkLight, size: 48),
  );
}

class _JourneyArt extends StatelessWidget {
  const _JourneyArt();

  @override
  Widget build(BuildContext context) => Container(
    width: 280,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF241124), OnboardingTokens.elevated],
      ),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: OnboardingTokens.pink.withValues(alpha: 0.45)),
      boxShadow: const [OnboardingTokens.glow],
    ),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StreakRing(),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(icon: Icons.favorite, value: '32', label: 'Games'),
            _Stat(icon: Icons.star, value: '8', label: 'Challenges'),
            _Stat(icon: Icons.people, value: '2', label: 'Partners'),
          ],
        ),
      ],
    ),
  );
}

class _StreakRing extends StatelessWidget {
  const _StreakRing();

  @override
  Widget build(BuildContext context) => Container(
    width: 104,
    height: 104,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: OnboardingTokens.pinkLight, width: 4),
      boxShadow: const [OnboardingTokens.glow],
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('14', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
        Text('🔥 Day streak', style: TextStyle(fontSize: 11)),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 18, color: OnboardingTokens.pinkLight),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      Text(label, style: const TextStyle(fontSize: 10, color: OnboardingTokens.muted)),
    ],
  );
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [Color(0x40E11D2E), Colors.transparent]),
    ),
  );
}
