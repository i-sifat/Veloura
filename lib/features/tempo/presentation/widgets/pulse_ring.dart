import 'package:flutter/material.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Animated visual metronome driven by one cached animation subtree.
class PulseRing extends StatelessWidget {
  const PulseRing({
    required this.animation,
    required this.label,
    required this.running,
    required this.finale,
    required this.reduceMotion,
    super.key,
  });

  final Animation<double> animation;
  final String label;
  final bool running;
  final bool finale;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: animation,
      child: SizedBox.square(
        dimension: 240,
        child: Center(
          child: Text(
            label,
            key: const ValueKey('tempo-instruction'),
            maxLines: 1,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              height: 26 / 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ),
      ),
      builder: (context, child) {
        final value = running ? _pulse(animation.value) : 0.0;
        final scale = finale ? 1.14 : (reduceMotion ? 1.0 : 1 + 0.14 * value);
        final glow = finale ? 0.55 : 0.18 + 0.24 * value;
        final strokeOpacity = reduceMotion && running
            ? 0.30 + 0.40 * value
            : 0.70;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: GameTokens.rose.withValues(alpha: strokeOpacity),
                width: 4,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  radius: 0.55,
                  colors: [
                    GameTokens.rose.withValues(alpha: glow),
                    Colors.transparent,
                  ],
                ),
              ),
              child: child,
            ),
          ),
        );
      },
    ),
  );

  double _pulse(double value) {
    if (value <= 0.35) {
      return Curves.easeOutQuad.transform(value / 0.35);
    }
    return 1 - Curves.easeInQuad.transform((value - 0.35) / 0.65);
  }
}
