import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/features/daily/domain/daily_challenge.dart';
import 'package:veloura/features/daily/domain/daily_repository.dart';
import 'package:veloura/features/daily/domain/daily_selector.dart';

/// SharedPreferences implementation for lightweight daily state.
class PreferencesDailyRepository implements DailyRepository {
  PreferencesDailyRepository(this.preferences);

  final SharedPreferences preferences;

  static const _deviceSeedKey = 'daily_device_seed';
  static const _completedKey = 'daily_completed_dates';
  static const _reminderKey = 'daily_reminder_settings';

  @override
  Future<String> getDeviceSeed() async {
    final existing = preferences.getString(_deviceSeedKey);
    if (existing != null) return existing;
    final seed = '${DateTime.now().microsecondsSinceEpoch}';
    await preferences.setString(_deviceSeedKey, seed);
    return seed;
  }

  @override
  Future<Set<DateTime>> getCompletionDates() async =>
      (preferences.getStringList(_completedKey) ?? const <String>[])
          .map(DateTime.parse)
          .map(dateOnly)
          .toSet();

  @override
  Future<bool> complete(DateTime date) async {
    final dates = await getCompletionDates();
    final added = dates.add(dateOnly(date));
    if (added) {
      final sorted = dates.toList()..sort();
      await preferences.setStringList(
        _completedKey,
        sorted.map(dateKey).toList(growable: false),
      );
    }
    return added;
  }

  @override
  Future<DailyReminderSettings> getReminderSettings() async {
    final raw = preferences.getString(_reminderKey);
    if (raw == null) return const DailyReminderSettings();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return DailyReminderSettings(
      enabled: json['enabled'] as bool? ?? false,
      hour: json['hour'] as int? ?? 20,
      minute: json['minute'] as int? ?? 0,
      title: json['title'] as String? ?? 'A little time for two',
      body: json['body'] as String? ?? 'Your Veloura daily challenge is ready.',
    );
  }

  @override
  Future<void> saveReminderSettings(DailyReminderSettings settings) async {
    await preferences.setString(
      _reminderKey,
      jsonEncode({
        'enabled': settings.enabled,
        'hour': settings.hour,
        'minute': settings.minute,
        'title': settings.title,
        'body': settings.body,
      }),
    );
  }
}
