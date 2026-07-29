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

/// Twelve-card deal shown for one intensity and optional category.
class CardFanState {
  const CardFanState({
    required this.cards,
    required this.progress,
    this.deck = IntensityDeck.romantic,
    this.category,
    this.selected,
    this.dealNumber = 0,
  });

  final List<ChallengeItem> cards;
  final Map<String, ChallengeProgress> progress;
  final IntensityDeck deck;
  final ChallengeCategory? category;
  final ChallengeItem? selected;
  final int dealNumber;

  bool get premiumLocked => deck == IntensityDeck.superhot;

  CardFanState copyWith({
    List<ChallengeItem>? cards,
    Map<String, ChallengeProgress>? progress,
    IntensityDeck? deck,
    ChallengeCategory? Function()? category,
    ChallengeItem? Function()? selected,
    int? dealNumber,
  }) => CardFanState(
    cards: cards ?? this.cards,
    progress: progress ?? this.progress,
    deck: deck ?? this.deck,
    category: category == null ? this.category : category(),
    selected: selected == null ? this.selected : selected(),
    dealNumber: dealNumber ?? this.dealNumber,
  );
}

/// Deals numbered mystery cards without repeating within a session.
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
      cards: const [],
      progress: await _repository.getProgress(),
    );
    return _deal(initial);
  }

  /// Selects a heat level and immediately deals a fresh set.
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

  /// Stores the chosen numbered card for the reveal surface.
  void pick(ChallengeItem item) {
    final current = state.asData?.value;
    if (current != null) state = AsyncData(current.copyWith(selected: () => item));
  }

  /// Re-deals twelve backs from the current deck and category.
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
          selected: () => null,
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
      state = AsyncData(
        current.copyWith(
          cards: [
            for (final candidate in current.cards)
              if (candidate.id == value.id) value else candidate,
          ],
          selected: () => value,
        ),
      );
    }
  }

  CardFanState _deal(CardFanState current) {
    final premium = ref.read(isPremiumProvider);
    final used = _usedIds[current.deck]!;
    var pool = _eligible(current, premium).where((item) => !used.contains(item.id)).toList();
    if (pool.isEmpty) {
      used.clear();
      pool = _eligible(current, premium);
    }
    pool.shuffle(_random);
    final cards = pool.take(12).toList(growable: false);
    used.addAll(cards.map((item) => item.id));
    return current.copyWith(
      cards: cards,
      selected: () => null,
      dealNumber: current.dealNumber + 1,
    );
  }

  List<ChallengeItem> _eligible(CardFanState state, bool premium) => _all
      .where(state.deck.accepts)
      .where(
        (item) => state.category == null || item.challengeCategory == state.category,
      )
      .where(
        (item) => state.progress[item.id]?.status != ChallengeStatus.completed,
      )
      .where((item) => state.deck == IntensityDeck.superhot || premium || !item.premium)
      .toList();
}

final cardFanControllerProvider =
    AsyncNotifierProvider<CardFanController, CardFanState>(CardFanController.new);
