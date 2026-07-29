import 'package:hive_ce/hive.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/session_repository.dart';

/// Hive implementation of the single-current-session repository.
class SessionRepositoryHive implements SessionRepository {
  SessionRepositoryHive(this.box);

  final Box<GameSession> box;
  static const currentKey = 'current';

  @override
  Future<AppResult<GameSession?>> load() async {
    try {
      return AppResult.success(box.get(currentKey));
    } on Object catch (error) {
      return AppResult.failure('Your game session could not be loaded.', error);
    }
  }

  @override
  Future<AppResult<void>> save(GameSession session) async {
    try {
      await box.put(currentKey, session);
      return const AppResult.success(null);
    } on Object catch (error) {
      return AppResult.failure('Your game session could not be saved.', error);
    }
  }
}
