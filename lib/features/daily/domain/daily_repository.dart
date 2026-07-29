import 'package:veloura/features/daily/domain/daily_challenge.dart';

/// Persistence boundary for daily completion, reminder, and device seed data.
abstract interface class DailyRepository {
  Future<String> getDeviceSeed();
  Future<Set<DateTime>> getCompletionDates();
  Future<bool> complete(DateTime date);
  Future<DailyReminderSettings> getReminderSettings();
  Future<void> saveReminderSettings(DailyReminderSettings settings);
}
