import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/positions/domain/intimacy_position.dart';

/// Loads every bundled position illustration as playable card content.
abstract interface class PositionRepository {
  Future<AppResult<List<IntimacyPosition>>> loadAll();
}
