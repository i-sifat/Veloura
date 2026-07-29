import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/conversation/domain/conversation_item.dart';
import 'package:veloura/features/conversation/domain/conversation_repository.dart';
import 'package:veloura/models/content_category.dart';

/// JSON conversation pack plus persisted favorites/answered/no-repeat state.
class AssetConversationRepository implements ConversationRepository {
  AssetConversationRepository(this.preferences, {Random? random})
    : _random = random ?? Random();

  final SharedPreferences preferences;
  final Random _random;
  List<ConversationItem>? _cache;
  static const _favorites = 'conversation_favorites';
  static const _answered = 'conversation_answered';
  static const _recent = 'conversation_recent';

  Future<List<ConversationItem>> _items() async {
    if (_cache case final cached?) return cached;
    final raw = await rootBundle.loadString(
      'lib/features/conversation/data/conversation_seed.json',
    );
    final favorites = preferences.getStringList(_favorites)?.toSet() ?? {};
    return _cache = (jsonDecode(raw) as List<dynamic>)
        .map((value) => ConversationItem.fromJson(value as Map<String, Object?>))
        .map((item) => item.copyWith(favorite: favorites.contains(item.id)))
        .toList(growable: false);
  }

  Future<AppResult<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return AppResult.success(await operation());
    } on Object catch (error) {
      return AppResult.failure('Conversation prompts could not be loaded.', error);
    }
  }

  @override
  Future<AppResult<List<ConversationItem>>> getAll() => _guard(_items);

  @override
  Future<AppResult<List<ConversationItem>>> getByCategory(
    ContentCategory category,
  ) => _guard(() async =>
      (await _items()).where((item) => item.category == category).toList());

  @override
  Future<AppResult<List<ConversationItem>>> getFavorites() => _guard(() async =>
      (await _items()).where((item) => item.favorite).toList());

  @override
  Future<AppResult<ConversationItem>> getRandom({ContentCategory? category}) =>
      _guard(() async {
        final items = (await _items())
            .where((item) => category == null || item.category == category)
            .toList();
        if (items.isEmpty) throw StateError('No prompts');
        return items[_random.nextInt(items.length)];
      });

  @override
  Future<AppResult<List<ConversationItem>>> search(String query) =>
      _guard(() async {
        final needle = query.toLowerCase();
        return (await _items())
            .where((item) => item.prompt.toLowerCase().contains(needle))
            .toList();
      });

  @override
  Future<AppResult<ConversationItem>> toggleFavorite(String id) =>
      _guard(() async {
        final items = await _items();
        final index = items.indexWhere((item) => item.id == id);
        if (index < 0) throw StateError('Unknown prompt');
        final updated = items[index].copyWith(favorite: !items[index].favorite);
        _cache = [...items]..[index] = updated;
        await preferences.setStringList(
          _favorites,
          _cache!
              .where((item) => item.favorite)
              .map((item) => item.id)
              .toList(),
        );
        return updated;
      });

  @override
  Future<Map<String, DateTime>> getAnswered() async {
    final raw = preferences.getString(_answered);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map(
      (id, timestamp) => MapEntry(id, DateTime.parse(timestamp as String)),
    );
  }

  @override
  Future<void> markAnswered(String id, DateTime timestamp) async {
    final values = await getAnswered()..[id] = timestamp;
    await preferences.setString(
      _answered,
      jsonEncode(values.map((key, value) => MapEntry(key, value.toIso8601String()))),
    );
  }

  @override
  Future<List<String>> getRecentIds() async =>
      preferences.getStringList(_recent) ?? [];

  @override
  Future<void> setRecentIds(List<String> ids) async {
    await preferences.setStringList(_recent, ids);
  }
}
