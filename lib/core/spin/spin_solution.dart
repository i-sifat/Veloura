/// Immutable resolved result for a weighted dial spin.
class SpinSolution {
  const SpinSolution({
    required this.endDegrees,
    required this.target,
    this.isDouble = false,
  });

  final double endDegrees;
  final int target;
  final bool isDouble;
}
