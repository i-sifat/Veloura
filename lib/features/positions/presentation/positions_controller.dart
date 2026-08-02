import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/positions/data/position_repository_asset.dart';
import 'package:veloura/features/positions/domain/heat_ladder.dart';
import 'package:veloura/features/positions/domain/intimacy_position.dart';
import 'package:veloura/features/positions/domain/position_repository.dart';
import 'package:veloura/features/positions/domain/position_zone.dart';
import 'package:veloura/features/positions/domain/session_intensity.dart';
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
    this.sessionSeconds = 0,
    this.elapsedInSession = Duration.zero,
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

  /// Total length of the active position session, in seconds.
  final int sessionSeconds;

  /// Time already spent inside the active position session.
  final Duration elapsedInSession;

  final PositionZone? zone;
  final IntimacyPosition? position;
  final DateTime? cooldownEndsAt;

  /// Intensity of the active session, chosen by the current heat.
  PositionSessionIntensity get sessionIntensity =>
      PositionSessionIntensity.forHeat(heat);

  /// 0..1 how full the timer ring should be. Fills clockwise as the
  /// session elapses and resets for the next round.
  double get sessionProgress {
    if (sessionSeconds <= 0) return 0;
    return (elapsedInSession.inMilliseconds /
            (sessionSeconds * Duration.millisecondsPerSecond))
        .clamp(0.0, 1.0);
  }

  /// Whole seconds remaining in the active session, for the ring center.
  int get sessionSecondsLeft {
    if (sessionSeconds <= 0) return 0;
    final remaining = Duration(seconds: sessionSeconds) - elapsedInSession;
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    return seconds < 0 ? 0 : seconds;
  }

  PositionsRoundState copyWith({
    RoundStage? stage,
    int? turns,
    int? completedRounds,
    int? heat,
    int? sessionSeconds,
    Duration? elapsedInSession,
    PositionZone? Function()? zone,
    IntimacyPosition? Function()? position,
    DateTime? Function()? cooldownEndsAt,
  }) => PositionsRoundState(
    catalog: catalog,
    stage: stage ?? this.stage,
    turns: turns ?? this.turns,
    completedRounds: completedRounds ?? this.completedRounds,
    heat: heat ?? this.heat,
    sessionSeconds: sessionSeconds ?? this.sessionSeconds,
    elapsedInSession: elapsedInSession ?? this.elapsedInSession,
    zone: zone == null ? this.zone : zone(),
    position: position == null ? this.position : position(),
    cooldownEndsAt: cooldownEndsAt == null
        ? this.cooldownEndsAt
        : cooldownEndsAt(),
  );
}

/// Coordinates the dial, held reveal, dynamic image card and timed session.
class PositionsController extends AsyncNotifier<PositionsRoundState> {
  late Random _random;
  Timer? _clock;
  DateTime? _lastTick;
  var _paused = false;
  final Map<PositionZone, Set<String>> _used = {
    for (final zone in PositionZone.values) zone: <String>{},
  };

  @override
  Future<PositionsRoundState> build() async {
    ref.onDispose(_cancelClock);
    _random = ref.watch(positionsRandomProvider);
    final result = await ref.watch(positionRepositoryProvider).loadAll();
    final catalog = switch (result) {
      AppSuccess<List<IntimacyPosition>>(:final value) => value,
      AppFailure<List<IntimacyPosition>>(:final message) => throw StateError(
        message,
      ),
    };
    return PositionsRoundState(
      catalog: catalog,
      stage: RoundStage.invite,
      turns: 0,
      completedRounds: 0,
      heat: 1,
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
      current.copyWith(stage: RoundStage.revealed, position: () => position),
    );
  }

  /// Free pass: redraws in the same zone without changing turns.
  void pass() {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(stage: RoundStage.held, position: () => null),
    );
  }

  /// Starts the timed session for the revealed position. The ring fills
  /// clockwise over [PositionsRoundState.sessionSeconds] while the clock
  /// runs; the round finishes on its own when time runs out.
  void enterTempo() {
    final current = state.requireValue;
    _cancelClock();
    _paused = false;
    state = AsyncData(
      current.copyWith(
        stage: RoundStage.tempo,
        sessionSeconds: positionSessionSeconds(current.heat),
        elapsedInSession: Duration.zero,
      ),
    );
    _startClock();
  }

  /// Advances the active session by [delta]. Public for deterministic
  /// unit tests.
  void advanceSession(Duration delta) {
    final current = state.requireValue;
    if (current.stage != RoundStage.tempo || delta <= Duration.zero) return;
    if (_paused) return;
    final elapsed = current.elapsedInSession + delta;
    if (elapsed >= Duration(seconds: current.sessionSeconds)) {
      finishRound();
      return;
    }
    state = AsyncData(current.copyWith(elapsedInSession: elapsed));
  }

  /// Ends the session early; the couple calls it when they're done.
  void finishSession() {
    final current = state.requireValue;
    if (current.stage != RoundStage.tempo) return;
    finishRound();
  }

  /// Pauses the session clock without losing progress, for app
  /// backgrounding. Call [resumeSession] to pick up where it left off.
  void pauseSession() {
    final current = state.requireValue;
    if (current.stage != RoundStage.tempo) return;
    _paused = true;
    _cancelClock();
  }

  void resumeSession() {
    final current = state.requireValue;
    if (current.stage != RoundStage.tempo || !_paused) return;
    _paused = false;
    _startClock();
  }

  /// Completes the round; the screen advances the shared player turn once.
  void finishRound() {
    _cancelClock();
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
    _cancelClock();
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        stage: RoundStage.invite,
        zone: () => null,
        position: () => null,
        sessionSeconds: 0,
        elapsedInSession: Duration.zero,
        cooldownEndsAt: () => null,
      ),
    );
  }

  void _startClock() {
    _lastTick = DateTime.now();
    _clock = Timer.periodic(const Duration(milliseconds: 25), (_) {
      final now = DateTime.now();
      final previous = _lastTick ?? now;
      _lastTick = now;
      advanceSession(now.difference(previous));
    });
  }

  void _cancelClock() {
    _clock?.cancel();
    _clock = null;
    _lastTick = null;
  }
}

final positionsControllerProvider =
    AsyncNotifierProvider<PositionsController, PositionsRoundState>(
      PositionsController.new,
    );
