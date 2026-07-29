import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/daily/data/daily_notification_service.dart';
import 'package:veloura/features/daily/domain/daily_challenge.dart';

void main() {
  test('permission denial is returned without throwing', () async {
    const service = NoopDailyNotificationService(permissionGranted: false);

    expect(await service.requestPermission(), isFalse);
    await expectLater(service.cancel(), completes);
  });

  test('past reminder time schedules seven unique consecutive days', () {
    const settings = DailyReminderSettings(
      enabled: true,
      hour: 20,
      minute: 0,
    );

    final occurrences = nextReminderOccurrences(
      settings: settings,
      now: DateTime(2026, 7, 30, 21),
    );

    expect(occurrences, hasLength(7));
    expect(occurrences.toSet(), hasLength(7));
    expect(occurrences.first, DateTime(2026, 7, 31, 20));
    expect(occurrences.last, DateTime(2026, 8, 6, 20));
  });

  test('future reminder time includes today exactly once', () {
    const settings = DailyReminderSettings(
      enabled: true,
      hour: 20,
      minute: 0,
    );

    final occurrences = nextReminderOccurrences(
      settings: settings,
      now: DateTime(2026, 7, 30, 19),
      count: 2,
    );

    expect(occurrences, [
      DateTime(2026, 7, 30, 20),
      DateTime(2026, 7, 31, 20),
    ]);
  });
}
