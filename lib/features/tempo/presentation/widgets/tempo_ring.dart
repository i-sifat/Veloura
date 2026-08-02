import 'package:flutter/material.dart';
import 'package:veloura/theme/game_tokens.dart';

/// A heartbeat ring that fills clockwise as a task's time elapses.
///
/// The center shows the tempo word (SLOW / FAST) and the seconds remaining.
/// Every beat the whole ring pulses like a heartbeat.
class TempoRing extends StatelessWidget {
  const TempoRing({
    required this.animation,
    required this.label,
    required this.secondsLeft,
    required this.progress,
    required this.running,
    required this.finale,
    required this.reduceMotion,
    super.key,
  });

  final Animation<double> animation;
  final String label;
  final int secondsLeft;

  /// 0..1 fill amount for the current task.
  final double progress;
  final bool running;
  final bool finale;
  final bool reduceMotion;

  static const double _dimension = 260;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: animation,
      child: SizedBox.square(
        dimension: _dimension,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: _dimension,
              child: CircularProgressIndicator(
                key: const ValueKey('tempo-ring-fill'),
                value: progress,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                color: GameTokens.rose,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  key: const ValueKey('tempo-instruction'),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    height: 26 / 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$secondsLeft',
                  key: const ValueKey('tempo-seconds'),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'SECONDS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.60),
                    letterSpacing: 2.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      builder: (context, child) {
        final value = running ? _pulse(animation.value) : 0.0;
        final scale = finale ? 1.14 : (reduceMotion ? 1.0 : 1 + 0.14 * value);
        final glow = finale ? 0.55 : 0.18 + 0.24 * value;
        return Transform.scale(
          scale: scale,
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
        );
      },
    ),
  );

  /// One fast outward beat followed by a slow return, like a pulse.
  double _pulse(double value) {
    if (value <= 0.35) {
      return Curves.easeOutQuad.transform(value / 0.35);
    }
    return 1 - Curves.easeInQuad.transform((value - 0.35) / 0.65);
  }
}
