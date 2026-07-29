import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/truth_dare/domain/truth_dare_item.dart';
import 'package:veloura/features/truth_dare/presentation/wheel/wheel_controller.dart';

void main() {
  test('all ten targets land beneath the pointer across every turn count', () {
    for (var turns = 4; turns <= 6; turns++) {
      for (var target = 0; target < WheelMath.segmentCount; target++) {
        final end = WheelMath.endDegrees(target: target, turns: turns);
        expect(WheelMath.targetForEndDegrees(end), target);
      }
    }
  });

  test('segment parity resolves five dares and five truths', () {
    final kinds = [
      for (var target = 0; target < WheelMath.segmentCount; target++)
        WheelMath.kindForTarget(target),
    ];

    expect(kinds.where((kind) => kind == TruthDareKind.dare), hasLength(5));
    expect(kinds.where((kind) => kind == TruthDareKind.truth), hasLength(5));
  });

  test('200 seeded-style target samples always map to matching parity', () {
    for (var sample = 0; sample < 200; sample++) {
      final target = sample % WheelMath.segmentCount;
      final turns = 4 + sample % 3;
      final resolved = WheelMath.targetForEndDegrees(
        WheelMath.endDegrees(target: target, turns: turns),
      );
      expect(WheelMath.kindForTarget(resolved), WheelMath.kindForTarget(target));
    }
  });
}
