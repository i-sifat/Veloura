import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/conversation/domain/conversation_item.dart';
import 'package:veloura/features/conversation/domain/conversation_repository.dart';
import 'package:veloura/features/conversation/presentation/conversation_controller.dart';

/// Four-prompt queue shown by the Conversation Starters hero experience.
class ConversationStackState {
  const ConversationStackState({
    required this.items,
    required this.queue,
    required this.recentIds,
    this.hasAdvanced = false,
  });

  final List<ConversationItem> items;
  final List<ConversationItem> queue;
  final List<String> recentIds;
  final bool hasAdvanced;

  ConversationItem? get current => queue.firstOrNull;

  ConversationStackState copyWith({
    List<ConversationItem>? queue,
    List<String>? recentIds,
    bool? hasAdvanced,
  }) => ConversationStackState(
    items: items,
    queue: queue ?? this.queue,
    recentIds: recentIds ?? this.recentIds,
    hasAdvanced: hasAdvanced ?? this.hasAdvanced,
  );
}

/// Injectable randomness keeps queue behavior deterministic in tests.
final conversationStackRandomProvider = Provider<Random>((ref) => Random());

/// Owns the preloaded prompt queue and persisted no-repeat/answered state.
class ConversationStackController extends AsyncNotifier<ConversationStackState> {
  static const queueSize = 4;
  static const recentWindow = 20;

  late ConversationRepository _repository;
  late Random _random;

  @override
  Future<ConversationStackState> build() async {
    _repository = await ref.watch(conversationRepositoryProvider.future);
    _random = ref.read(conversationStackRandomProvider);
    final result = await _repository.getAll();
    final items = switch (result) {
      AppSuccess<List<ConversationItem>>(:final value) => value,
      AppFailure<List<ConversationItem>>(:final message) =>
        throw StateError(message),
    };
    final recentIds = await _repository.getRecentIds();
    return ConversationStackState(
      items: items,
      queue: _refill(items: items, recentIds: recentIds),
      recentIds: recentIds,
    );
  }

  /// Marks the visible prompt answered, advances the queue, and persists the
  /// same rolling no-repeat window used by the legacy Random mode.
  Future<void> advance() async {
    final current = state.asData?.value;
    final answered = current?.current;
    if (current == null || answered == null) return;

    final recentIds = <String>[
      answered.id,
      ...current.recentIds.where((id) => id != answered.id),
    ].take(recentWindow).toList(growable: false);
    await _repository.markAnswered(answered.id, DateTime.now());
    await _repository.setRecentIds(recentIds);

    final remaining = current.queue.skip(1).toList(growable: true);
    final queue = _refill(
      items: current.items,
      recentIds: recentIds,
      existing: remaining,
    );
    state = AsyncData(
      current.copyWith(
        queue: queue,
        recentIds: recentIds,
        hasAdvanced: true,
      ),
    );
  }

  List<ConversationItem> _refill({
    required List<ConversationItem> items,
    required List<String> recentIds,
    List<ConversationItem> existing = const [],
  }) {
    final queue = existing.toList(growable: true);
    while (queue.length < queueSize) {
      final queuedIds = queue.map((item) => item.id).toSet();
      var candidates = items
          .where((item) => !queuedIds.contains(item.id))
          .where((item) => !recentIds.contains(item.id))
          .toList(growable: false);
      if (candidates.isEmpty) {
        candidates = items
            .where((item) => !queuedIds.contains(item.id))
            .toList(growable: false);
      }
      if (candidates.isEmpty) break;
      queue.add(candidates[_random.nextInt(candidates.length)]);
    }
    return List.unmodifiable(queue);
  }
}

final conversationStackControllerProvider =
    AsyncNotifierProvider<ConversationStackController, ConversationStackState>(
      ConversationStackController.new,
    );
