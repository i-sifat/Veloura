import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/cards/presentation/challenge_controller.dart';
import 'package:veloura/features/conversation/presentation/conversation_controller.dart';
import 'package:veloura/features/daily/presentation/daily_controller.dart';
import 'package:veloura/features/dice/domain/dice_roll_record.dart';
import 'package:veloura/features/dice/presentation/dice_controller.dart';
import 'package:veloura/features/profile/data/profile_preferences.dart';
import 'package:veloura/features/profile/domain/achievement_rules.dart';
import 'package:veloura/features/profile/domain/profile_models.dart';
import 'package:veloura/features/roleplay/presentation/roleplay_controller.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/features/truth_dare/presentation/truth_dare_controller.dart';

class ProfileState {
  const ProfileState({
    required this.profile,
    required this.settings,
    required this.stats,
    required this.achievements,
    required this.activity,
    required this.favorites,
  });

  final CoupleProfile profile;
  final ProfileSettings settings;
  final ProfileStats stats;
  final List<Achievement> achievements;
  final List<ActivityEntry> activity;
  final List<FavoriteEntry> favorites;

  ProfileState copyWith({
    CoupleProfile? profile,
    ProfileSettings? settings,
  }) => ProfileState(
    profile: profile ?? this.profile,
    settings: settings ?? this.settings,
    stats: stats,
    achievements: achievements,
    activity: activity,
    favorites: favorites,
  );
}

class ProfileController extends AsyncNotifier<ProfileState> {
  late ProfilePreferences _preferences;

  @override
  Future<ProfileState> build() async {
    _preferences = ProfilePreferences(await SharedPreferences.getInstance());
    final session = await ref.watch(sessionControllerProvider.future);
    final diceRepository = await ref.watch(diceRepositoryProvider.future);
    final truthRepository = await ref.watch(truthDareRepositoryProvider.future);
    final cardsRepository = await ref.watch(challengeRepositoryProvider.future);
    final conversationRepository = await ref.watch(conversationRepositoryProvider.future);
    final roleplayRepository = await ref.watch(roleplayRepositoryProvider.future);
    final dailyRepository = await ref.watch(dailyRepositoryProvider.future);

    final diceResult = await diceRepository.getHistory();
    final dice = switch (diceResult) {
      AppSuccess<List<DiceRollRecord>>(:final value) => value,
      _ => <DiceRollRecord>[],
    };
    final truthAll = await truthRepository.getAll();
    final cardAll = await cardsRepository.getAll();
    final conversationAll = await conversationRepository.getAll();
    final roleplayAll = await roleplayRepository.getAll();
    final truthCompleted = await truthRepository.getCompletedIds();
    final cardProgress = await cardsRepository.getProgress();
    final answered = await conversationRepository.getAnswered();
    final daily = await dailyRepository.getCompletionDates();
    final rawRoleplays = (await SharedPreferences.getInstance())
            .getStringList(RoleplayController.completedPlaysKey) ??
        <String>[];

    final favorites = <FavoriteEntry>[
      for (final record in dice.where((item) => item.favorite))
        FavoriteEntry(source: 'Dice', label: record.summary),
      ..._favoritesFromResult('Truth or Dare', truthAll, (item) => item.favorite, (item) => item.prompt),
      ..._favoritesFromResult('Challenges', cardAll, (item) => item.favorite, (item) => item.title),
      ..._favoritesFromResult('Conversation', conversationAll, (item) => item.favorite, (item) => item.prompt),
      ..._favoritesFromResult('Roleplay', roleplayAll, (item) => item.favorite, (item) => item.title),
    ];

    final completedCards = cardProgress.values
        .where((value) => value.completedAt != null)
        .toList();
    final stats = ProfileStats(
      diceRolls: dice.length,
      truthDareCompleted: truthCompleted.length,
      challengesCompleted: completedCards.length,
      conversationsAnswered: answered.length,
      roleplaysCompleted: rawRoleplays.length,
      dailyCompletions: daily.length,
      favorites: favorites.length,
    );
    final activity = <ActivityEntry>[
      for (final record in dice)
        ActivityEntry(
          gameId: 'dice',
          label: record.summary,
          timestamp: record.createdAt,
        ),
      for (final value in cardProgress.entries)
        if (value.value.completedAt case final timestamp?)
          ActivityEntry(
            gameId: 'cards',
            label: 'Completed challenge ${value.key}',
            timestamp: timestamp,
          ),
      for (final value in answered.entries)
        ActivityEntry(
          gameId: 'conversation',
          label: 'Answered a conversation prompt',
          timestamp: value.value,
        ),
      for (final raw in rawRoleplays)
        if (_roleplayActivity(raw) case final item?) item,
      for (final date in daily)
        ActivityEntry(
          gameId: 'daily',
          label: 'Completed the daily connection',
          timestamp: date,
        ),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ProfileState(
      profile: _preferences.loadProfile(
        nameA: session.a.name,
        nameB: session.b.name,
      ),
      settings: _preferences.loadSettings(),
      stats: stats,
      achievements: evaluateAchievements(stats),
      activity: activity,
      favorites: favorites,
    );
  }

  List<FavoriteEntry> _favoritesFromResult<T>(
    String source,
    AppResult<List<T>> result,
    bool Function(T) favorite,
    String Function(T) label,
  ) => switch (result) {
    AppSuccess<List<T>>(:final value) => [
      for (final item in value.where(favorite))
        FavoriteEntry(source: source, label: label(item)),
    ],
    _ => const [],
  };

  ActivityEntry? _roleplayActivity(String raw) {
    final parts = raw.split('|');
    if (parts.length != 2) return null;
    final timestamp = DateTime.tryParse(parts[1]);
    if (timestamp == null) return null;
    return ActivityEntry(
      gameId: 'roleplay',
      label: 'Finished roleplay scene ${parts[0]}',
      timestamp: timestamp.toLocal(),
    );
  }

  Future<void> updateProfile(CoupleProfile value) async {
    await _preferences.saveProfile(value);
    final current = state.asData?.value;
    if (current != null) state = AsyncData(current.copyWith(profile: value));
  }

  Future<void> updateSettings(ProfileSettings value) async {
    await _preferences.saveSettings(value);
    final current = state.asData?.value;
    if (current != null) state = AsyncData(current.copyWith(settings: value));
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileState>(
      ProfileController.new,
    );
