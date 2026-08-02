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
/// per the design spec.
const List<double> kTumbleRates = [0.95, 0.80, 0.62, 0.44, 0.27];

/// Authored reference speed: how many full turns a rate of 1.0 covers per
/// second. There is no external spec for this exact number - it's a
/// deliberate authored choice to make the tumble read as "fast", matched
/// against extraTurns below so the final ease phase always has forward
/// distance left to cover.
const double kReferenceTurnsPerSecond = 3.0;

/// Extra full forward turns layered on top of the minimal angle needed to
/// reach the landing face, so the roll always has visible travel. Chosen
/// comfortably above the maximum turns the tumble segments could possibly
/// cover (5 segments * up to 500ms * rate <= 1.0 * 3 turns/s ~= 4.6 turns
/// worst case), so the final easing segment never has to move backward.
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

  /// Turns (fractional) covered by the tumble phase alone, before the
  /// final easing segment takes over. Always well under
  /// [kExtraForwardTurns] (see its doc comment), so the final segment
  /// always has forward distance left to animate.
  double get tumbleTurnsCovered {
    var turns = 0.0;
    for (var i = 0; i < kTumbleRates.length; i++) {
      final seconds = segmentDurations[i].inMilliseconds / 1000;
      turns += kTumbleRates[i] * kReferenceTurnsPerSecond * seconds;
    }
    return turns;
  }

  /// Builds the normalized 0..1 progress curve: piecewise-linear through
  /// the five tumble segments (each covering its own share of
  /// [tumbleTurnsCovered], at a constant rate within the segment - an
  /// authored "stair-step slowdown", not a simulated physical curve), then
  /// `Curves.easeOutCubic` for the remaining distance to 1.0.
  Animatable<double> buildProgressCurve() {
    final totalTurns = tumbleTurnsCovered + _remainingTurnsPlaceholder;
    var cumulativeTurns = 0.0;
    final items = <TweenSequenceItem<double>>[];
    for (var i = 0; i < kTumbleRates.length; i++) {
      final seconds = segmentDurations[i].inMilliseconds / 1000;
      final segmentTurns = kTumbleRates[i] * kReferenceTurnsPerSecond * seconds;
      final start = cumulativeTurns / totalTurns;
      cumulativeTurns += segmentTurns;
      final end = cumulativeTurns / totalTurns;
      items.add(
        TweenSequenceItem(
          weight: segmentDurations[i].inMilliseconds.toDouble(),
          tween: Tween(begin: start, end: end),
        ),
      );
    }
    items.add(
      TweenSequenceItem(
        weight: finalSegmentDuration.inMilliseconds.toDouble(),
        tween: Tween(begin: cumulativeTurns / totalTurns, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
      ),
    );
    return TweenSequence<double>(items);
  }

  // Placeholder so buildProgressCurve's totalTurns matches the *actual*
  // forward travel passed in by the caller; overwritten by
  // WordDieState.roll(), which rescales this curve's 0..1 output against
  // the real rotationXTarget/rotationYTarget deltas rather than this
  // schedule's own (rate-only) turn estimate.
  static const _remainingTurnsPlaceholder = 0.0001;
}
