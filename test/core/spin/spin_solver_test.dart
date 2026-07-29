import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/core/spin/spin_solver.dart';

void main() {
  test('resolved angles map back to intended targets', () {
    for (final zones in [5, 6, 8]) {
      final random = Random(42);
      for (var index = 0; index < 500; index++) {
        final solution = SpinSolver.solve(
          random: random,
          zoneCount: zones,
          turns: 2 + index % 5,
          direction: index.isEven ? 1 : -1,
        );
        expect(
          SpinSolver.zoneForDegrees(solution.endDegrees, zones),
          solution.target,
        );
      }
    }
  });
}
