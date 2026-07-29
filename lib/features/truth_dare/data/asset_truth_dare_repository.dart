import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/truth_dare/domain/truth_dare_item.dart';
import 'package:veloura/features/truth_dare/domain/truth_dare_repository.dart';
import 'package:veloura/models/content_category.dart';

/// JSON-pack repository with lightweight persisted favorite/progress flags.
class AssetTruthDareRepository implements TruthDareRepository {
  AssetTruthDareRepository(this.preferences, {Random? random})
    : _random = random ?? Random();

  final SharedPreferences preferences;
  final Random _random;
  List<TruthDareItem>? _cache;

  static const _favoritesKey = 'td_favorites';
  static const _completedKey = 'td_completed';

  Future<List<TruthDareItem>> _items() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(
      'lib/features/truth_dare/data/truth_dare_seed.json',
    );
    final favorites = preferences.getStringList(_favoritesKey)?.toSet() ?? {};
    final decoded = jsonDecode(raw) as List<dynamic>;
    return _cache = decoded
        .map((value) => TruthDareItem.fromJson(value as Map<String, Object?>))
        .map((item) => item.copyWith(favorite: favorites.contains(item.id)))
        .toList(growable: false);
  }

  Future<AppResult<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return AppResult.success(await operation());
    } on Object catch (error) {
      return AppResult.failure('Truth or Dare could not be loaded.', error);
    }
  }

  @override
  Future<AppResult<List<TruthDareItem>>> getAll() => _guard(_items);

  @override
  Future<AppResult<List<TruthDareItem>>> getByCategory(
    ContentCategory category,
  ) => _guard(() async {
    final items = await _items();
    return items.where((item) => item.category == category).toList();
  });

  @override
  Future<AppResult<List<TruthDareItem>>> getFavorites() => _guard(() async {
    final items = await _items();
    return items.where((item) => item.favorite).toList();
  });

  @override
  Future<AppResult<TruthDareItem>> getRandom({ContentCategory? category}) =>
      _guard(() async {
        final items = (await _items())
            .where((item) => category == null || item.category == category)
            .toList();
        if (items.isEmpty) throw StateError('No matching cards');
        return items[_random.nextInt(items.length)];
      });

  @override
  Future<AppResult<List<TruthDareItem>>> search(String query) => _guard(() async {
    final normalized = query.trim().toLowerCase();
    final items = await _items();
    return items
        .where((item) => item.prompt.toLowerCase().contains(normalized))
        .toList();
  });

  @override
  Future<AppResult<TruthDareItem>> toggleFavorite(String id) => _guard(() async {
    final items = await _items();
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Unknown card');
    final updated = items[index].copyWith(favorite: !items[index].favorite);
    final mutable = [...items]..[index] = updated;
    _cache = mutable;
    final favorites = mutable
        .where((item) => item.favorite)
        .map((item) => item.id)
        .toList();
    await preferences.setStringList(_favoritesKey, favorites);
    return updated;
  });

  @override
  Future<Set<String>> getCompletedIds() async =>
      preferences.getStringList(_completedKey)?.toSet() ?? {};

  @override
  Future<void> markCompleted(String id) async {
    final completed = await getCompletedIds()..add(id);
    await preferences.setStringList(_completedKey, completed.toList());
  }
}
