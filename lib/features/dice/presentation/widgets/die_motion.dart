import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Physics-plausible, deterministic motion parameters for one die.
class DieMotion {
  const DieMotion({
    required this.delay,
    required this.turnsX,
    required this.turnsY,
    required this.landingFaceIndex,
    required this.lift,
    required this.liftPx,
    required this.wobbleAmplitude,
  }) : assert(landingFaceIndex >= 0 && landingFaceIndex < 6);

  /// Total shared animation duration used by the dice stage.
  static const totalDuration = Duration(milliseconds: 1150);

  final Duration delay;
  final double turnsX;
  final double turnsY;
  final int landingFaceIndex;
  final double lift;
  final double liftPx;
  final double wobbleAmplitude;

  /// Creates varied motion while preserving the documented timing bounds.
  factory DieMotion.random(math.Random rng, {required int dieIndex}) {
    final totalTurns = 2 + rng.nextDouble() * 1.5;
    final weightX = 0.25 + rng.nextDouble() * 0.5;
    return DieMotion(
      delay: Duration(milliseconds: dieIndex * 70 + rng.nextInt(40)),
      turnsX: totalTurns * weightX,
      turnsY: totalTurns * (1 - weightX),
      landingFaceIndex: rng.nextInt(6),
      lift: 0.06 + rng.nextDouble() * 0.06,
      liftPx: 10 + rng.nextDouble() * 8,
      wobbleAmplitude: 0.07 + rng.nextDouble() * 0.02,
    );
  }

  /// Axis-aligned rotations that bring [index] dead-on to the camera.
  static (double, double) orientationForFace(int index) => switch (index) {
    0 => (0, 0),
    1 => (0, math.pi),
    2 => (0, -math.pi / 2),
    3 => (0, math.pi / 2),
    4 => (-math.pi / 2, 0),
    5 => (math.pi / 2, 0),
    _ => throw RangeError.range(index, 0, 5, 'index'),
  };

  /// Samples the complete visual state at normalized shared time [globalT].
  DieFrame at(double globalT) {
    final delayFraction = delay.inMicroseconds / totalDuration.inMicroseconds;
    final t = ((globalT.clamp(0.0, 1.0) - delayFraction) /
            (1 - delayFraction))
        .clamp(0.0, 1.0);
    final (landingX, landingY) = orientationForFace(landingFaceIndex);

    final progress = switch (t) {
      < 0.08 => 0.0,
      < 0.62 =>
        0.78 *
            const Cubic(0.15, 0.85, 0.10, 1.00).transform(
              ((t - 0.08) / 0.54).clamp(0.0, 1.0),
            ),
      < 0.85 =>
        0.78 +
            0.22 *
                Curves.easeOutCubic.transform(
                  ((t - 0.62) / 0.23).clamp(0.0, 1.0),
                ),
      _ => 1.0,
    };

    final decelerationT = ((t - 0.62) / 0.23).clamp(0.0, 1.0);
    final wobble = t >= 0.62 && t < 0.85
        ? math.sin(decelerationT * 6 * math.pi) *
              math.pow(1 - decelerationT, 3) *
              wobbleAmplitude
        : 0.0;
    final flightT = ((t - 0.08) / 0.77).clamp(0.0, 1.0);
    final flightHeight = t < 0.08 || t >= 0.85
        ? 0.0
        : math.sin(flightT * math.pi);
    final impactT = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
    final impactEnvelope = t < 0.85
        ? 0.0
        : math.sin(impactT * math.pi) * (1 - impactT);
    final bounce = t < 0.85
        ? 0.0
        : -math.sin(impactT * 2 * math.pi).abs() * 6 * (1 - impactT);

    final blurProgress = t <= 0.08
        ? 0.0
        : t < 0.3
        ? (t - 0.08) / 0.22
        : t < 0.75
        ? (0.75 - t) / 0.45
        : 0.0;
    final blurSigma = 2.6 * blurProgress.clamp(0.0, 1.0);

    return DieFrame(
      rotationX: landingX + (1 - progress) * turnsX * 2 * math.pi + wobble,
      rotationY: landingY + (1 - progress) * turnsY * 2 * math.pi - wobble * 0.7,
      scaleX: 1 + lift * flightHeight + 0.08 * impactEnvelope,
      scaleY: 1 + lift * flightHeight - 0.12 * impactEnvelope,
      translateY: -liftPx * flightHeight + bounce,
      flightHeight: flightHeight,
      shadowWidthFactor: 0.55 + 0.35 * (1 - flightHeight),
      shadowBlur: 6 + 18 * flightHeight,
      shadowOpacity: 0.34 * (1 - 0.7 * flightHeight),
      blurSigma: blurSigma,
      textOpacity: 1 - 0.45 * (blurSigma / 2.6),
      hasLanded: t >= 0.85,
    );
  }
}

/// Immutable visual values sampled from a [DieMotion].
class DieFrame {
  const DieFrame({
    required this.rotationX,
    required this.rotationY,
    required this.scaleX,
    required this.scaleY,
    required this.translateY,
    required this.flightHeight,
    required this.shadowWidthFactor,
    required this.shadowBlur,
    required this.shadowOpacity,
    required this.blurSigma,
    required this.textOpacity,
    required this.hasLanded,
  });

  final double rotationX;
  final double rotationY;
  final double scaleX;
  final double scaleY;
  final double translateY;
  final double flightHeight;
  final double shadowWidthFactor;
  final double shadowBlur;
  final double shadowOpacity;
  final double blurSigma;
  final double textOpacity;
  final bool hasLanded;
}
