import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/cards/domain/challenge_item.dart';
import 'package:veloura/features/cards/domain/challenge_repository.dart';
import 'package:veloura/models/content_category.dart';

/// JSON challenge pack plus persisted lifecycle/favorite/reward flags.
class AssetChallengeRepository implements ChallengeRepository {
  AssetChallengeRepository(this.preferences, {Random? random})
    : _random = random ?? Random();

  final SharedPreferences preferences;
  final Random _random;
  List<ChallengeItem>? _cache;
  static const _favorites = 'challenge_favorites';
  static const _progress = 'challenge_progress';
  static const _rewards = 'reward_balance';

  Future<List<ChallengeItem>> _items() async {
    if (_cache case final cached?) return cached;
    final raw = await rootBundle.loadString(
      'lib/features/cards/data/challenge_seed.json',
    );
    final favorites = preferences.getStringList(_favorites)?.toSet() ?? {};
    return _cache = (jsonDecode(raw) as List<dynamic>)
        .map((value) => ChallengeItem.fromJson(value as Map<String, Object?>))
        .map((item) => item.copyWith(favorite: favorites.contains(item.id)))
        .toList(growable: false);
  }

  Future<AppResult<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return AppResult.success(await operation());
    } on Object catch (error) {
      return AppResult.failure('Challenges could not be loaded.', error);
    }
  }

  @override
  Future<AppResult<List<ChallengeItem>>> getAll() => _guard(_items);

  @override
  Future<AppResult<List<ChallengeItem>>> getByCategory(
    ContentCategory category,
  ) => _guard(() async =>
      (await _items()).where((item) => item.category == category).toList());

  @override
  Future<AppResult<List<ChallengeItem>>> getFavorites() => _guard(() async =>
      (await _items()).where((item) => item.favorite).toList());

  @override
  Future<AppResult<ChallengeItem>> getRandom({ContentCategory? category}) =>
      _guard(() async {
        final items = (await _items())
            .where((item) => category == null || item.category == category)
            .toList();
        if (items.isEmpty) throw StateError('No challenges');
        return items[_random.nextInt(items.length)];
      });

  @override
  Future<AppResult<List<ChallengeItem>>> search(String query) => _guard(() async {
    final needle = query.toLowerCase();
    return (await _items())
        .where((item) =>
            item.title.toLowerCase().contains(needle) ||
            item.description.toLowerCase().contains(needle))
        .toList();
  });

  @override
  Future<AppResult<ChallengeItem>> toggleFavorite(String id) => _guard(() async {
    final items = await _items();
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Unknown challenge');
    final updated = items[index].copyWith(favorite: !items[index].favorite);
    _cache = [...items]..[index] = updated;
    await preferences.setStringList(
      _favorites,
      _cache!.where((item) => item.favorite).map((item) => item.id).toList(),
    );
    return updated;
  });

  @override
  Future<Map<String, ChallengeProgress>> getProgress() async {
    final raw = preferences.getString(_progress);
    if (raw == null) return {};
    final values = jsonDecode(raw) as Map<String, dynamic>;
    return values.map((id, value) {
      final data = value as Map<String, dynamic>;
      return MapEntry(
        id,
        ChallengeProgress(
          status: ChallengeStatus.values.byName(data['status'] as String),
          reflection: data['reflection'] as String?,
          completedAt: data['completedAt'] == null
              ? null
              : DateTime.parse(data['completedAt'] as String),
        ),
      );
    });
  }

  @override
  Future<void> setProgress(String id, ChallengeProgress progress) async {
    final all = await getProgress()..[id] = progress;
    final encoded = all.map((key, value) => MapEntry(key, {
      'status': value.status.name,
      'reflection': value.reflection,
      'completedAt': value.completedAt?.toIso8601String(),
    }));
    await preferences.setString(_progress, jsonEncode(encoded));
    if (progress.status == ChallengeStatus.completed) {
      await preferences.setInt(_rewards, (await getRewardBalance()) + 10);
    }
  }

  @override
  Future<int> getRewardBalance() async => preferences.getInt(_rewards) ?? 0;
}
