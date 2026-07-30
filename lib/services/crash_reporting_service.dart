import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class CrashReportingService {
  Future<void> record(Object error, StackTrace stack, {bool fatal = false});
}

final class NoOpCrashReportingService implements CrashReportingService {
  const NoOpCrashReportingService();
  @override
  Future<void> record(Object error, StackTrace stack, {bool fatal = false}) async {}
}

final class FirebaseCrashReportingService implements CrashReportingService {
  FirebaseCrashReportingService(this.crashlytics);
  final FirebaseCrashlytics crashlytics;

  @override
  Future<void> record(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) => crashlytics.recordError(error, stack, fatal: fatal);
}

final crashReportingServiceProvider = Provider<CrashReportingService>(
  (ref) => const NoOpCrashReportingService(),
);
