import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/premium/provider.dart';
import 'package:veloura/features/truth_dare/domain/truth_dare_item.dart';
import 'package:veloura/features/truth_dare/domain/truth_dare_repository.dart';
import 'package:veloura/features/truth_dare/presentation/truth_dare_controller.dart';
import 'package:veloura/models/difficulty.dart';

/// Injectable random source for deterministic wheel tests.
final wheelRandomProvider = Provider<Random>((ref) => Random());

/// Pure landing calculations shared by animation and tests.
abstract final class WheelMath {
  static const segmentCount = 10;
  static const segmentDegrees = 360 / segmentCount;

  static double endDegrees({required int target, required int turns}) {
    assert(target >= 0 && target < segmentCount);
    final centre = target * segmentDegrees + segmentDegrees / 2;
    return turns * 360 + (360 - centre);
  }

  /// Like [endDegrees], but always measured forward from [currentDegrees]
  /// instead of from zero. Guarantees the result is strictly greater than
  /// [currentDegrees] (plus at least [turns] full revolutions), so animating
  /// from `currentDegrees` to this value can only ever spin clockwise -
  /// never backward - no matter how many spins came before it.
  static double nextEndDegrees({
    required double currentDegrees,
    required int target,
    required int turns,
  }) {
    assert(target >= 0 && target < segmentCount);
    assert(turns >= 1);
    final centre = target * segmentDegrees + segmentDegrees / 2;
    final targetMod = (360 - centre) % 360;
    final currentMod = currentDegrees % 360;
    var forwardDelta = targetMod - currentMod;
    if (forwardDelta <= 0) forwardDelta += 360;
    return currentDegrees + forwardDelta + turns * 360;
  }

  static int targetForEndDegrees(double degrees) {
    final normalized = degrees % 360;
    final clockwiseFromPointer = (360 - normalized) % 360;
    return (clockwiseFromPointer / segmentDegrees).floor() % segmentCount;
  }

  static TruthDareKind kindForTarget(int target) =>
      target.isEven ? TruthDareKind.dare : TruthDareKind.truth;
}

/// Current roulette round.
class WheelState {
  const WheelState({
    this.target = 0,
    this.turns = 7,
    this.endDegrees = 0,
    this.spinning = false,
    this.item,
  });

  final int target;
  final int turns;
  final double endDegrees;
  final bool spinning;
  final TruthDareItem? item;

  TruthDareKind get kind => WheelMath.kindForTarget(target);

  WheelState copyWith({
    int? target,
    int? turns,
    double? endDegrees,
    bool? spinning,
    TruthDareItem? Function()? item,
  }) => WheelState(
    target: target ?? this.target,
    turns: turns ?? this.turns,
    endDegrees: endDegrees ?? this.endDegrees,
    spinning: spinning ?? this.spinning,
    item: item == null ? this.item : item(),
  );
}

/// Selects wheel outcomes while preserving the existing content repository.
class WheelController extends AsyncNotifier<WheelState> {
  late TruthDareRepository _repository;
  late Random _random;
  final List<String> _recentIds = [];

  @override
  Future<WheelState> build() async {
    _repository = await ref.watch(truthDareRepositoryProvider.future);
    _random = ref.watch(wheelRandomProvider);
    return const WheelState();
  }

  /// Chooses a segment and exact axis-aligned landing angle.
  void prepareSpin() {
    final current = state.asData?.value;
    if (current == null || current.spinning) return;
    final target = _random.nextInt(WheelMath.segmentCount);
    final turns = 7 + _random.nextInt(4);
    final end = WheelMath.endDegrees(target: target, turns: turns);
    assert(WheelMath.targetForEndDegrees(end) == target);
    state = AsyncData(
      current.copyWith(
        target: target,
        turns: turns,
        endDegrees: end,
        spinning: true,
        item: () => null,
      ),
    );
  }

  /// Draws a prompt matching the Truth or Dare segment where the wheel landed.
  Future<void> resolvePrompt() async {
    final current = state.asData?.value;
    if (current == null) return;
    final result = await _repository.getAll();
    switch (result) {
      case AppSuccess<List<TruthDareItem>>(:final value):
        final premium = ref.read(isPremiumProvider);
        var pool = value
            .where((item) => item.kind == current.kind)
            .where((item) => premium || item.difficulty != Difficulty.extreme)
            .where((item) => !_recentIds.contains(item.id))
            .toList();
        if (pool.isEmpty) {
          _recentIds.clear();
          pool = value
              .where((item) => item.kind == current.kind)
              .where((item) => premium || item.difficulty != Difficulty.extreme)
              .toList();
        }
        if (pool.isEmpty) throw StateError('No matching prompts');
        final item = pool[_random.nextInt(pool.length)];
        _recentIds
          ..add(item.id)
          ..removeRange(0, max(0, _recentIds.length - 12));
        state = AsyncData(current.copyWith(spinning: false, item: () => item));
      case AppFailure<List<TruthDareItem>>(:final message, :final cause):
        state = AsyncError(message, StackTrace.fromString('$cause'));
    }
  }

  Future<void> complete() async {
    final item = state.asData?.value.item;
    if (item != null) await _repository.markCompleted(item.id);
  }

  Future<void> skip() => resolvePrompt();

  Future<void> toggleFavorite() async {
    final current = state.asData?.value;
    final item = current?.item;
    if (current == null || item == null) return;
    final result = await _repository.toggleFavorite(item.id);
    if (result case AppSuccess<TruthDareItem>(:final value)) {
      state = AsyncData(current.copyWith(item: () => value));
    }
  }
}

final wheelControllerProvider =
    AsyncNotifierProvider<WheelController, WheelState>(WheelController.new);
