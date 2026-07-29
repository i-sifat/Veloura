import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/dice/presentation/widgets/die_motion.dart';

void main() {
  const epsilon = 1e-9;

  DieMotion motionFor(int face) => DieMotion(
    delay: Duration.zero,
    turnsX: 2.3,
    turnsY: 0.9,
    landingFaceIndex: face,
    lift: 0.09,
    liftPx: 14,
    wobbleAmplitude: 0.09,
  );

  bool isQuarterTurn(double angle) {
    final turns = angle / (math.pi / 2);
    return (turns - turns.round()).abs() < epsilon;
  }

  test('all landing orientations are exact quarter turns', () {
    for (var face = 0; face < 6; face++) {
      final (x, y) = DieMotion.orientationForFace(face);
      expect(isQuarterTurn(x), isTrue, reason: 'face $face x');
      expect(isQuarterTurn(y), isTrue, reason: 'face $face y');
    }
  });

  test('every face settles exactly axis aligned', () {
    for (var face = 0; face < 6; face++) {
      final frame = motionFor(face).at(1);
      expect(isQuarterTurn(frame.rotationX), isTrue, reason: 'face $face x');
      expect(isQuarterTurn(frame.rotationY), isTrue, reason: 'face $face y');
    }
  });

  test('flight begins and ends grounded and rises mid-roll', () {
    final motion = motionFor(0);
    expect(motion.at(0).flightHeight, 0);
    expect(motion.at(0.46).flightHeight, greaterThan(0.95));
    expect(motion.at(1).flightHeight, 0);
  });

  test('all numeric frame values stay finite', () {
    final motion = motionFor(3);
    for (var step = 0; step <= 100; step++) {
      final frame = motion.at(step / 100);
      final values = [
        frame.rotationX,
        frame.rotationY,
        frame.scaleX,
        frame.scaleY,
        frame.translateY,
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

  test('different random seeds produce varied motion', () {
    final first = DieMotion.random(math.Random(1), dieIndex: 0);
    final second = DieMotion.random(math.Random(2), dieIndex: 0);
    expect(
      first.turnsX != second.turnsX ||
          first.turnsY != second.turnsY ||
          first.landingFaceIndex != second.landingFaceIndex ||
          first.lift != second.lift,
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
