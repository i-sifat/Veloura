import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// The six fixed camera-facing rotations (radians), one per physical die
/// face, matching the design spec exactly:
/// face 1 -> {x:0, y:0}, face 2 -> {x:0, y:-90}, face 3 -> {x:-90, y:0},
/// face 4 -> {x:90, y:0}, face 5 -> {x:0, y:90}, face 6 -> {x:0, y:180}.
const List<(double x, double y)> kFaceLandingRotations = [
  (0, 0),
  (0, -math.pi / 2),
  (-math.pi / 2, 0),
  (math.pi / 2, 0),
  (0, math.pi / 2),
  (0, math.pi),
];

/// One physical cube face: its outward normal at rest, and the local
/// (yaw, pitch) that places its panel at that face when composing the cube.
///
/// Chosen so that rotating the *entire* cube by `kFaceLandingRotations[i]`
/// always brings face `i`'s normal to point straight at the camera
/// (0, 0, 1) - verified against the standard rotateX/rotateY matrices:
/// rotateY(y) maps (x,y,z) -> (x cos y + z sin y, y, -x sin y + z cos y),
/// rotateX(x) maps (x,y,z) -> (x, y cos x - z sin x, y sin x + z cos x).
class DieFaceDefinition {
  const DieFaceDefinition(this.normal, this.yaw, this.pitch);

  /// Unit outward normal (x, y, z) at rest (before any cube rotation).
  final (double, double, double) normal;
  final double yaw;
  final double pitch;
}

const List<DieFaceDefinition> kDieFaceDefinitions = [
  DieFaceDefinition((0, 0, 1), 0, 0),
  DieFaceDefinition((1, 0, 0), math.pi / 2, 0),
  DieFaceDefinition((0, -1, 0), 0, math.pi / 2),
  DieFaceDefinition((0, 1, 0), 0, -math.pi / 2),
  DieFaceDefinition((-1, 0, 0), -math.pi / 2, 0),
  DieFaceDefinition((0, 0, -1), math.pi, 0),
];

/// Smallest non-negative delta to add to [current] so it becomes congruent
/// with [target] (mod 2*pi) - i.e. the shortest *forward* rotation from
/// `current` that lands exactly on `target`.
double forwardDelta(double current, double target) {
  const tau = 2 * math.pi;
  final delta = (target - current) % tau;
  return delta < 0 ? delta + tau : delta;
}

/// Stepping-down angular rates for the five tumble segments (fast to slow),
/// per the design spec. Used only as *relative weights* between segments
/// (see [TumbleSchedule.buildProgressCurve]), not as absolute speeds.
const List<double> kTumbleRates = [0.95, 0.80, 0.62, 0.44, 0.27];

/// Fraction of the total 0..1 roll progress claimed by the five tumble
/// segments together; the rest (to 1.0) is the final easing segment.
const double kTumblePhaseShare = 0.8;

/// Extra full forward turns layered on top of the minimal angle needed to
/// reach the landing face, purely so the roll has enough visible travel to
/// read as a real throw rather than a small nudge.
const int kExtraForwardTurns = 6;

/// One planned roll: which face lands, the absolute rotation targets for
/// each axis, and the randomized tumble timing.
class RollPlan {
  const RollPlan({
    required this.landingFaceIndex,
    required this.rotationXTarget,
    required this.rotationYTarget,
    required this.tumble,
  });

  final int landingFaceIndex;
  final double rotationXTarget;
  final double rotationYTarget;
  final TumbleSchedule tumble;

  Duration get totalDuration => tumble.totalDuration;
}

/// Picks a random landing face and per-axis spin direction, and computes
/// the absolute forward-only rotation targets from the die's current
/// resting angles.
RollPlan planRoll({
  required math.Random random,
  required double currentRotationX,
  required double currentRotationY,
}) {
  final landingFaceIndex = random.nextInt(kDieFaceDefinitions.length);
  final (targetX, targetY) = kFaceLandingRotations[landingFaceIndex];
  final signX = random.nextBool() ? 1 : -1;
  final signY = random.nextBool() ? 1 : -1;
  return RollPlan(
    landingFaceIndex: landingFaceIndex,
    rotationXTarget: _forwardTarget(currentRotationX, targetX, signX),
    rotationYTarget: _forwardTarget(currentRotationY, targetY, signY),
    tumble: TumbleSchedule(random),
  );
}

/// Absolute rotation the die must reach, always strictly greater than (if
/// [sign] is 1) or strictly less than (if [sign] is -1) [current] - so
/// animating from `current` to this value only ever spins in that one
/// direction, plus [kExtraForwardTurns] full turns of travel.
double _forwardTarget(double current, double target, int sign) {
  const tau = 2 * math.pi;
  final minimalTravel = sign == 1
      ? forwardDelta(current, target)
      : forwardDelta(target, current);
  final travel = minimalTravel + kExtraForwardTurns * tau;
  return current + sign * travel;
}

/// Five stepping-down-rate tumble segments (340-500ms each) followed by a
/// 680ms `Curves.easeOutCubic` settle, exposed as a single monotonic
/// `Animatable<double>` from 0 (rest) to 1 (exact landing angle).
///
/// Multiply this curve's sampled value by a die's own real rotation delta
/// (target - current) to get that axis's actual angle at time t; both axes
/// can differ in total travel while staying perfectly time-synced, since
/// they share this same normalized 0..1 curve.
class TumbleSchedule {
  TumbleSchedule(math.Random random)
    : segmentDurations = List.generate(
        kTumbleRates.length,
        (_) => Duration(milliseconds: 340 + random.nextInt(161)),
      );

  static const finalSegmentDuration = Duration(milliseconds: 680);

  final List<Duration> segmentDurations;

  Duration get totalDuration => segmentDurations.fold(
    finalSegmentDuration,
    (sum, duration) => sum + duration,
  );

  /// Builds the normalized 0..1 progress curve: piecewise-linear through
  /// the five tumble segments (each claiming a share of the 0..[kTumblePhaseShare]
  /// range proportional to rate*duration - an authored "stair-step
  /// slowdown", not a simulated physical curve), then
  /// `Curves.easeOutCubic` covering [kTumblePhaseShare]..1.0.
  Animatable<double> buildProgressCurve() {
    final weights = [
      for (var i = 0; i < kTumbleRates.length; i++)
        kTumbleRates[i] * segmentDurations[i].inMilliseconds,
    ];
    final weightSum = weights.fold(0.0, (sum, w) => sum + w);
    var cumulativeShare = 0.0;
    final items = <TweenSequenceItem<double>>[];
    for (var i = 0; i < kTumbleRates.length; i++) {
      final start = cumulativeShare;
      cumulativeShare += kTumblePhaseShare * (weights[i] / weightSum);
      items.add(
        TweenSequenceItem(
          weight: segmentDurations[i].inMilliseconds.toDouble(),
          tween: Tween(begin: start, end: cumulativeShare),
        ),
      );
    }
    items.add(
      TweenSequenceItem(
        weight: finalSegmentDuration.inMilliseconds.toDouble(),
        tween: Tween(begin: kTumblePhaseShare, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
      ),
    );
    return TweenSequence<double>(items);
  }
}
