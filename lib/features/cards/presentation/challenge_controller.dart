import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/cards/data/asset_challenge_repository.dart';
import 'package:veloura/features/cards/domain/challenge_item.dart';
import 'package:veloura/features/cards/domain/challenge_repository.dart';

class ChallengeState {
  const ChallengeState({
    required this.items,
    required this.progress,
    required this.rewards,
    this.category,
  });

  final List<ChallengeItem> items;
  final Map<String, ChallengeProgress> progress;
  final int rewards;
  final ChallengeCategory? category;

  ChallengeState copyWith({
    List<ChallengeItem>? items,
    Map<String, ChallengeProgress>? progress,
    int? rewards,
    ChallengeCategory? Function()? category,
  }) => ChallengeState(
    items: items ?? this.items,
    progress: progress ?? this.progress,
    rewards: rewards ?? this.rewards,
    category: category == null ? this.category : category(),
  );
}

final challengeRepositoryProvider = FutureProvider<ChallengeRepository>(
  (ref) async => AssetChallengeRepository(await SharedPreferences.getInstance()),
);

class ChallengeController extends AsyncNotifier<ChallengeState> {
  late ChallengeRepository _repository;

  @override
  Future<ChallengeState> build() async {
    _repository = await ref.watch(challengeRepositoryProvider.future);
    final result = await _repository.getAll();
    final items = switch (result) {
      AppSuccess<List<ChallengeItem>>(:final value) => value,
      AppFailure<List<ChallengeItem>>(:final message) => throw StateError(message),
    };
    return ChallengeState(
      items: items,
      progress: await _repository.getProgress(),
      rewards: await _repository.getRewardBalance(),
    );
  }

  void selectCategory(ChallengeCategory? category) {
    final current = state.asData?.value;
    if (current != null) state = AsyncData(current.copyWith(category: () => category));
  }

  Future<void> setStatus(
    ChallengeItem item,
    ChallengeStatus status, {
    String? reflection,
  }) async {
    final current = state.asData?.value;
    if (current == null) return;
    final progress = ChallengeProgress(
      status: status,
      reflection: reflection,
      completedAt: status == ChallengeStatus.completed ? DateTime.now() : null,
    );
    await _repository.setProgress(item.id, progress);
    state = AsyncData(current.copyWith(
      progress: {...current.progress, item.id: progress},
      rewards: await _repository.getRewardBalance(),
    ));
  }

  Future<void> toggleFavorite(ChallengeItem item) async {
    final current = state.asData?.value;
    if (current == null) return;
    final result = await _repository.toggleFavorite(item.id);
    if (result case AppSuccess<ChallengeItem>(:final value)) {
      state = AsyncData(current.copyWith(items: [
        for (final candidate in current.items)
          if (candidate.id == value.id) value else candidate,
      ]));
    }
  }
}

final challengeControllerProvider =
    AsyncNotifierProvider<ChallengeController, ChallengeState>(
      ChallengeController.new,
    );
