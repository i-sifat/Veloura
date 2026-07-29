import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/content_item.dart';
import 'package:veloura/models/difficulty.dart';

/// Editorial categories used to browse roleplay stories.
enum RoleplayCategory { fantasy, romance, adventure }

/// One playable character in a roleplay story.
class RoleplayCharacter {
  const RoleplayCharacter({required this.name, required this.description});

  factory RoleplayCharacter.fromJson(Map<String, Object?> json) =>
      RoleplayCharacter(
        name: json['name']! as String,
        description: json['description']! as String,
      );

  final String name;
  final String description;
}

/// Immutable, local-first roleplay scenario.
class RoleplayStory implements ContentItem {
  const RoleplayStory({
    required this.id,
    required this.title,
    required this.roleplayCategory,
    required this.difficulty,
    required this.characterA,
    required this.characterB,
    required this.setting,
    required this.goal,
    required this.twists,
    required this.estimatedDuration,
    required this.packId,
    required this.packTitle,
    required this.premium,
    required this.createdAt,
    this.favorite = false,
  });

  factory RoleplayStory.fromJson(Map<String, Object?> json) => RoleplayStory(
    id: json['id']! as String,
    title: json['title']! as String,
    roleplayCategory: RoleplayCategory.values.byName(
      json['category']! as String,
    ),
    difficulty: Difficulty.values.byName(json['tier']! as String),
    characterA: RoleplayCharacter.fromJson(
      json['characterA']! as Map<String, Object?>,
    ),
    characterB: RoleplayCharacter.fromJson(
      json['characterB']! as Map<String, Object?>,
    ),
    setting: json['setting']! as String,
    goal: json['goal']! as String,
    twists: (json['twists']! as List<dynamic>).cast<String>(),
    estimatedDuration: json['estimatedDuration']! as String,
    packId: json['packId']! as String,
    packTitle: json['packTitle']! as String,
    premium: json['premium']! as bool,
    createdAt: DateTime.parse(json['createdAt']! as String),
  );

  @override
  final String id;
  final String title;
  final RoleplayCategory roleplayCategory;
  @override
  ContentCategory get category => switch (roleplayCategory) {
    RoleplayCategory.fantasy => ContentCategory.fantasy,
    RoleplayCategory.romance => ContentCategory.romance,
    RoleplayCategory.adventure => ContentCategory.adventure,
  };
  @override
  final Difficulty difficulty;
  final RoleplayCharacter characterA;
  final RoleplayCharacter characterB;
  final String setting;
  final String goal;
  final List<String> twists;
  final String estimatedDuration;
  final String packId;
  final String packTitle;
  final bool premium;
  @override
  final DateTime createdAt;
  @override
  final bool favorite;

  RoleplayStory copyWith({bool? favorite}) => RoleplayStory(
    id: id,
    title: title,
    roleplayCategory: roleplayCategory,
    difficulty: difficulty,
    characterA: characterA,
    characterB: characterB,
    setting: setting,
    goal: goal,
    twists: twists,
    estimatedDuration: estimatedDuration,
    packId: packId,
    packTitle: packTitle,
    premium: premium,
    createdAt: createdAt,
    favorite: favorite ?? this.favorite,
  );
}
