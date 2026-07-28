import 'dart:math';

import 'package:hive_ce/hive.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/core/content_repository.dart';
import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/content_item.dart';

/// Reusable Hive implementation for feature repositories.
abstract class HiveContentRepository<T extends ContentItem>
    implements ContentRepository<T> {
  HiveContentRepository(this.box, {Random? random})
    : _random = random ?? Random();

  /// Feature-owned Hive box.
  final Box<T> box;
  final Random _random;

  /// Returns searchable text for an item.
  String searchableText(T item);

  /// Returns a copy of [item] with [favorite] applied.
  T copyWithFavorite(T item, bool favorite);

  Future<AppResult<R>> guard<R>(Future<R> Function() operation) async {
    try {
      return AppResult.success(await operation());
    } on Object catch (error) {
      return AppResult.failure('We could not load this content.', error);
    }
  }

  @override
  Future<AppResult<List<T>>> getAll() =>
      guard(() async => List<T>.unmodifiable(box.values));

  @override
  Future<AppResult<List<T>>> getByCategory(ContentCategory category) => guard(
    () async => box.values.where((item) => item.category == category).toList(),
  );

  @override
  Future<AppResult<List<T>>> getFavorites() => guard(
    () async => box.values.where((item) => item.favorite).toList(),
  );

  @override
  Future<AppResult<T>> getRandom({ContentCategory? category}) => guard(() async {
    final items = box.values
        .where((item) => category == null || item.category == category)
        .toList();
    if (items.isEmpty) throw StateError('No matching content');
    return items[_random.nextInt(items.length)];
  });

  @override
  Future<AppResult<List<T>>> search(String query) => guard(() async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return List<T>.unmodifiable(box.values);
    return box.values
        .where(
          (item) => searchableText(item).toLowerCase().contains(normalized),
        )
        .toList();
  });

  @override
  Future<AppResult<T>> toggleFavorite(String id) => guard(() async {
    final item = box.get(id);
    if (item == null) throw StateError('Unknown content id: $id');
    final updated = copyWithFavorite(item, !item.favorite);
    await box.put(id, updated);
    return updated;
  });
}
