import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/cards/domain/challenge_item.dart';
import 'package:veloura/features/cards/presentation/challenge_controller.dart';
import 'package:veloura/features/conversation/domain/conversation_item.dart';
import 'package:veloura/features/conversation/presentation/conversation_controller.dart';
import 'package:veloura/features/daily/data/daily_notification_service.dart';
import 'package:veloura/features/daily/data/preferences_daily_repository.dart';
import 'package:veloura/features/daily/data/ritual_prompts.dart';
import 'package:veloura/features/daily/domain/daily_challenge.dart';
import 'package:veloura/features/daily/domain/daily_repository.dart';
import 'package:veloura/features/daily/domain/daily_selector.dart';
import 'package:veloura/features/daily/domain/streak_calculator.dart';
import 'package:veloura/features/truth_dare/domain/truth_dare_item.dart';
import 'package:veloura/features/truth_dare/presentation/truth_dare_controller.dart';
import 'package:veloura/models/difficulty.dart';
import 'package:veloura/services/reward_currency_service.dart';

class DailyState {
  const DailyState({
    required this.challenge,
    required this.completionDates,
    required this.streak,
    required this.rewardBalance,
    required this.reminder,
    required this.displayedMonth,
  });

  final DailyChallenge challenge;
  final Set<DateTime> completionDates;
  final int streak;
  final int rewardBalance;
  final DailyReminderSettings reminder;
  final DateTime displayedMonth;

  bool get completedToday => completionDates.contains(dateOnly(DateTime.now()));

  DailyState copyWith({
    Set<DateTime>? completionDates,
    int? streak,
    int? rewardBalance,
    DailyReminderSettings? reminder,
    DateTime? displayedMonth,
  }) => DailyState(
    challenge: challenge,
    completionDates: completionDates ?? this.completionDates,
    streak: streak ?? this.streak,
    rewardBalance: rewardBalance ?? this.rewardBalance,
    reminder: reminder ?? this.reminder,
    displayedMonth: displayedMonth ?? this.displayedMonth,
  );
}

final dailyRepositoryProvider = FutureProvider<DailyRepository>(
  (ref) async => PreferencesDailyRepository(
    await SharedPreferences.getInstance(),
  ),
);

final rewardCurrencyServiceProvider = FutureProvider<RewardCurrencyService>(
  (ref) async => PreferencesRewardCurrencyService(
    await SharedPreferences.getInstance(),
  ),
);

final dailyNotificationServiceProvider = Provider<DailyNotificationService>(
  (ref) => PluginDailyNotificationService(),
);

final dailyNowProvider = Provider<DateTime>((ref) => DateTime.now());

class DailyController extends AsyncNotifier<DailyState> {
  static const completionReward = 10;

  late DailyRepository _repository;
  late RewardCurrencyService _rewards;
  late DailyNotificationService _notifications;

  @override
  Future<DailyState> build() async {
    _repository = await ref.watch(dailyRepositoryProvider.future);
    _rewards = await ref.watch(rewardCurrencyServiceProvider.future);
    _notifications = ref.read(dailyNotificationServiceProvider);

    final pool = await _composePool();
    final now = ref.read(dailyNowProvider);
    final challenge = const DailySelector().select(
      pool: pool,
      deviceSeed: await _repository.getDeviceSeed(),
      date: now,
    );
    final dates = await _repository.getCompletionDates();
    final reminder = await _repository.getReminderSettings();
    await _notifications.initialize();
    if (reminder.enabled) await _notifications.schedule(reminder);

    return DailyState(
      challenge: challenge,
      completionDates: dates,
      streak: const StreakCalculator().calculate(
        completions: dates,
        today: now,
      ),
      rewardBalance: await _rewards.balance(),
      reminder: reminder,
      displayedMonth: DateTime(now.year, now.month),
    );
  }

  Future<List<DailyChallenge>> _composePool() async {
    final truthRepository = await ref.watch(truthDareRepositoryProvider.future);
    final cardRepository = await ref.watch(challengeRepositoryProvider.future);
    final conversationRepository = await ref.watch(
      conversationRepositoryProvider.future,
    );
    final truth = await truthRepository.getAll();
    final cards = await cardRepository.getAll();
    final conversation = await conversationRepository.getAll();

    return [
      ...dailyRitualPrompts,
      ...switch (truth) {
        AppSuccess<List<TruthDareItem>>(:final value) => value
            .where((item) => item.difficulty != Difficulty.extreme)
            .map(
              (item) => DailyChallenge(
                id: 'truth_dare_${item.id}',
                title: item.kind == TruthDareKind.truth
                    ? 'Today’s truth'
                    : 'Today’s dare',
                prompt: item.prompt,
                source: DailyChallengeSource.truthDare,
                sourceId: item.id,
                estimatedMinutes: 5,
              ),
            ),
        AppFailure<List<TruthDareItem>>() => const <DailyChallenge>[],
      },
      ...switch (cards) {
        AppSuccess<List<ChallengeItem>>(:final value) => value
            .where((item) => !item.premium)
            .map(
              (item) => DailyChallenge(
                id: 'card_${item.id}',
                title: item.title,
                prompt: item.description,
                source: DailyChallengeSource.challengeCard,
                sourceId: item.id,
                estimatedMinutes: item.estimatedMinutes,
              ),
            ),
        AppFailure<List<ChallengeItem>>() => const <DailyChallenge>[],
      },
      ...switch (conversation) {
        AppSuccess<List<ConversationItem>>(:final value) => value.map(
          (item) => DailyChallenge(
            id: 'conversation_${item.id}',
            title: 'Talk about this',
            prompt: item.prompt,
            source: DailyChallengeSource.conversation,
            sourceId: item.id,
            estimatedMinutes: 8,
          ),
        ),
        AppFailure<List<ConversationItem>>() => const <DailyChallenge>[],
      },
    ];
  }

  Future<void> completeToday() async {
    final current = state.asData?.value;
    if (current == null || current.completedToday) return;
    final now = ref.read(dailyNowProvider);
    final newlyCompleted = await _repository.complete(now);
    final dates = await _repository.getCompletionDates();
    final balance = newlyCompleted
        ? await _rewards.award(completionReward)
        : await _rewards.balance();
    state = AsyncData(
      current.copyWith(
        completionDates: dates,
        streak: const StreakCalculator().calculate(
          completions: dates,
          today: now,
        ),
        rewardBalance: balance,
      ),
    );
  }

  void changeMonth(int delta) {
    final current = state.asData?.value;
    if (current == null) return;
    final month = current.displayedMonth;
    state = AsyncData(
      current.copyWith(
        displayedMonth: DateTime(month.year, month.month + delta),
      ),
    );
  }

  Future<bool> updateReminder(DailyReminderSettings settings) async {
    final current = state.asData?.value;
    if (current == null) return false;
    if (!settings.enabled) {
      await _notifications.cancel();
      await _repository.saveReminderSettings(settings);
      state = AsyncData(current.copyWith(reminder: settings));
      return true;
    }
    final granted = await _notifications.requestPermission();
    if (!granted) return false;
    await _repository.saveReminderSettings(settings);
    await _notifications.schedule(settings);
    state = AsyncData(current.copyWith(reminder: settings));
    return true;
  }
}

final dailyControllerProvider = AsyncNotifierProvider<DailyController, DailyState>(
  DailyController.new,
);
