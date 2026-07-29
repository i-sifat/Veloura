import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/dice/presentation/widgets/die_motion.dart';

void main() {
  const epsilon = 1e-9;

  DieMotion motionFor(int face) => DieMotion(
    delay: Duration.zero,
    turnsX: 3.3,
    turnsY: 1.9,
    turnsZ: 1.4,
    landingFaceIndex: face,
    lift: 0.16,
    liftPx: 38,
    wobbleAmplitude: 0.10,
    startX: -1.2,
    startY: -0.8,
    endX: 0.3,
    endY: 0.2,
    restTiltX: 0.28,
    restTiltY: -0.34,
  );

  bool isQuarterTurn(double angle) {
    final turns = angle / (math.pi / 2);
    return (turns - turns.round()).abs() < epsilon;
  }

  test('base landing orientations are exact quarter turns', () {
    for (var face = 0; face < 6; face++) {
      final (x, y) = DieMotion.orientationForFace(face);
      expect(isQuarterTurn(x), isTrue, reason: 'face $face x');
      expect(isQuarterTurn(y), isTrue, reason: 'face $face y');
    }
  });

  test('every result face settles with the intentional three-face tilt', () {
    for (var face = 0; face < 6; face++) {
      final motion = motionFor(face);
      final frame = motion.at(1);
      final (baseX, baseY) = DieMotion.orientationForFace(face);
      expect(frame.rotationX, closeTo(baseX + motion.restTiltX, epsilon));
      expect(frame.rotationY, closeTo(baseY + motion.restTiltY, epsilon));
      expect(frame.rotationZ, closeTo(0, epsilon));
    }
  });

  test('die travels from outside the board to its scattered resting point', () {
    final motion = motionFor(0);
    final start = motion.at(0);
    final middle = motion.at(0.46);
    final end = motion.at(1);

    expect(start.translateX, closeTo(motion.startX, epsilon));
    expect(start.translateY, closeTo(motion.startY, epsilon));
    expect(middle.translateY, lessThan(motion.endY));
    expect(end.translateX, closeTo(motion.endX, epsilon));
    expect(end.translateY, closeTo(motion.endY, epsilon));
  });

  test('flight begins and ends grounded and rises mid-throw', () {
    final motion = motionFor(0);
    expect(motion.at(0).flightHeight, 0);
    expect(motion.at(0.45).flightHeight, greaterThan(0.95));
    expect(motion.at(1).flightHeight, 0);
  });

  test('all numeric frame values stay finite', () {
    final motion = motionFor(3);
    for (var step = 0; step <= 100; step++) {
      final frame = motion.at(step / 100);
      final values = [
        frame.rotationX,
        frame.rotationY,
        frame.rotationZ,
        frame.scaleX,
        frame.scaleY,
        frame.translateX,
        frame.translateY,
        frame.bounceY,
        frame.flightHeight,
        frame.shadowWidthFactor,
        frame.shadowBlur,
        frame.shadowOpacity,
        frame.blurSigma,
        frame.textOpacity,
      ];
      expect(values.every((value) => value.isFinite), isTrue);
    }
  });

  test('different random seeds produce visibly different throws', () {
    final first = DieMotion.random(math.Random(1), dieIndex: 0);
    final second = DieMotion.random(math.Random(2), dieIndex: 0);
    expect(
      first.turnsX != second.turnsX ||
          first.turnsY != second.turnsY ||
          first.landingFaceIndex != second.landingFaceIndex ||
          first.endX != second.endX ||
          first.restTiltY != second.restTiltY,
      isTrue,
    );
  });

  test('landing changes from false to true exactly once', () {
    final motion = motionFor(5);
    var transitions = 0;
    var previous = motion.at(0).hasLanded;
    expect(previous, isFalse);
    for (var step = 1; step <= 100; step++) {
      final current = motion.at(step / 100).hasLanded;
      if (current != previous) transitions++;
      previous = current;
    }
    expect(previous, isTrue);
    expect(transitions, 1);
  });
}
