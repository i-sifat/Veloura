import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/cards/domain/challenge_item.dart';
import 'package:veloura/features/cards/domain/challenge_repository.dart';
import 'package:veloura/features/cards/domain/intensity_deck.dart';
import 'package:veloura/features/cards/presentation/challenge_controller.dart';
import 'package:veloura/features/premium/provider.dart';

/// Injectable shuffle source for deterministic deal tests.
final cardDealRandomProvider = Provider<Random>((ref) => Random());

/// Current mystery-card round for one intensity and optional category.
class CardFanState {
  const CardFanState({
    required this.pool,
    required this.progress,
    this.deck = IntensityDeck.romantic,
    this.category,
    this.selected,
    this.selectedNumber,
    this.dealNumber = 0,
  });

  final List<ChallengeItem> pool;
  final Map<String, ChallengeProgress> progress;
  final IntensityDeck deck;
  final ChallengeCategory? category;
  final ChallengeItem? selected;
  final int? selectedNumber;
  final int dealNumber;

  CardFanState copyWith({
    List<ChallengeItem>? pool,
    Map<String, ChallengeProgress>? progress,
    IntensityDeck? deck,
    ChallengeCategory? Function()? category,
    ChallengeItem? Function()? selected,
    int? Function()? selectedNumber,
    int? dealNumber,
  }) => CardFanState(
    pool: pool ?? this.pool,
    progress: progress ?? this.progress,
    deck: deck ?? this.deck,
    category: category == null ? this.category : category(),
    selected: selected == null ? this.selected : selected(),
    selectedNumber: selectedNumber == null
        ? this.selectedNumber
        : selectedNumber(),
    dealNumber: dealNumber ?? this.dealNumber,
  );
}

/// Resolves one of twelve identical mystery backs without session repeats.
class CardFanController extends AsyncNotifier<CardFanState> {
  late ChallengeRepository _repository;
  late Random _random;
  List<ChallengeItem> _all = const [];
  final Map<IntensityDeck, Set<String>> _usedIds = {
    for (final deck in IntensityDeck.values) deck: <String>{},
  };

  @override
  Future<CardFanState> build() async {
    _repository = await ref.watch(challengeRepositoryProvider.future);
    _random = ref.watch(cardDealRandomProvider);
    final result = await _repository.getAll();
    _all = switch (result) {
      AppSuccess<List<ChallengeItem>>(:final value) => value,
      AppFailure<List<ChallengeItem>>(:final message) => throw StateError(message),
    };
    final initial = CardFanState(
      pool: const [],
      progress: await _repository.getProgress(),
    );
    return _deal(initial);
  }

  /// Selects a heat level and immediately refreshes the hidden pool.
  void selectDeck(IntensityDeck deck) {
    final current = state.asData?.value;
    if (current != null) state = AsyncData(_deal(current.copyWith(deck: deck)));
  }

  /// Applies an optional category filter without putting eight tabs on screen.
  void selectCategory(ChallengeCategory? category) {
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(_deal(current.copyWith(category: () => category)));
    }
  }

  /// Resolves a numbered back to one random unused challenge.
  void pickNumber(int number) {
    assert(number >= 1 && number <= 12);
    final current = state.asData?.value;
    if (current == null || current.pool.isEmpty) return;
    final item = current.pool[_random.nextInt(current.pool.length)];
    _usedIds[current.deck]!.add(item.id);
    state = AsyncData(
      current.copyWith(
        selected: () => item,
        selectedNumber: () => number,
      ),
    );
  }

  /// Clears the reveal and refreshes the eligible pool.
  void redeal() {
    final current = state.asData?.value;
    if (current != null) state = AsyncData(_deal(current));
  }

  /// Completes through the existing progress/reward repository flow.
  Future<void> completeSelected({String? reflection}) async {
    final current = state.asData?.value;
    final item = current?.selected;
    if (current == null || item == null) return;
    final progress = ChallengeProgress(
      status: ChallengeStatus.completed,
      reflection: reflection,
      completedAt: DateTime.now(),
    );
    await _repository.setProgress(item.id, progress);
    state = AsyncData(
      _deal(
        current.copyWith(
          progress: {...current.progress, item.id: progress},
        ),
      ),
    );
  }

  /// Uses the existing favorite persistence API.
  Future<void> toggleFavorite() async {
    final current = state.asData?.value;
    final item = current?.selected;
    if (current == null || item == null) return;
    final result = await _repository.toggleFavorite(item.id);
    if (result case AppSuccess<ChallengeItem>(:final value)) {
      _all = [
        for (final candidate in _all)
          if (candidate.id == value.id) value else candidate,
      ];
      state = AsyncData(current.copyWith(selected: () => value));
    }
  }

  CardFanState _deal(CardFanState current) {
    final premium = ref.read(isPremiumProvider);
    final used = _usedIds[current.deck]!;
    var pool = _eligible(current, premium)
        .where((item) => !used.contains(item.id))
        .toList();
    if (pool.isEmpty) {
      used.clear();
      pool = _eligible(current, premium);
    }
    pool.shuffle(_random);
    return current.copyWith(
      pool: pool,
      selected: () => null,
      selectedNumber: () => null,
      dealNumber: current.dealNumber + 1,
    );
  }

  List<ChallengeItem> _eligible(CardFanState state, bool premium) => _all
      .where(state.deck.accepts)
      .where(
        (item) =>
            state.category == null || item.challengeCategory == state.category,
      )
      .where(
        (item) =>
            state.progress[item.id]?.status != ChallengeStatus.completed,
      )
      .where(
        (item) =>
            state.deck == IntensityDeck.superhot || premium || !item.premium,
      )
      .toList();
}

final cardFanControllerProvider =
    AsyncNotifierProvider<CardFanController, CardFanState>(
      CardFanController.new,
    );
