import 'package:veloura/core/app_result.dart';
import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/content_item.dart';

/// Storage-agnostic operations shared by all content modules.
abstract interface class ContentRepository<T extends ContentItem> {
  /// Returns all items.
  Future<AppResult<List<T>>> getAll();

  /// Returns items in [category].
  Future<AppResult<List<T>>> getByCategory(ContentCategory category);

  /// Returns all favorited items.
  Future<AppResult<List<T>>> getFavorites();

  /// Flips and persists the favorite state for [id].
  Future<AppResult<T>> toggleFavorite(String id);

  /// Returns one random item, optionally scoped to [category].
  Future<AppResult<T>> getRandom({ContentCategory? category});

  /// Searches user-visible item text.
  Future<AppResult<List<T>>> search(String query);
}
