import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:veloura/services/analytics_service.dart';
import 'package:veloura/services/crash_reporting_service.dart';

/// Result of optional Firebase initialization.
class FirebaseServices {
  const FirebaseServices({
    required this.analytics,
    required this.crashReporting,
    required this.configured,
  });

  final AnalyticsService analytics;
  final CrashReportingService crashReporting;
  final bool configured;
}

/// Initializes Firebase when platform configuration is present. Missing
/// google-services files/options leave the app fully functional and local-only.
Future<FirebaseServices> initializeFirebaseSafely() async {
  try {
    await Firebase.initializeApp();
    final analytics = FirebaseAnalyticsService(FirebaseAnalytics.instance);
    final crash = FirebaseCrashReportingService(FirebaseCrashlytics.instance);
    if (!kIsWeb) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
    return FirebaseServices(
      analytics: analytics,
      crashReporting: crash,
      configured: true,
    );
  } on Object {
    return const FirebaseServices(
      analytics: NoOpAnalyticsService(),
      crashReporting: NoOpCrashReportingService(),
      configured: false,
    );
  }
}
