import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/dice/data/hive_dice_repository.dart';
import 'package:veloura/features/dice/domain/dice_repository.dart';
import 'package:veloura/features/dice/domain/dice_roll_record.dart';
import 'package:veloura/features/dice/presentation/dice_state.dart';
import 'package:veloura/services/storage_service.dart';

const _defaultActions = [
  'Kiss',
  'Trace',
  'Whisper to',
  'Compliment',
  'Massage',
  'Hold',
];
const _defaultBodies = [
  'their hand',
  'their cheek',
  'their shoulder',
  'their forehead',
  'their neck',
  'their back',
];
const _defaultExtras = [
  'for 10 seconds',
  'gently',
  'with eyes closed',
  'until they smile',
  'slowly',
  'with a compliment',
];

/// Dice repository dependency.
final diceRepositoryProvider = FutureProvider<DiceRepository>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return HiveDiceRepository(
    historyBox: await storage.box<DiceRollRecord>('dice_history'),
    settingsBox: await storage.box<String>('dice_settings'),
  );
});

/// Injectable random source for deterministic tests.
final diceRandomProvider = Provider<Random>((ref) => Random.secure());

/// Coordinates Dice rolls, history, favorites, and custom sets.
class DiceController extends AsyncNotifier<DiceState> {
  late DiceRepository _repository;
  late Random _random;

  @override
  Future<DiceState> build() async {
    _repository = await ref.watch(diceRepositoryProvider.future);
    _random = ref.watch(diceRandomProvider);
    final historyResult = await _repository.getHistory();
    final customResult = await _repository.getCustomFaces();
    final history = switch (historyResult) {
      AppSuccess<List<DiceRollRecord>>(:final value) => value,
      AppFailure<List<DiceRollRecord>>() => <DiceRollRecord>[],
    };
    final custom = switch (customResult) {
      AppSuccess<DiceFaceSet?>(:final value) => value,
      AppFailure<DiceFaceSet?>() => null,
    };
    return DiceState(
      status: history.isEmpty ? DiceRollStatus.idle : DiceRollStatus.result,
      current: history.firstOrNull,
      history: history,
      actions: custom?.actions ?? _defaultActions,
      bodies: custom?.bodies ?? _defaultBodies,
      extras: _defaultExtras,
      customFacesEnabled: custom != null,
    );
  }

  /// Rolls all enabled dice and persists the result.
  Future<void> roll({Duration animationDuration = const Duration(milliseconds: 720)}) async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.status == DiceRollStatus.rolling) return;
    state = AsyncData(currentState.copyWith(status: DiceRollStatus.rolling));
    await Future<void>.delayed(animationDuration);
    final active = state.valueOrNull ?? currentState;
    final timestamp = DateTime.now();
    final record = DiceRollRecord(
      id: '${timestamp.microsecondsSinceEpoch}',
      action: active.actions[_random.nextInt(active.actions.length)],
      body: active.bodies[_random.nextInt(active.bodies.length)],
      extra: active.useThirdDie
          ? active.extras[_random.nextInt(active.extras.length)]
          : null,
      createdAt: timestamp,
    );
    final saved = await _repository.saveRoll(record);
    switch (saved) {
      case AppSuccess<DiceRollRecord>(:final value):
        state = AsyncData(
          active.copyWith(
            status: DiceRollStatus.result,
            current: value,
            history: [value, ...active.history],
          ),
        );
      case AppFailure<DiceRollRecord>(:final message, :final cause):
        state = AsyncError(message, StackTrace.fromString('$cause'));
    }
  }

  /// Enables or disables the optional third die.
  void setThirdDie(bool enabled) {
    final current = state.valueOrNull;
    if (current != null) state = AsyncData(current.copyWith(useThirdDie: enabled));
  }

  /// Opens a historical result in the main result area.
  void selectRecord(DiceRollRecord record) {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current.copyWith(status: DiceRollStatus.result, current: record),
      );
    }
  }

  /// Persists custom action and body faces and enables the custom set.
  Future<void> saveCustomFaces(List<String> actions, List<String> bodies) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final faces = DiceFaceSet(
      actions: _clean(actions, _defaultActions),
      bodies: _clean(bodies, _defaultBodies),
    );
    final saved = await _repository.saveCustomFaces(faces);
    if (saved case AppSuccess<DiceFaceSet>(:final value)) {
      state = AsyncData(
        current.copyWith(
          actions: value.actions,
          bodies: value.bodies,
          customFacesEnabled: true,
        ),
      );
    }
  }

  /// Toggles a persisted roll favorite.
  Future<void> toggleFavorite(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final result = await _repository.toggleFavorite(id);
    if (result case AppSuccess<DiceRollRecord>(:final value)) {
      final history = [
        for (final record in current.history)
          if (record.id == value.id) value else record,
      ];
      state = AsyncData(
        current.copyWith(
          history: history,
          current: current.current?.id == value.id ? value : current.current,
        ),
      );
    }
  }

  static List<String> _clean(List<String> values, List<String> fallback) {
    final cleaned = values.map((value) => value.trim()).where((value) => value.isNotEmpty).toSet().toList();
    return cleaned.length >= 2 ? cleaned : fallback;
  }
}

/// Dice flow state.
final diceControllerProvider =
    AsyncNotifierProvider<DiceController, DiceState>(DiceController.new);
