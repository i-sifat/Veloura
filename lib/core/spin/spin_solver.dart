import 'dart:math';

import 'package:veloura/core/spin/spin_solution.dart';

/// Pure uniform landing solver shared by dial-based games.
abstract final class SpinSolver {
  /// Flick strength controls the journey; randomness controls the destination.
  static SpinSolution solve({
    required Random random,
    required int zoneCount,
    required int turns,
    required int direction,
    double seamChance = 0,
  }) {
    assert(zoneCount > 1);
    assert(turns > 0);
    assert(direction == -1 || direction == 1);
    final sweep = 360 / zoneCount;
    final isDouble = seamChance > 0 && random.nextDouble() < seamChance;
    final target = random.nextInt(zoneCount);
    final offset = isDouble ? sweep / 2 : 0.0;
    return SpinSolution(
      endDegrees: direction * turns * 360 + target * sweep + offset,
      target: target,
      isDouble: isDouble,
    );
  }

  static int zoneForDegrees(double degrees, int zoneCount) {
    final sweep = 360 / zoneCount;
    final normalized = ((degrees % 360) + 360) % 360;
    return (normalized / sweep).round() % zoneCount;
  }
}
