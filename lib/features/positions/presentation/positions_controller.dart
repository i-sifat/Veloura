import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/positions/data/position_repository_asset.dart';
import 'package:veloura/features/positions/domain/heat_ladder.dart';
import 'package:veloura/features/positions/domain/intimacy_position.dart';
import 'package:veloura/features/positions/domain/position_repository.dart';
import 'package:veloura/features/positions/domain/position_zone.dart';
import 'package:veloura/features/positions/domain/tempo_beat.dart';
import 'package:veloura/features/premium/provider.dart';

/// Physical stages of one Creative Positions round.
enum RoundStage { invite, spinning, held, revealed, tempo, cooldown }

/// Injectable randomness for deterministic tests.
final positionsRandomProvider = Provider<Random>((ref) => Random());

final positionRepositoryProvider = Provider<PositionRepository>(
  (ref) => PositionRepositoryAsset(),
);

/// Pure landing calculations for the zone wheel, inherited 1:1 from the
/// Truth or Dare `WheelMath` (see
/// `features/truth_dare/presentation/wheel/wheel_controller.dart`), just
/// parameterized by [zoneCount] instead of a fixed 10 segments.
abstract final class PositionWheelMath {
  static double segmentDegrees(int zoneCount) => 360 / zoneCount;

  /// Landing angle measured from zero. Kept for parity with the Truth or
  /// Dare math and for direct unit testing; the screen uses
  /// [nextEndDegrees] to animate.
  static double endDegrees({
    required int target,
    required int turns,
    required int zoneCount,
  }) {
    assert(target >= 0 && target < zoneCount);
    final segment = segmentDegrees(zoneCount);
    final centre = target * segment + segment / 2;
    return turns * 360 + (360 - centre);
  }

  /// Like [endDegrees], but always measured forward from [currentDegrees]
  /// instead of from zero. Guarantees the result is strictly greater than
  /// [currentDegrees] (plus at least [turns] full revolutions), so
  /// animating from `currentDegrees` to this value can only ever spin
  /// clockwise - never backward or in place - no matter how many spins
  /// came before it.
  static double nextEndDegrees({
    required double currentDegrees,
    required int target,
    required int turns,
    required int zoneCount,
  }) {
    assert(target >= 0 && target < zoneCount);
    assert(turns >= 1);
    final segment = segmentDegrees(zoneCount);
    final centre = target * segment + segment / 2;
    final targetMod = (360 - centre) % 360;
    final currentMod = currentDegrees % 360;
    var forwardDelta = targetMod - currentMod;
    if (forwardDelta <= 0) forwardDelta += 360;
    return currentDegrees + forwardDelta + turns * 360;
  }

  static int targetForEndDegrees(double degrees, int zoneCount) {
    final segment = segmentDegrees(zoneCount);
    final normalized = degrees % 360;
    final clockwiseFromPointer = (360 - normalized) % 360;
    return (clockwiseFromPointer / segment).floor() % zoneCount;
  }
}

/// Immutable round state rendered by the dynamic card surface.
class PositionsRoundState {
  const PositionsRoundState({
    required this.catalog,
    required this.stage,
    required this.turns,
    required this.completedRounds,
    required this.heat,
    required this.beats,
    required this.beatIndex,
    this.zone,
    this.position,
    this.cooldownEndsAt,
  });

  final List<IntimacyPosition> catalog;
  final RoundStage stage;

  /// Number of full revolutions the current/last spin travels.
  final int turns;
  final int completedRounds;
  final int heat;
  final List<TempoBeat> beats;
  final int beatIndex;
  final PositionZone? zone;
  final IntimacyPosition? position;
  final DateTime? cooldownEndsAt;

  TempoBeat? get currentBeat => beats.isEmpty ? null : beats[beatIndex];

  PositionsRoundState copyWith({
    RoundStage? stage,
    int? turns,
    int? completedRounds,
    int? heat,
    List<TempoBeat>? beats,
    int? beatIndex,
    PositionZone? Function()? zone,
    IntimacyPosition? Function()? position,
    DateTime? Function()? cooldownEndsAt,
  }) => PositionsRoundState(
    catalog: catalog,
    stage: stage ?? this.stage,
    turns: turns ?? this.turns,
    completedRounds: completedRounds ?? this.completedRounds,
    heat: heat ?? this.heat,
    beats: beats ?? this.beats,
    beatIndex: beatIndex ?? this.beatIndex,
    zone: zone == null ? this.zone : zone(),
    position: position == null ? this.position : position(),
    cooldownEndsAt: cooldownEndsAt == null
        ? this.cooldownEndsAt
        : cooldownEndsAt(),
  );
}

/// Coordinates the dial, held reveal, dynamic image card and beat rail.
class PositionsController extends AsyncNotifier<PositionsRoundState> {
  late Random _random;
  final Map<PositionZone, Set<String>> _used = {
    for (final zone in PositionZone.values) zone: <String>{},
  };

