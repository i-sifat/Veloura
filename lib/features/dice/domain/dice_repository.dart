import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/dice/domain/dice_roll_record.dart';

/// Persisted custom face configuration.
class DiceFaceSet {
  const DiceFaceSet({required this.actions, required this.bodies});

  final List<String> actions;
  final List<String> bodies;
}

/// Data boundary for Dice history and premium face sets.
abstract interface class DiceRepository {
  Future<AppResult<List<DiceRollRecord>>> getHistory();
  Future<AppResult<DiceRollRecord>> saveRoll(DiceRollRecord record);
  Future<AppResult<DiceRollRecord>> toggleFavorite(String id);
  Future<AppResult<DiceFaceSet?>> getCustomFaces();
  Future<AppResult<DiceFaceSet>> saveCustomFaces(DiceFaceSet faces);
}
