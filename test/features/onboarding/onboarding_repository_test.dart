import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/features/onboarding/data/onboarding_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new install requires onboarding', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = OnboardingRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.isComplete, isFalse);
  });

  test('legacy configured players bypass onboarding', () async {
    SharedPreferences.setMockInitialValues({
      OnboardingRepository.legacyPlayersKey: true,
    });
    final repository = OnboardingRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.isComplete, isTrue);
  });

  test('completion persists both modern and compatibility flags', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = OnboardingRepository(preferences);

    await repository.complete();

    expect(repository.isComplete, isTrue);
    expect(preferences.getBool(OnboardingRepository.completedKey), isTrue);
    expect(preferences.getBool(OnboardingRepository.legacyPlayersKey), isTrue);
  });
}
