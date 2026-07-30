import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class AnalyticsService {
  Future<void> track(String name, {Map<String, Object?> properties = const {}});
}

final class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();
  @override
  Future<void> track(String name, {Map<String, Object?> properties = const {}}) async {}
}

final class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this.analytics);
  final FirebaseAnalytics analytics;

  @override
  Future<void> track(
    String name, {
    Map<String, Object?> properties = const {},
  }) => analytics.logEvent(
    name: name,
    parameters: {
      for (final entry in properties.entries)
        if (entry.value case final value?) entry.key: value,
    },
  );
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => const NoOpAnalyticsService(),
);
