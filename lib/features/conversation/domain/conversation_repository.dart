import 'package:veloura/core/content_repository.dart';
import 'package:veloura/features/conversation/domain/conversation_item.dart';

/// Conversation-specific persisted state operations.
abstract interface class ConversationRepository
    implements ContentRepository<ConversationItem> {
  Future<Map<String, DateTime>> getAnswered();
  Future<void> markAnswered(String id, DateTime timestamp);
  Future<List<String>> getRecentIds();
  Future<void> setRecentIds(List<String> ids);
}
