/// Couple details stored locally on this device.
class CoupleProfile {
  const CoupleProfile({
    required this.nameA,
    required this.nameB,
    this.relationshipStart,
  });

  final String nameA;
  final String nameB;
  final DateTime? relationshipStart;

  int togetherDays(DateTime now) => relationshipStart == null
      ? 0
      : now.difference(relationshipStart!).inDays.clamp(0, 1000000);
}

/// Persisted app preferences owned by Profile settings.
class ProfileSettings {
  const ProfileSettings({
    this.haptics = true,
    this.sound = false,
    this.notifications = false,
    this.language = 'English',
  });

  final bool haptics;
  final bool sound;
  final bool notifications;
  final String language;

  ProfileSettings copyWith({
    bool? haptics,
    bool? sound,
    bool? notifications,
    String? language,
  }) => ProfileSettings(
    haptics: haptics ?? this.haptics,
    sound: sound ?? this.sound,
    notifications: notifications ?? this.notifications,
    language: language ?? this.language,
  );
}

/// One read-only entry aggregated from an existing feature store.
class ActivityEntry {
  const ActivityEntry({
    required this.gameId,
    required this.label,
    required this.timestamp,
  });

  final String gameId;
  final String label;
  final DateTime timestamp;
}

/// Rule-based badge; no duplicate progress store is introduced.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final bool unlocked;
}

/// Cross-feature counts computed from repositories at read time.
class ProfileStats {
  const ProfileStats({
    required this.diceRolls,
    required this.truthDareCompleted,
    required this.challengesCompleted,
    required this.conversationsAnswered,
    required this.roleplaysCompleted,
    required this.dailyCompletions,
    required this.favorites,
  });

  final int diceRolls;
  final int truthDareCompleted;
  final int challengesCompleted;
  final int conversationsAnswered;
  final int roleplaysCompleted;
  final int dailyCompletions;
  final int favorites;

  int get totalPlays =>
      diceRolls + truthDareCompleted + challengesCompleted +
      conversationsAnswered + roleplaysCompleted + dailyCompletions;
}

/// Lightweight favorite projection spanning all content repositories.
class FavoriteEntry {
  const FavoriteEntry({required this.source, required this.label});
  final String source;
  final String label;
}
