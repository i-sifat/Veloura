import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/features/profile/data/profile_preferences.dart';
import 'package:veloura/features/profile/domain/profile_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('profile and settings survive repository recreation', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = ProfilePreferences(preferences);
    final profile = CoupleProfile(
      nameA: 'River',
      nameB: 'Sage',
      relationshipStart: DateTime(2020, 5, 4),
    );
    const settings = ProfileSettings(
      haptics: false,
      sound: true,
      notifications: true,
      language: 'English',
    );

    await repository.saveProfile(profile);
    await repository.saveSettings(settings);
    final restored = ProfilePreferences(preferences);

    expect(restored.loadProfile(nameA: 'A', nameB: 'B').nameA, 'River');
    expect(
      restored.loadProfile(nameA: 'A', nameB: 'B').relationshipStart,
      DateTime(2020, 5, 4),
    );
    expect(restored.loadSettings().haptics, isFalse);
    expect(restored.loadSettings().sound, isTrue);
    expect(restored.loadSettings().notifications, isTrue);
  });
}
