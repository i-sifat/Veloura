/// Analytics boundary. The Firebase implementation is introduced in Phase 8.
abstract interface class AnalyticsService {
  /// Records an event without exposing an SDK to feature code.
  Future<void> track(String name, {Map<String, Object?> properties = const {}});
}

/// No-op analytics used until Phase 8.
final class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();

  @override
  Future<void> track(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {}
}
