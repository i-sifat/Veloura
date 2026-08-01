import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Runs once before every test in this directory (and subdirectories that
/// don't declare their own `flutter_test_config.dart`), per the Flutter
/// test runner's convention.
///
/// `AppTheme.dark` loads Inter via `google_fonts`, which normally fetches
/// the font file from the network on first use. `TestWidgetsFlutterBinding`
/// blocks real HTTP requests, so that fetch throws and fails otherwise
/// unrelated tests. Disabling runtime fetching here makes every test fall
/// back to the bundled default font instead - no test should depend on a
/// live network call to fonts.gstatic.com.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
