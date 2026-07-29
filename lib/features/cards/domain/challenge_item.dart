import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/content_item.dart';
import 'package:veloura/models/difficulty.dart';

/// The eight Challenge Card categories.
enum ChallengeCategory {
  romance,
  adventure,
  connection,
  playful,
  kindness,
  creativity,
  wellness,
  surprise,
}

/// User lifecycle for a challenge.
enum ChallengeStatus { available, inProgress, completed, locked }

/// Immutable Challenge Card content.
class ChallengeItem implements ContentItem {
  const ChallengeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.challengeCategory,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.createdAt,
    this.premium = false,
    this.favorite = false,
  });

  factory ChallengeItem.fromJson(Map<String, Object?> json) => ChallengeItem(
    id: json['id']! as String,
    title: json['title']! as String,
    description: json['description']! as String,
    challengeCategory: ChallengeCategory.values.byName(
      json['challengeCategory']! as String,
    ),
    difficulty: Difficulty.values.byName(json['difficulty']! as String),
    estimatedMinutes: json['estimatedMinutes']! as int,
    premium: json['premium'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt']! as String),
  );

  @override
  final String id;
  final String title;
  final String description;
  final ChallengeCategory challengeCategory;
  @override
  ContentCategory get category => switch (challengeCategory) {
    ChallengeCategory.romance => ContentCategory.romance,
    ChallengeCategory.adventure => ContentCategory.adventure,
    ChallengeCategory.connection => ContentCategory.relationship,
    ChallengeCategory.playful => ContentCategory.playful,
    ChallengeCategory.kindness => ContentCategory.relationship,
    ChallengeCategory.creativity => ContentCategory.playful,
    ChallengeCategory.wellness => ContentCategory.daily,
    ChallengeCategory.surprise => ContentCategory.adventure,
  };
  @override
  final Difficulty difficulty;
  final int estimatedMinutes;
  final bool premium;
  @override
  final DateTime createdAt;
  @override
  final bool favorite;

  ChallengeItem copyWith({bool? favorite}) => ChallengeItem(
    id: id,
    title: title,
    description: description,
    challengeCategory: challengeCategory,
    difficulty: difficulty,
    estimatedMinutes: estimatedMinutes,
    premium: premium,
    createdAt: createdAt,
    favorite: favorite ?? this.favorite,
  );
}
