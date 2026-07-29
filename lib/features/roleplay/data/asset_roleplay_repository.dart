import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/roleplay/domain/roleplay_repository.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/difficulty.dart';

/// Asset-backed story pack with lightweight persisted favorites.
class AssetRoleplayRepository implements RoleplayRepository {
  AssetRoleplayRepository(this.preferences, {Random? random})
    : _random = random ?? Random();

  final SharedPreferences preferences;
  final Random _random;
  List<RoleplayStory>? _cache;

  static const _favoritesKey = 'roleplay_favorites';
  static const _assetPath =
      'lib/features/roleplay/data/roleplay_seed.json';

  Future<List<RoleplayStory>> _items() async {
    if (_cache case final cached?) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final favorites = preferences.getStringList(_favoritesKey)?.toSet() ?? {};
    return _cache = (jsonDecode(raw) as List<dynamic>)
        .map((value) => RoleplayStory.fromJson(value as Map<String, Object?>))
        .map((item) => item.copyWith(favorite: favorites.contains(item.id)))
        .toList(growable: false);
  }

  Future<AppResult<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return AppResult.success(await operation());
    } on Object catch (error) {
      return AppResult.failure('Roleplay stories could not be loaded.', error);
    }
  }

  @override
  Future<AppResult<List<RoleplayStory>>> getAll() => _guard(_items);

  @override
  Future<AppResult<List<RoleplayStory>>> getByCategory(
    ContentCategory category,
  ) => _guard(
    () async => (await _items())
        .where((item) => item.category == category)
        .toList(growable: false),
  );

  @override
  Future<AppResult<List<RoleplayStory>>> getFavorites() => _guard(
    () async => (await _items())
        .where((item) => item.favorite)
        .toList(growable: false),
  );

  @override
  Future<AppResult<RoleplayStory>> getRandom({ContentCategory? category}) =>
      _guard(() async {
        final candidates = (await _items())
            .where((item) => category == null || item.category == category)
            .toList();
        if (candidates.isEmpty) throw StateError('No matching stories.');
        return candidates[_random.nextInt(candidates.length)];
      });

  @override
  Future<AppResult<List<RoleplayStory>>> search(String query) => _guard(
    () async {
      final needle = query.toLowerCase().trim();
      return (await _items())
          .where(
            (item) =>
                item.title.toLowerCase().contains(needle) ||
                item.setting.toLowerCase().contains(needle) ||
                item.packTitle.toLowerCase().contains(needle),
          )
          .toList(growable: false);
    },
  );

  @override
  Future<AppResult<RoleplayStory>> toggleFavorite(String id) => _guard(
    () async {
      final items = await _items();
      final index = items.indexWhere((item) => item.id == id);
      if (index < 0) throw StateError('Unknown story.');
      final updated = items[index].copyWith(favorite: !items[index].favorite);
      _cache = [...items]..[index] = updated;
      await preferences.setStringList(
        _favoritesKey,
        _cache!
            .where((item) => item.favorite)
            .map((item) => item.id)
            .toList(growable: false),
      );
      return updated;
    },
  );

  @override
  Future<List<RoleplayStory>> getFiltered({
    RoleplayCategory? category,
    Difficulty? difficulty,
    required bool includePremium,
  }) async => (await _items())
      .where(
        (item) =>
            (category == null || item.roleplayCategory == category) &&
            (difficulty == null || item.difficulty == difficulty) &&
            (includePremium || !item.premium),
      )
      .toList(growable: false);
}
