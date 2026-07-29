import 'package:veloura/core/content_repository.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/models/difficulty.dart';

/// Roleplay story queries and persisted favorite operations.
abstract interface class RoleplayRepository
    implements ContentRepository<RoleplayStory> {
  Future<List<RoleplayStory>> getFiltered({
    RoleplayCategory? category,
    Difficulty? difficulty,
    required bool includePremium,
  });
}
