import 'package:hive_ce/hive.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/dice/domain/dice_repository.dart';
import 'package:veloura/features/dice/domain/dice_roll_record.dart';

/// Hive-backed implementation of the Dice data boundary.
class HiveDiceRepository implements DiceRepository {
  HiveDiceRepository({required this.historyBox, required this.settingsBox});

  final Box<DiceRollRecord> historyBox;
  final Box<String> settingsBox;

  static const _actionsKey = 'custom_actions';
  static const _bodiesKey = 'custom_bodies';
  static const _separator = '\u001F';

  Future<AppResult<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return AppResult.success(await operation());
    } on Object catch (error) {
      return AppResult.failure('Dice data could not be saved.', error);
    }
  }

  @override
  Future<AppResult<List<DiceRollRecord>>> getHistory() => _guard(() async {
    final records = historyBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(records);
  });

  @override
  Future<AppResult<DiceRollRecord>> saveRoll(DiceRollRecord record) =>
      _guard(() async {
        await historyBox.put(record.id, record);
        return record;
      });

  @override
  Future<AppResult<DiceRollRecord>> toggleFavorite(String id) => _guard(() async {
    final record = historyBox.get(id);
    if (record == null) throw StateError('Unknown roll: $id');
    final updated = record.copyWith(favorite: !record.favorite);
    await historyBox.put(id, updated);
    return updated;
  });

  @override
  Future<AppResult<DiceFaceSet?>> getCustomFaces() => _guard(() async {
    final actions = settingsBox.get(_actionsKey);
    final bodies = settingsBox.get(_bodiesKey);
    if (actions == null || bodies == null) return null;
    return DiceFaceSet(
      actions: actions.split(_separator),
      bodies: bodies.split(_separator),
    );
  });

  @override
  Future<AppResult<DiceFaceSet>> saveCustomFaces(DiceFaceSet faces) =>
      _guard(() async {
        await settingsBox.put(_actionsKey, faces.actions.join(_separator));
        await settingsBox.put(_bodiesKey, faces.bodies.join(_separator));
        return faces;
      });
}
