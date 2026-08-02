import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/positions/presentation/positions_controller.dart';

void main() {
  for (final zoneCount in [5, 6]) {
    group('zoneCount = $zoneCount', () {
      test('every target lands beneath the pointer at typical turn counts', () {
        for (var turns = 3; turns <= 5; turns++) {
          for (var target = 0; target < zoneCount; target++) {
            final end = PositionWheelMath.endDegrees(
              target: target,
              turns: turns,
              zoneCount: zoneCount,
            );
            expect(PositionWheelMath.targetForEndDegrees(end, zoneCount), target);
          }
        }
      });

      test('nextEndDegrees always advances strictly forward from the current angle', () {
        var current = 0.0;
        for (var spin = 0; spin < 200; spin++) {
          final target = spin % zoneCount;
          final end = PositionWheelMath.nextEndDegrees(
            currentDegrees: current,
            target: target,
            turns: 3,
            zoneCount: zoneCount,
          );
          expect(end, greaterThan(current));
          expect(PositionWheelMath.targetForEndDegrees(end, zoneCount), target);
          current = end;
        }
      });

      test('repeated spins to the same target never stall the wheel', () {
        // Regression test: the previous SpinSolver-based implementation
        // computed each landing angle from zero, so a second spin could
        // land at or behind the wheel's current position and the wheel
        // appeared frozen or jumped backward. nextEndDegrees must always
        // move forward by at least one full turn.
        var current = 100.0;
        for (var repeat = 0; repeat < 5; repeat++) {
          final end = PositionWheelMath.nextEndDegrees(
            currentDegrees: current,
            target: 0,
            turns: 3,
            zoneCount: zoneCount,
          );
          expect(end - current, greaterThanOrEqualTo(3 * 360));
          current = end;
        }
      });
    });
  }
}
