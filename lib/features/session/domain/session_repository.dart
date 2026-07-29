import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/session/domain/game_session.dart';

/// Storage boundary for the current shared game session.
abstract interface class SessionRepository {
  Future<AppResult<GameSession?>> load();
  Future<AppResult<void>> save(GameSession session);
}
