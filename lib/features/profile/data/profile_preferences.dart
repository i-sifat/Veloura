import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/features/profile/domain/profile_models.dart';

/// Lightweight profile/settings persistence.
class ProfilePreferences {
  ProfilePreferences(this.preferences);

  final SharedPreferences preferences;

  CoupleProfile loadProfile({required String nameA, required String nameB}) {
    final start = preferences.getString('profile_relationship_start');
    return CoupleProfile(
      nameA: preferences.getString('profile_name_a') ?? nameA,
      nameB: preferences.getString('profile_name_b') ?? nameB,
      relationshipStart: start == null ? null : DateTime.tryParse(start),
    );
  }

  Future<void> saveProfile(CoupleProfile value) async {
    await preferences.setString('profile_name_a', value.nameA);
    await preferences.setString('profile_name_b', value.nameB);
    if (value.relationshipStart case final start?) {
      await preferences.setString(
        'profile_relationship_start',
        start.toIso8601String(),
      );
    }
  }

  ProfileSettings loadSettings() => ProfileSettings(
    haptics: preferences.getBool('game_vibration') ?? true,
    sound: preferences.getBool('game_sound') ?? false,
    notifications: preferences.getBool('profile_notifications') ?? false,
    language: preferences.getString('profile_language') ?? 'English',
  );

  Future<void> saveSettings(ProfileSettings value) async {
    await preferences.setBool('game_vibration', value.haptics);
    await preferences.setBool('game_sound', value.sound);
    await preferences.setBool('profile_notifications', value.notifications);
    await preferences.setString('profile_language', value.language);
  }
}
