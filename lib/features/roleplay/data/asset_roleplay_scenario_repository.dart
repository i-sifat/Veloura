import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/roleplay/domain/roleplay_scenario.dart';
import 'package:veloura/features/roleplay/domain/roleplay_scenario_repository.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/difficulty.dart';

/// Asset-backed scenario pack with lightweight persisted favorites.
class AssetRoleplayScenarioRepository implements RoleplayScenarioRepository {
  AssetRoleplayScenarioRepository(this.preferences, {Random? random})
    : _random = random ?? Random();

  final SharedPreferences preferences;
  final Random _random;
  List<RoleplayScenario>? _cache;

  static const _favoritesKey = 'roleplay_scenario_favorites';
  static const _assetPath =
      'lib/features/roleplay/data/roleplay_scenarios_seed.json';

  Future<List<RoleplayScenario>> _items() async {
    if (_cache case final cached?) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final favorites = preferences.getStringList(_favoritesKey)?.toSet() ?? {};
    return _cache = (jsonDecode(raw) as List<dynamic>)
        .map(
          (value) => RoleplayScenario.fromJson(value as Map<String, Object?>),
        )
        .map((item) => item.copyWith(favorite: favorites.contains(item.id)))
        .toList(growable: false);
  }

  Future<AppResult<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return AppResult.success(await operation());
    } on Object catch (error) {
      return AppResult.failure(
        'Roleplay scenarios could not be loaded.',
        error,
      );
    }
  }

  @override
  Future<AppResult<List<RoleplayScenario>>> getAll() => _guard(_items);

  @override
  Future<AppResult<List<RoleplayScenario>>> getByCategory(
    ContentCategory category,
  ) => _guard(
    () async => (await _items())
        .where((item) => item.category == category)
        .toList(growable: false),
  );

  @override
  Future<AppResult<List<RoleplayScenario>>> getFavorites() => _guard(
    () async =>
        (await _items()).where((item) => item.favorite).toList(growable: false),
  );

  @override
  Future<AppResult<RoleplayScenario>> getRandom({ContentCategory? category}) =>
      _guard(() async {
        final candidates = (await _items())
            .where((item) => category == null || item.category == category)
            .toList();
        if (candidates.isEmpty) throw StateError('No matching scenarios.');
        return candidates[_random.nextInt(candidates.length)];
      });

  @override
  Future<AppResult<List<RoleplayScenario>>> search(String query) => _guard(() async {
    final needle = query.toLowerCase().trim();
    return (await _items())
        .where(
          (item) =>
              item.title.toLowerCase().contains(needle) ||
              item.description.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  });

  @override
  Future<AppResult<RoleplayScenario>> toggleFavorite(String id) =>
      _guard(() async {
        final items = await _items();
        final index = items.indexWhere((item) => item.id == id);
        if (index < 0) throw StateError('Unknown scenario.');
        final updated = items[index].copyWith(
          favorite: !items[index].favorite,
        );
        _cache = [...items]..[index] = updated;
        await preferences.setStringList(
          _favoritesKey,
          _cache!
              .where((item) => item.favorite)
              .map((item) => item.id)
              .toList(growable: false),
        );
        return updated;
      });

  @override
  Future<List<RoleplayScenario>> getFiltered({
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
