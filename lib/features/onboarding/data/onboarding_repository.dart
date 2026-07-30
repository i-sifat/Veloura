import 'package:shared_preferences/shared_preferences.dart';

/// Persists only the lightweight first-launch completion flag.
class OnboardingRepository {
  OnboardingRepository(this.preferences);

  static const completedKey = 'onboarding_seen';
  static const legacyPlayersKey = 'session_players_configured';

  final SharedPreferences preferences;

  /// Existing installs that already configured players are treated as complete.
  bool get isComplete =>
      preferences.getBool(completedKey) ??
      (preferences.getBool(legacyPlayersKey) ?? false);

  Future<void> complete() async {
    await preferences.setBool(completedKey, true);
    await preferences.setBool(legacyPlayersKey, true);
  }
}
