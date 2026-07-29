import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// A deterministic board trajectory and tumble for one word die.
class DieMotion {
  const DieMotion({
    required this.delay,
    required this.turnsX,
    required this.turnsY,
    required this.landingFaceIndex,
    required this.lift,
    required this.liftPx,
    required this.wobbleAmplitude,
    this.turnsZ = 0,
    this.startX = 0,
    this.startY = 0,
    this.endX = 0,
    this.endY = 0,
    this.arcHeight = 0.45,
    this.restTiltX = 0.28,
    this.restTiltY = -0.34,
  }) : assert(landingFaceIndex >= 0 && landingFaceIndex < 6);

  /// Shared throw duration, including travel, tumble, impact, and settle.
  static const totalDuration = Duration(milliseconds: 1800);

  final Duration delay;
  final double turnsX;
  final double turnsY;
  final double turnsZ;
  final int landingFaceIndex;
  final double lift;
  final double liftPx;
  final double wobbleAmplitude;

  /// Board-relative positions where -1/1 are the usable board edges.
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double arcHeight;
  final double restTiltX;
  final double restTiltY;

  /// Creates a varied entrance and scattered landing for [dieIndex].
  factory DieMotion.random(math.Random rng, {required int dieIndex}) {
    final totalTurns = 3 + rng.nextDouble() * 2.2;
    final weightX = 0.3 + rng.nextDouble() * 0.4;
    final end = switch (dieIndex) {
      0 => (-0.34 + rng.nextDouble() * 0.12, 0.18 + rng.nextDouble() * 0.14),
      1 => (0.34 - rng.nextDouble() * 0.12, -0.12 + rng.nextDouble() * 0.14),
      _ => (-0.04 + rng.nextDouble() * 0.16, 0.52 - rng.nextDouble() * 0.12),
    };
    final start = switch (dieIndex) {
      0 => (-1.25, -0.82),
      1 => (1.25, -0.68),
      _ => (-0.95, 1.12),
    };
    return DieMotion(
      delay: Duration(milliseconds: dieIndex * 90 + rng.nextInt(55)),
      turnsX: totalTurns * weightX,
      turnsY: totalTurns * (1 - weightX),
      turnsZ: 1.2 + rng.nextDouble() * 1.6,
      landingFaceIndex: rng.nextInt(6),
      lift: 0.12 + rng.nextDouble() * 0.12,
      liftPx: 28 + rng.nextDouble() * 24,
      wobbleAmplitude: 0.08 + rng.nextDouble() * 0.05,
      startX: start.$1,
      startY: start.$2,
      endX: end.$1,
      endY: end.$2,
      arcHeight: 0.38 + rng.nextDouble() * 0.28,
      restTiltX: (rng.nextBool() ? 1 : -1) * (0.22 + rng.nextDouble() * 0.14),
      restTiltY: (rng.nextBool() ? 1 : -1) * (0.28 + rng.nextDouble() * 0.16),
    );
  }

  /// Axis rotations that bring [index] to the camera before resting tilt.
  static (double, double) orientationForFace(int index) => switch (index) {
    0 => (0, 0),
    1 => (0, math.pi),
    2 => (0, -math.pi / 2),
    3 => (0, math.pi / 2),
    4 => (-math.pi / 2, 0),
    5 => (math.pi / 2, 0),
    _ => throw RangeError.range(index, 0, 5, 'index'),
  };

  /// Samples the full transform and shadow state at shared time [globalT].
  DieFrame at(double globalT) {
    final delayFraction = delay.inMicroseconds / totalDuration.inMicroseconds;
    final t = _clamp01(
      (globalT.clamp(0.0, 1.0) - delayFraction) / (1 - delayFraction),
    );
    final (landingX, landingY) = orientationForFace(landingFaceIndex);

    final travel = Curves.easeOutCubic.transform(_clamp01(t / 0.72));
    final settle = switch (t) {
      < 0.08 => 0.0,
      < 0.70 => 0.84 * const Cubic(0.12, 0.78, 0.06, 1).transform(
        _clamp01((t - 0.08) / 0.62),
      ),
      < 0.90 => 0.84 + 0.16 * Curves.easeOutCubic.transform(
        _clamp01((t - 0.70) / 0.20),
      ),
      _ => 1.0,
    };

    final decelerationT = _clamp01((t - 0.70) / 0.20);
    final decay = 1 - decelerationT;
    final wobble = t >= 0.70 && t < 0.90
        ? math.sin(decelerationT * 6 * math.pi) *
              decay *
              decay *
              wobbleAmplitude
        : 0.0;
    final flightHeight = t >= 0.90 ? 0.0 : math.sin(_clamp01(t / 0.90) * math.pi);
    final impactT = _clamp01((t - 0.90) / 0.10);
    final impactEnvelope = t < 0.90
        ? 0.0
        : math.sin(impactT * math.pi) * (1 - impactT);
    final bounce = t < 0.90
        ? 0.0
        : -math.sin(impactT * 3 * math.pi).abs() * 9 * (1 - impactT);

    final horizontalDrift = math.sin(travel * math.pi) *
        (endX >= startX ? 0.16 : -0.16);
    final boardX = _lerp(startX, endX, travel) + horizontalDrift;
    final boardY = _lerp(startY, endY, travel) -
        math.sin(travel * math.pi) * arcHeight;

    final speedEnvelope = t < 0.10
        ? t / 0.10
        : t < 0.72
        ? (0.72 - t) / 0.62
        : 0.0;
    final blurSigma = 2.2 * _clamp01(speedEnvelope);

    return DieFrame(
      rotationX:
          landingX + restTiltX + (1 - settle) * turnsX * 2 * math.pi + wobble,
      rotationY:
          landingY + restTiltY + (1 - settle) * turnsY * 2 * math.pi - wobble,
      rotationZ: (1 - settle) * turnsZ * 2 * math.pi,
      scaleX: 1 + lift * flightHeight + 0.10 * impactEnvelope,
      scaleY: 1 + lift * flightHeight - 0.14 * impactEnvelope,
      translateX: boardX,
      translateY: boardY,
      bounceY: -liftPx * flightHeight + bounce,
      flightHeight: flightHeight,
      shadowWidthFactor: 0.70 + 0.42 * (1 - flightHeight),
      shadowBlur: 7 + 22 * flightHeight,
      shadowOpacity: 0.38 * (1 - 0.74 * flightHeight),
      blurSigma: blurSigma,
      textOpacity: 1 - 0.35 * (blurSigma / 2.2),
      hasLanded: t >= 0.90,
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static double _clamp01(num value) => value.clamp(0.0, 1.0).toDouble();
}

/// Immutable visual values sampled from a [DieMotion].
class DieFrame {
  const DieFrame({
    required this.rotationX,
    required this.rotationY,
    required this.rotationZ,
    required this.scaleX,
    required this.scaleY,
    required this.translateX,
    required this.translateY,
    required this.bounceY,
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
  final double rotationZ;
  final double scaleX;
  final double scaleY;
  final double translateX;
  final double translateY;
  final double bounceY;
  final double flightHeight;
  final double shadowWidthFactor;
  final double shadowBlur;
  final double shadowOpacity;
  final double blurSigma;
  final double textOpacity;
  final bool hasLanded;
}
