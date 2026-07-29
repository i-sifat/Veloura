import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/conversation/data/asset_conversation_repository.dart';
import 'package:veloura/features/conversation/domain/conversation_item.dart';
import 'package:veloura/features/conversation/domain/conversation_repository.dart';

/// Conversation presentation mode.
enum ConversationMode { random, browse }

class ConversationState {
  const ConversationState({
    required this.items,
    required this.answered,
    required this.recentIds,
    required this.current,
    this.mode = ConversationMode.random,
    this.category,
  });

  final List<ConversationItem> items;
  final Map<String, DateTime> answered;
  final List<String> recentIds;
  final ConversationItem? current;
  final ConversationMode mode;
  final ConversationCategory? category;

  ConversationState copyWith({
    List<ConversationItem>? items,
    Map<String, DateTime>? answered,
    List<String>? recentIds,
    ConversationItem? current,
    ConversationMode? mode,
    ConversationCategory? Function()? category,
  }) => ConversationState(
    items: items ?? this.items,
    answered: answered ?? this.answered,
    recentIds: recentIds ?? this.recentIds,
    current: current ?? this.current,
    mode: mode ?? this.mode,
    category: category == null ? this.category : category(),
  );
}

final conversationRepositoryProvider = FutureProvider<ConversationRepository>(
  (ref) async =>
      AssetConversationRepository(await SharedPreferences.getInstance()),
);

class ConversationController extends AsyncNotifier<ConversationState> {
  late ConversationRepository _repository;
  final _random = Random();

  @override
  Future<ConversationState> build() async {
    _repository = await ref.watch(conversationRepositoryProvider.future);
    final result = await _repository.getAll();
    final items = switch (result) {
      AppSuccess<List<ConversationItem>>(:final value) => value,
      AppFailure<List<ConversationItem>>(:final message) =>
        throw StateError(message),
    };
    final recent = await _repository.getRecentIds();
    return ConversationState(
      items: items,
      answered: await _repository.getAnswered(),
      recentIds: recent,
      current: _pick(items, recent, null),
    );
  }

  Future<void> randomize() async {
    final current = state.asData?.value;
    if (current == null) return;
    final item = _pick(current.items, current.recentIds, current.category);
    if (item == null) return;
    final recent = [item.id, ...current.recentIds.where((id) => id != item.id)]
        .take(20)
        .toList();
    await _repository.setRecentIds(recent);
    state = AsyncData(current.copyWith(current: item, recentIds: recent));
  }

  void setMode(ConversationMode mode) {
    final current = state.asData?.value;
    if (current != null) state = AsyncData(current.copyWith(mode: mode));
  }

  void setCategory(ConversationCategory? category) {
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(current.copyWith(category: () => category));
    }
  }

  void select(ConversationItem item) {
    final current = state.asData?.value;
    if (current != null) state = AsyncData(current.copyWith(current: item));
  }

  Future<void> toggleFavorite(ConversationItem item) async {
    final current = state.asData?.value;
    if (current == null) return;
    final result = await _repository.toggleFavorite(item.id);
    if (result case AppSuccess<ConversationItem>(:final value)) {
      final items = [
        for (final candidate in current.items)
          if (candidate.id == value.id) value else candidate,
      ];
      state = AsyncData(current.copyWith(
        items: items,
        current: current.current?.id == value.id ? value : current.current,
      ));
    }
  }

  Future<void> markAnswered(ConversationItem item) async {
    final current = state.asData?.value;
    if (current == null) return;
    final now = DateTime.now();
    await _repository.markAnswered(item.id, now);
    state = AsyncData(
      current.copyWith(answered: {...current.answered, item.id: now}),
    );
  }

  ConversationItem? _pick(
    List<ConversationItem> items,
    List<String> recent,
    ConversationCategory? category,
  ) {
    var candidates = items
        .where((item) => category == null || item.conversationCategory == category)
        .where((item) => !recent.contains(item.id))
        .toList();
    if (candidates.isEmpty) {
      candidates = items
          .where((item) => category == null || item.conversationCategory == category)
          .toList();
    }
    return candidates.isEmpty ? null : candidates[_random.nextInt(candidates.length)];
  }
}

final conversationControllerProvider =
    AsyncNotifierProvider<ConversationController, ConversationState>(
      ConversationController.new,
    );
