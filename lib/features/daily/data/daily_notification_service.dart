import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:veloura/features/daily/domain/daily_challenge.dart';

/// Platform notification boundary so denial and tests never affect Daily logic.
abstract interface class DailyNotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> schedule(DailyReminderSettings settings);
  Future<void> cancel();
}

/// Local notification implementation. It schedules the next seven local
/// occurrences and refreshes them whenever the app opens or settings change.
class PluginDailyNotificationService implements DailyNotificationService {
  PluginDailyNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _firstNotificationId = 5100;
  static const _daysScheduled = 7;
  final FlutterLocalNotificationsPlugin _plugin;
  var _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? true;
  }

  @override
  Future<void> schedule(DailyReminderSettings settings) async {
    await initialize();
    await cancel();
    if (!settings.enabled) return;
    final now = DateTime.now();
    for (var offset = 0; offset < _daysScheduled; offset++) {
      var local = DateTime(
        now.year,
        now.month,
        now.day + offset,
        settings.hour,
        settings.minute,
      );
      if (!local.isAfter(now)) local = local.add(const Duration(days: 1));
      final instant = tz.TZDateTime.from(local.toUtc(), tz.UTC);
      await _plugin.zonedSchedule(
        _firstNotificationId + offset,
        settings.title,
        settings.body,
        instant,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_connection',
            'Daily connection reminder',
            channelDescription: 'A configurable reminder for today’s challenge.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancel() async {
    await initialize();
    for (var offset = 0; offset < _daysScheduled; offset++) {
      await _plugin.cancel(_firstNotificationId + offset);
    }
  }
}

/// Safe test/fallback implementation.
class NoopDailyNotificationService implements DailyNotificationService {
  const NoopDailyNotificationService({this.permissionGranted = true});

  final bool permissionGranted;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> schedule(DailyReminderSettings settings) async {}
}
