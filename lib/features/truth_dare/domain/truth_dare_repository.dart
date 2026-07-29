import 'package:veloura/core/content_repository.dart';
import 'package:veloura/features/truth_dare/domain/truth_dare_item.dart';

/// Truth or Dare-specific repository contract.
abstract interface class TruthDareRepository
    implements ContentRepository<TruthDareItem> {
  Future<Set<String>> getCompletedIds();
  Future<void> markCompleted(String id);
}
