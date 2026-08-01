import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/conversation/domain/conversation_item.dart';
import 'package:veloura/features/conversation/domain/conversation_repository.dart';
import 'package:veloura/features/conversation/presentation/conversation_controller.dart';
import 'package:veloura/features/conversation/presentation/stack/stack_controller.dart';
import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/difficulty.dart';

class _MemoryConversationRepository implements ConversationRepository {
  _MemoryConversationRepository(this.items);

  final List<ConversationItem> items;
  final Map<String, DateTime> answered = {};
  List<String> recent = [];

  @override
  Future<Map<String, DateTime>> getAnswered() async => answered;

  @override
  Future<void> markAnswered(String id, DateTime timestamp) async {
    answered[id] = timestamp;
  }

  @override
  Future<List<String>> getRecentIds() async => recent;

  @override
  Future<void> setRecentIds(List<String> ids) async {
    recent = ids;
  }

  @override
  Future<AppResult<List<ConversationItem>>> getAll() async =>
      AppResult.success(items);

  @override
  Future<AppResult<List<ConversationItem>>> getByCategory(
    ContentCategory category,
  ) async => AppResult.success(
    items.where((item) => item.category == category).toList(),
  );

  @override
  Future<AppResult<List<ConversationItem>>> getFavorites() async =>
      AppResult.success(<ConversationItem>[]);

  @override
  Future<AppResult<ConversationItem>> getRandom({
    ContentCategory? category,
  }) async => AppResult.success(items.first);

  @override
  Future<AppResult<List<ConversationItem>>> search(String query) async =>
      AppResult.success(items);

  @override
  Future<AppResult<ConversationItem>> toggleFavorite(String id) async =>
      AppResult.success(items.firstWhere((item) => item.id == id));
}

void main() {
  final items = List.generate(
    30,
    (index) => ConversationItem(
      id: 'cv_$index',
      prompt: 'Prompt $index',
      conversationCategory: ConversationCategory.deep,
      difficulty: Difficulty.romantic,
      createdAt: DateTime(2026),
    ),
  );

  test('preloads four unique prompts and persists each advance', () async {
    final repository = _MemoryConversationRepository(items);
    final container = ProviderContainer(
      overrides: [
        conversationRepositoryProvider.overrideWith((ref) async => repository),
        conversationStackRandomProvider.overrideWith((ref) => Random(7)),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(
      conversationStackControllerProvider.future,
    );
    expect(initial.queue, hasLength(4));
    expect(initial.queue.map((item) => item.id).toSet(), hasLength(4));
    final answeredId = initial.current!.id;

    await container.read(conversationStackControllerProvider.notifier).advance();
    final advanced = container
        .read(conversationStackControllerProvider)
        .requireValue;

    expect(repository.answered, contains(answeredId));
    expect(repository.recent.first, answeredId);
    expect(advanced.queue, hasLength(4));
    expect(advanced.current!.id, isNot(answeredId));
    expect(advanced.hasAdvanced, isTrue);
  });

  test(
    'roundPosition is a decorative session position that cycles 1..roundLength and back to 1',
    () async {
      final repository = _MemoryConversationRepository(items);
      final container = ProviderContainer(
        overrides: [
          conversationRepositoryProvider.overrideWith((ref) async => repository),
          conversationStackRandomProvider.overrideWith((ref) => Random(7)),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(
        conversationStackControllerProvider.future,
      );
      expect(initial.roundPosition, 1);

      final notifier = container.read(conversationStackControllerProvider.notifier);
      const roundLength = ConversationStackController.roundLength;

      for (var expected = 2; expected <= roundLength; expected++) {
        await notifier.advance();
        expect(
          container.read(conversationStackControllerProvider).requireValue.roundPosition,
          expected,
        );
      }

      // One more advance past roundLength wraps back to 1.
      await notifier.advance();
      expect(
        container.read(conversationStackControllerProvider).requireValue.roundPosition,
        1,
      );
    },
  );
}
