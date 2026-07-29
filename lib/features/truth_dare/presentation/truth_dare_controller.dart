import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/truth_dare/data/asset_truth_dare_repository.dart';
import 'package:veloura/features/truth_dare/domain/truth_dare_item.dart';
import 'package:veloura/features/truth_dare/domain/truth_dare_repository.dart';
import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/difficulty.dart';

/// Active Truth or Dare session state.
class TruthDareState {
  const TruthDareState({
    required this.deck,
    required this.index,
    required this.completed,
    this.kind,
    this.difficulty,
    this.category,
    this.shuffle = true,
  });

  final List<TruthDareItem> deck;
  final int index;
  final int completed;
  final TruthDareKind? kind;
  final Difficulty? difficulty;
  final ContentCategory? category;
  final bool shuffle;

  TruthDareItem? get current => deck.isEmpty ? null : deck[index % deck.length];

  TruthDareState copyWith({
    List<TruthDareItem>? deck,
    int? index,
    int? completed,
    TruthDareKind? Function()? kind,
    Difficulty? Function()? difficulty,
    ContentCategory? Function()? category,
    bool? shuffle,
  }) => TruthDareState(
    deck: deck ?? this.deck,
    index: index ?? this.index,
    completed: completed ?? this.completed,
    kind: kind == null ? this.kind : kind(),
    difficulty: difficulty == null ? this.difficulty : difficulty(),
    category: category == null ? this.category : category(),
    shuffle: shuffle ?? this.shuffle,
  );
}

final truthDareRepositoryProvider = FutureProvider<TruthDareRepository>(
  (ref) async => AssetTruthDareRepository(await SharedPreferences.getInstance()),
);

/// Builds filtered decks and tracks a session's progress.
class TruthDareController extends AsyncNotifier<TruthDareState> {
  late TruthDareRepository _repository;
  final _random = Random();

  @override
  Future<TruthDareState> build() async {
    _repository = await ref.watch(truthDareRepositoryProvider.future);
    final result = await _repository.getAll();
    final items = switch (result) {
      AppSuccess<List<TruthDareItem>>(:final value) => value,
      AppFailure<List<TruthDareItem>>(:final message) => throw StateError(message),
    };
    return TruthDareState(deck: _shuffle(items), index: 0, completed: 0);
  }

  Future<void> applyFilters({
    TruthDareKind? kind,
    Difficulty? difficulty,
    ContentCategory? category,
    bool shuffle = true,
  }) async {
    final result = await _repository.getAll();
    if (result case AppSuccess<List<TruthDareItem>>(:final value)) {
      var filtered = value
          .where((item) => kind == null || item.kind == kind)
          .where((item) => difficulty == null || item.difficulty == difficulty)
          .where((item) => category == null || item.category == category)
          .toList();
      if (shuffle) filtered = _shuffle(filtered);
      state = AsyncData(
        TruthDareState(
          deck: filtered,
          index: 0,
          completed: 0,
          kind: kind,
          difficulty: difficulty,
          category: category,
          shuffle: shuffle,
        ),
      );
    }
  }

  Future<void> next({bool completed = true}) async {
    final current = state.asData?.value;
    final item = current?.current;
    if (current == null || item == null) return;
    if (completed) await _repository.markCompleted(item.id);
    state = AsyncData(
      current.copyWith(
        index: (current.index + 1) % current.deck.length,
        completed: current.completed + (completed ? 1 : 0),
      ),
    );
  }

  Future<void> toggleFavorite() async {
    final current = state.asData?.value;
    final item = current?.current;
    if (current == null || item == null) return;
    final result = await _repository.toggleFavorite(item.id);
    if (result case AppSuccess<TruthDareItem>(:final value)) {
      final deck = [
        for (final card in current.deck)
          if (card.id == value.id) value else card,
      ];
      state = AsyncData(current.copyWith(deck: deck));
    }
  }

  List<TruthDareItem> _shuffle(List<TruthDareItem> items) {
    final shuffled = [...items]..shuffle(_random);
    return shuffled;
  }
}

final truthDareControllerProvider =
    AsyncNotifierProvider<TruthDareController, TruthDareState>(
      TruthDareController.new,
    );
