import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/conversation/domain/conversation_item.dart';
import 'package:veloura/features/conversation/domain/conversation_repository.dart';
import 'package:veloura/features/conversation/presentation/conversation_controller.dart';
import 'package:veloura/features/conversation/presentation/stack/creative_connections_screen.dart';
import 'package:veloura/features/conversation/presentation/stack/stack_controller.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/player.dart';
import 'package:veloura/features/session/domain/session_repository.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
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

class _SavedSessionRepository implements SessionRepository {
  _SavedSessionRepository(this.value);

  GameSession value;

  @override
  Future<AppResult<GameSession?>> load() async => AppResult.success(value);

  @override
  Future<AppResult<void>> save(GameSession session) async {
    value = session;
    return const AppResult.success(null);
  }
}

GameSession _session() => GameSession(
  a: const Player(id: 'a', name: 'You', colorValue: 0xFFFF4D6D),
  b: const Player(id: 'b', name: 'Partner', colorValue: 0xFF8E4BD1),
  activeIndex: 0,
  startedAt: DateTime(2026),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final items = List.generate(
    10,
    (index) => ConversationItem(
      id: 'cv_$index',
      prompt: 'Prompt $index',
      conversationCategory: ConversationCategory.deep,
      difficulty: Difficulty.romantic,
      createdAt: DateTime(2026),
    ),
  );

  Widget buildApp({
    required _MemoryConversationRepository repository,
    required _SavedSessionRepository sessionRepository,
  }) => ProviderScope(
    overrides: [
      conversationRepositoryProvider.overrideWith((ref) async => repository),
      conversationStackRandomProvider.overrideWith((ref) => Random(7)),
      sessionRepositoryProvider.overrideWith((ref) async => sessionRepository),
    ],
    child: const MaterialApp(home: CreativeConnectionsScreen()),
  );

  testWidgets('renders title, step progress, turn chips, and the current prompt', (
    tester,
  ) async {
    final repository = _MemoryConversationRepository(items);
    final sessionRepository = _SavedSessionRepository(_session());

    await tester.pumpWidget(
      buildApp(repository: repository, sessionRepository: sessionRepository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Creative connections'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Partner'), findsOneWidget);
    expect(find.text('Next question'), findsOneWidget);
  });

  testWidgets('tapping Next question advances the queue and hands off the turn', (
    tester,
  ) async {
    final repository = _MemoryConversationRepository(items);
    final sessionRepository = _SavedSessionRepository(_session());

    await tester.pumpWidget(
      buildApp(repository: repository, sessionRepository: sessionRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next question'));
    await tester.pumpAndSettle();

    expect(repository.answered, isNotEmpty);
    expect(sessionRepository.value.activeIndex, 1);
  });
}
