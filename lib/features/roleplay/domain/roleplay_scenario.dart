import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/content_item.dart';
import 'package:veloura/models/difficulty.dart';

/// Literal token replaced with the active session's first player name.
const kCharacterATag = '@CharacterA';

/// Literal token replaced with the active session's second player name.
const kCharacterBTag = '@CharacterB';

/// A single spin-wheel scenario for the redesigned Passionate Roleplay game.
///
/// Unlike the older [RoleplayStory] (structured setting/goal/twists fields
/// rendered in a multi-step flow), a scenario is one flowing [description]
/// paragraph containing the literal tokens [kCharacterATag] and
/// [kCharacterBTag], swapped for the couple's real session names at display
/// time. See `STORY_FORMAT_GUIDE.md` for the authoring format.
class RoleplayScenario implements ContentItem {
  const RoleplayScenario({
    required this.id,
    required this.title,
    required this.roleplayCategory,
    required this.difficulty,
    required this.roleA,
    required this.roleB,
    required this.description,
    required this.premium,
    required this.createdAt,
    this.twists = const [],
    this.favorite = false,
  });

  factory RoleplayScenario.fromJson(Map<String, Object?> json) =>
      RoleplayScenario(
        id: json['id']! as String,
        title: json['title']! as String,
        roleplayCategory: RoleplayCategory.values.byName(
          json['category']! as String,
        ),
        difficulty: Difficulty.values.byName(json['tier']! as String),
        roleA: json['roleA']! as String,
        roleB: json['roleB']! as String,
        description: json['description']! as String,
        twists: (json['twists'] as List<dynamic>?)?.cast<String>() ?? const [],
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

  /// Short in-world label for the first role (e.g. "The Hidden Host").
  final String roleA;

  /// Short in-world label for the second role (e.g. "The Curious Guest").
  final String roleB;

  /// Flowing narrative containing [kCharacterATag] / [kCharacterBTag].
  final String description;

  /// Optional bonus beats revealable one at a time during a scene.
  final List<String> twists;
  final bool premium;
  @override
  final DateTime createdAt;
  @override
  final bool favorite;

  /// Renders [description] with the tokens swapped for real player names.
  String describeFor({required String nameA, required String nameB}) =>
      description
          .replaceAll(kCharacterATag, nameA)
          .replaceAll(kCharacterBTag, nameB);

  RoleplayScenario copyWith({bool? favorite}) => RoleplayScenario(
    id: id,
    title: title,
    roleplayCategory: roleplayCategory,
    difficulty: difficulty,
    roleA: roleA,
    roleB: roleB,
    description: description,
    twists: twists,
    premium: premium,
    createdAt: createdAt,
    favorite: favorite ?? this.favorite,
  );
}
