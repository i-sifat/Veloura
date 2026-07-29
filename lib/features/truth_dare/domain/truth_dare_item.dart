import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/content_item.dart';
import 'package:veloura/models/difficulty.dart';

/// Truth or Dare card type.
enum TruthDareKind { truth, dare }

/// Immutable Truth or Dare content item.
class TruthDareItem implements ContentItem {
  const TruthDareItem({
    required this.id,
    required this.kind,
    required this.prompt,
    required this.category,
    required this.difficulty,
    required this.createdAt,
    this.favorite = false,
  });

  factory TruthDareItem.fromJson(Map<String, Object?> json) => TruthDareItem(
    id: json['id']! as String,
    kind: TruthDareKind.values.byName(json['kind']! as String),
    prompt: json['prompt']! as String,
    category: ContentCategory.values.byName(json['category']! as String),
    difficulty: Difficulty.values.byName(json['difficulty']! as String),
    createdAt: DateTime.parse(json['createdAt']! as String),
  );

  @override
  final String id;
  final TruthDareKind kind;
  final String prompt;
  @override
  final ContentCategory category;
  @override
  final Difficulty difficulty;
  @override
  final DateTime createdAt;
  @override
  final bool favorite;

  TruthDareItem copyWith({bool? favorite}) => TruthDareItem(
    id: id,
    kind: kind,
    prompt: prompt,
    category: category,
    difficulty: difficulty,
    createdAt: createdAt,
    favorite: favorite ?? this.favorite,
  );
}
