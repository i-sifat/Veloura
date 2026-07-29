import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/roleplay/data/asset_roleplay_repository.dart';
import 'package:veloura/features/roleplay/domain/roleplay_repository.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/models/difficulty.dart';

/// Complete picker and active-session state for Roleplay Stories.
class RoleplayState {
  const RoleplayState({
    required this.items,
    this.category,
    this.difficulty,
    this.current,
    this.inSession = false,
    this.rolesSwapped = false,
    this.revealedTwists = 0,
  });

  final List<RoleplayStory> items;
  final RoleplayCategory? category;
  final Difficulty? difficulty;
  final RoleplayStory? current;
  final bool inSession;
  final bool rolesSwapped;
  final int revealedTwists;

  RoleplayState copyWith({
    List<RoleplayStory>? items,
    RoleplayCategory? Function()? category,
    Difficulty? Function()? difficulty,
    RoleplayStory? Function()? current,
    bool? inSession,
    bool? rolesSwapped,
    int? revealedTwists,
  }) => RoleplayState(
    items: items ?? this.items,
    category: category == null ? this.category : category(),
    difficulty: difficulty == null ? this.difficulty : difficulty(),
    current: current == null ? this.current : current(),
    inSession: inSession ?? this.inSession,
    rolesSwapped: rolesSwapped ?? this.rolesSwapped,
    revealedTwists: revealedTwists ?? this.revealedTwists,
  );
}

final roleplayRepositoryProvider = FutureProvider<RoleplayRepository>(
  (ref) async => AssetRoleplayRepository(
    await SharedPreferences.getInstance(),
    random: ref.read(roleplayRandomProvider),
  ),
);

/// Injectable randomness keeps selection deterministic in tests.
final roleplayRandomProvider = Provider<Random>((ref) => Random());

/// Coordinates story filtering, selection, favorites, and twist pacing.
class RoleplayController extends AsyncNotifier<RoleplayState> {
  static const completedPlaysKey = 'roleplay_completed_plays';
  late RoleplayRepository _repository;
  late Random _random;

  @override
  Future<RoleplayState> build() async {
    _random = ref.read(roleplayRandomProvider);
    _repository = await ref.watch(roleplayRepositoryProvider.future);
    final result = await _repository.getAll();
    final items = switch (result) {
      AppSuccess<List<RoleplayStory>>(:final value) => value,
      AppFailure<List<RoleplayStory>>(:final message) => throw StateError(message),
    };
    return RoleplayState(items: items);
  }

  void setCategory(RoleplayCategory? category) {
    final current = state.asData?.value;
    if (current != null) state = AsyncData(current.copyWith(category: () => category));
  }

  void setDifficulty(Difficulty? difficulty) {
    final current = state.asData?.value;
    if (current != null) state = AsyncData(current.copyWith(difficulty: () => difficulty));
  }

  List<RoleplayStory> visibleStories({required bool isPremium}) {
    final current = state.asData?.value;
    if (current == null) return const [];
    return current.items.where((item) =>
      (current.category == null || item.roleplayCategory == current.category) &&
      (current.difficulty == null || item.difficulty == current.difficulty) &&
      (isPremium || !item.premium)).toList(growable: false);
  }

  bool randomize({required bool isPremium}) {
    final current = state.asData?.value;
    final candidates = visibleStories(isPremium: isPremium);
    if (current == null || candidates.isEmpty) return false;
    state = AsyncData(current.copyWith(current: () => candidates[_random.nextInt(candidates.length)]));
    return true;
  }

  void select(RoleplayStory story) {
    final current = state.asData?.value;
    if (current != null) state = AsyncData(current.copyWith(current: () => story));
  }

  void startSession() {
    final current = state.asData?.value;
    if (current?.current == null) return;
    state = AsyncData(current!.copyWith(inSession: true, rolesSwapped: false, revealedTwists: 0));
  }

  void swapRoles() {
    final current = state.asData?.value;
    if (current != null) state = AsyncData(current.copyWith(rolesSwapped: !current.rolesSwapped));
  }

  void revealNextTwist() {
    final current = state.asData?.value;
    final story = current?.current;
    if (current == null || story == null || current.revealedTwists >= story.twists.length) return;
    state = AsyncData(current.copyWith(revealedTwists: current.revealedTwists + 1));
  }

  void endSession() {
    final current = state.asData?.value;
    if (current != null) state = AsyncData(current.copyWith(inSession: false, revealedTwists: 0));
  }

  /// Persists a compact completion event for future statistics.
  Future<void> recordPlay(String storyId) async {
    final preferences = await SharedPreferences.getInstance();
    final plays = preferences.getStringList(completedPlaysKey) ?? <String>[];
    await preferences.setStringList(completedPlaysKey, [
      ...plays,
      '$storyId|${DateTime.now().toUtc().toIso8601String()}',
    ]);
  }

  Future<void> toggleFavorite(RoleplayStory story) async {
    final current = state.asData?.value;
    if (current == null) return;
    final result = await _repository.toggleFavorite(story.id);
    if (result case AppSuccess<RoleplayStory>(:final value)) {
      final items = [for (final candidate in current.items) if (candidate.id == value.id) value else candidate];
      state = AsyncData(current.copyWith(items: items, current: current.current?.id == value.id ? () => value : null));
    }
  }
}

final roleplayControllerProvider = AsyncNotifierProvider<RoleplayController, RoleplayState>(RoleplayController.new);
