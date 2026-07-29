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
      const AppResult.success([]);

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
        conversationStackRandomProvider.overrideWithValue(Random(7)),
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
    final advanced = container.read(conversationStackControllerProvider).value!;

    expect(repository.answered, contains(answeredId));
    expect(repository.recent.first, answeredId);
    expect(advanced.queue, hasLength(4));
    expect(advanced.current!.id, isNot(answeredId));
    expect(advanced.hasAdvanced, isTrue);
  });
}
