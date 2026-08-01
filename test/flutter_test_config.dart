import 'dart:async';

import 'package:veloura/theme/app_theme.dart';

/// Runs once before every test in this directory (and subdirectories that
/// don't declare their own `flutter_test_config.dart`), per the Flutter
/// test runner's convention.
///
/// `AppTheme.dark` normally builds its text theme via `google_fonts`
/// (Inter), which fetches the font file from the network on first use.
/// `TestWidgetsFlutterBinding` blocks real HTTP requests, so that fetch
/// would throw and fail otherwise-unrelated tests. Overriding
/// `AppTheme.textThemeBuilder` with the identity builder means no test ever
/// calls into `google_fonts` - no network call, no bundled font asset
/// needed, and no production code path is touched (`main.dart` never sets
/// this seam, so the app still renders Inter normally on-device).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppTheme.textThemeBuilder = (base) => base;
  await testMain();
}
