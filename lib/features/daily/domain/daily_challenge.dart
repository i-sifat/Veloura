/// Source module used to compose a daily challenge.
enum DailyChallengeSource { ritual, truthDare, challengeCard, conversation }

/// One normalized prompt that can be selected for a calendar day.
class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.title,
    required this.prompt,
    required this.source,
    this.sourceId,
    this.estimatedMinutes,
  });

  final String id;
  final String title;
  final String prompt;
  final DailyChallengeSource source;
  final String? sourceId;
  final int? estimatedMinutes;
}

/// Persisted local reminder configuration.
class DailyReminderSettings {
  const DailyReminderSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
    this.title = 'A little time for two',
    this.body = 'Your Veloura daily challenge is ready.',
  });

  final bool enabled;
  final int hour;
  final int minute;
  final String title;
  final String body;

  DailyReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    String? title,
    String? body,
  }) => DailyReminderSettings(
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    title: title ?? this.title,
    body: body ?? this.body,
  );
}
