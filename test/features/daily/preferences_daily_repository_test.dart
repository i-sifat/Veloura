import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/features/daily/data/preferences_daily_repository.dart';
import 'package:veloura/features/daily/domain/daily_challenge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('completion is idempotent and survives repository recreation', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesDailyRepository(preferences);
    final date = DateTime(2026, 7, 30, 22);

    expect(await repository.complete(date), isTrue);
    expect(await repository.complete(date), isFalse);

    final restored = PreferencesDailyRepository(preferences);
    expect(await restored.getCompletionDates(), {DateTime(2026, 7, 30)});
  });

  test('reminder settings persist configurable time and copy', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesDailyRepository(preferences);
    const settings = DailyReminderSettings(
      enabled: true,
      hour: 18,
      minute: 45,
      title: 'Our time',
      body: 'A prompt is waiting.',
    );

    await repository.saveReminderSettings(settings);
    final restored = await repository.getReminderSettings();

    expect(restored.enabled, isTrue);
    expect(restored.hour, 18);
    expect(restored.minute, 45);
    expect(restored.title, 'Our time');
    expect(restored.body, 'A prompt is waiting.');
  });
}
