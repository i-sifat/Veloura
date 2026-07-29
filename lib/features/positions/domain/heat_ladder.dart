/// Session heat rises every two rounds and respects entitlement caps.
int heatFor(
  int completedRounds, {
  required bool premium,
  required bool softened,
}) {
  final raw = 1 + completedRounds ~/ 2;
  final cap = softened ? 2 : (premium ? 5 : 3);
  return raw.clamp(1, cap);
}