  @override
  Future<PositionsRoundState> build() async {
    _random = ref.watch(positionsRandomProvider);
    final result = await ref.watch(positionRepositoryProvider).loadAll();
    final catalog = switch (result) {
      AppSuccess<List<IntimacyPosition>>(:final value) => value,
      AppFailure<List<IntimacyPosition>>(:final message) =>
        throw StateError(message),
    };
    return PositionsRoundState(
      catalog: catalog,
      stage: RoundStage.invite,
      turns: 0,
      completedRounds: 0,
      heat: 1,
      beats: const [],
      beatIndex: 0,
    );
  }

  /// Picks a fair landing zone and a random turn count, inherited 1:1 from
  /// Truth or Dare's `WheelController.prepareSpin()`. The screen reads
  /// [PositionsRoundState.zone] and [PositionsRoundState.turns] straight
  /// back off state to drive its own [PositionWheelMath.nextEndDegrees]
  /// animation, exactly like the Truth or Dare wheel screen does.
  void beginSpin() {
    final current = state.requireValue;
    if (current.stage == RoundStage.spinning) return;
    final premium = ref.read(isPremiumProvider);
    final zoneCount = premium ? 6 : 5;
    final turns = 3 + _random.nextInt(3);
    final target = _random.nextInt(zoneCount);
    state = AsyncData(
      current.copyWith(
        stage: RoundStage.spinning,
        turns: turns,
        zone: () => PositionZone.values[target],
        position: () => null,
      ),
    );
  }

  /// Moves from the settled dial to the face-down card.
  void finishSpin() {
    final current = state.requireValue;
    if (current.stage == RoundStage.spinning) {
      state = AsyncData(current.copyWith(stage: RoundStage.held));
    }
  }

  /// Draws an unused image-backed position in the landed zone.
  void reveal() {
    final current = state.requireValue;
    final zone = current.zone;
    if (zone == null) return;
    final premium = ref.read(isPremiumProvider);
    var eligible = current.catalog
        .where((item) => item.zone == zone)
        .where((item) => item.heatMin <= current.heat)
        .where((item) => premium || !item.isPremium)
        .where((item) => !_used[zone]!.contains(item.id))
        .toList();
    if (eligible.isEmpty) {
      _used[zone]!.clear();
      eligible = current.catalog
          .where((item) => item.zone == zone)
          .where((item) => premium || !item.isPremium)
          .toList();
    }
    if (eligible.isEmpty) return;
    final position = eligible[_random.nextInt(eligible.length)];
    _used[zone]!.add(position.id);
    state = AsyncData(
      current.copyWith(
        stage: RoundStage.revealed,
        position: () => position,
      ),
    );
  }

  /// Free pass: redraws in the same zone without changing turns.
  void pass() {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(stage: RoundStage.held, position: () => null),
    );
  }

  /// Creates a compact stateful tempo script from the current heat.
  void enterTempo() {
    final current = state.requireValue;
    final beatCount = current.heat <= 1 ? 2 : (current.heat <= 3 ? 3 : 4);
    final labels = ['SLOW', 'TEASE', 'DEEP', 'HOLD'];
    final beats = <TempoBeat>[
      for (var index = 0; index < beatCount; index++)
        TempoBeat(
          label: labels[index % labels.length],
          count: 3 + current.heat + index * 2,
        ),
      const TempoBeat(label: 'Stay close together.'),
    ];
    state = AsyncData(
      current.copyWith(
        stage: RoundStage.tempo,
        beats: beats,
        beatIndex: 0,
      ),
    );
  }

  void advanceBeat() {
    final current = state.requireValue;
    if (current.stage != RoundStage.tempo || current.beats.isEmpty) return;
    if (current.beatIndex < current.beats.length - 1) {
      state = AsyncData(current.copyWith(beatIndex: current.beatIndex + 1));
    }
  }

  /// Completes the round; the screen advances the shared player turn once.
  void finishRound() {
    final current = state.requireValue;
    final completed = current.completedRounds + 1;
    state = AsyncData(
      current.copyWith(
        stage: RoundStage.cooldown,
        completedRounds: completed,
        heat: heatFor(
          completed,
          premium: ref.read(isPremiumProvider),
          softened: false,
        ),
        cooldownEndsAt: () => DateTime.now().add(const Duration(seconds: 8)),
      ),
    );
  }

  void restart() {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        stage: RoundStage.invite,
        zone: () => null,
        position: () => null,
        beats: const [],
        beatIndex: 0,
        cooldownEndsAt: () => null,
      ),
    );
  }
}

final positionsControllerProvider =
    AsyncNotifierProvider<PositionsController, PositionsRoundState>(
      PositionsController.new,
    );
