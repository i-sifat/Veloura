import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/difficulty.dart';

/// Immutable base contract implemented by every content item.
abstract interface class ContentItem {
  /// Stable identifier used by persistence and analytics.
  String get id;

  /// Category used for discovery and filtering.
  ContentCategory get category;

  /// Intensity assigned by the editorial content pack.
  Difficulty get difficulty;

  /// Whether the current user favorited this item.
  bool get favorite;

  /// Timestamp for migration, sorting, and user-created content.
  DateTime get createdAt;
}
