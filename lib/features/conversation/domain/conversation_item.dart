import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/content_item.dart';
import 'package:veloura/models/difficulty.dart';

/// Conversation Starter browse categories.
enum ConversationCategory { deep, funny, romantic, future, rediscover }

/// Immutable conversation prompt.
class ConversationItem implements ContentItem {
  const ConversationItem({
    required this.id,
    required this.prompt,
    required this.conversationCategory,
    required this.difficulty,
    required this.createdAt,
    this.favorite = false,
  });

  factory ConversationItem.fromJson(Map<String, Object?> json) =>
      ConversationItem(
        id: json['id']! as String,
        prompt: json['prompt']! as String,
        conversationCategory: ConversationCategory.values.byName(
          json['conversationCategory']! as String,
        ),
        difficulty: Difficulty.values.byName(json['difficulty']! as String),
        createdAt: DateTime.parse(json['createdAt']! as String),
      );

  @override
  final String id;
  final String prompt;
  final ConversationCategory conversationCategory;
  @override
  ContentCategory get category => switch (conversationCategory) {
    ConversationCategory.deep => ContentCategory.deepTalk,
    ConversationCategory.funny => ContentCategory.funny,
    ConversationCategory.romantic => ContentCategory.romance,
    ConversationCategory.future => ContentCategory.future,
    ConversationCategory.rediscover => ContentCategory.relationship,
  };
  @override
  final Difficulty difficulty;
  @override
  final DateTime createdAt;
  @override
  final bool favorite;

  ConversationItem copyWith({bool? favorite}) => ConversationItem(
    id: id,
    prompt: prompt,
    conversationCategory: conversationCategory,
    difficulty: difficulty,
    createdAt: createdAt,
    favorite: favorite ?? this.favorite,
  );
}
