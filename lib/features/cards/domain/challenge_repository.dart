import 'package:veloura/core/content_repository.dart';
import 'package:veloura/features/cards/domain/challenge_item.dart';

/// Persisted state attached to a challenge card.
class ChallengeProgress {
  const ChallengeProgress({
    required this.status,
    this.reflection,
    this.completedAt,
  });

  final ChallengeStatus status;
  final String? reflection;
  final DateTime? completedAt;
}

/// Challenge-specific data operations.
abstract interface class ChallengeRepository
    implements ContentRepository<ChallengeItem> {
  Future<Map<String, ChallengeProgress>> getProgress();
  Future<void> setProgress(String id, ChallengeProgress progress);
  Future<int> getRewardBalance();
}
