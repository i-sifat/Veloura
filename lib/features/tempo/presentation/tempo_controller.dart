import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/tempo/domain/tempo_round.dart';

enum TempoStatus { idle, running, paused, complete }

/// Immutable in-memory state for one pacing round.
class TempoState {
  const TempoState({
    this.status = TempoStatus.idle,
    this.elapsed = Duration.zero,
    this.stageIndex = 0,
    this.beatCount = 0,
    this.instruction = 'SLOW',
  });

  final TempoStatus status;
  final Duration elapsed;
  final int stageIndex;
  final int beatCount;
  final String instruction;

  bool get isFinale => stageIndex == kDefaultRound.length;
}

/// Owns the round clock and exposes deterministic elapsed-time progression.
class TempoController extends Notifier<TempoState> {
  Timer? _timer;
  DateTime? _lastTick;

  @override
  TempoState build() {
    ref.onDispose(_cancelClock);
    return const TempoState();
  }

  void start() {
    _cancelClock();
    state = _stateFor(Duration.zero, TempoStatus.running);
    _startClock();
  }

  void stop() {
    _cancelClock();
    state = const TempoState();
  }

  void pause() {
    if (state.status != TempoStatus.running) return;
    _cancelClock();
    state = _stateFor(state.elapsed, TempoStatus.paused);
  }

  void resume() {
    if (state.status != TempoStatus.paused) return;
    state = _stateFor(state.elapsed, TempoStatus.running);
    _startClock();
  }

  /// Advances the round by [delta]. Public for deterministic unit tests.
  void advance(Duration delta) {
    if (state.status != TempoStatus.running || delta <= Duration.zero) return;
    final total = _roundLength + kTempoFinaleLength;
    final elapsed = state.elapsed + delta;
    if (elapsed >= total) {
      _cancelClock();
      state = _stateFor(total, TempoStatus.complete);
      return;
    }
    state = _stateFor(elapsed, TempoStatus.running);
  }

  Duration get _roundLength => kDefaultRound.fold(
    Duration.zero,
    (total, stage) => total + stage.length,
  );

  void _startClock() {
    _lastTick = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 25), (_) {
      final now = DateTime.now();
      final previous = _lastTick ?? now;
      _lastTick = now;
      advance(now.difference(previous));
    });
  }

  void _cancelClock() {
    _timer?.cancel();
    _timer = null;
    _lastTick = null;
  }

  TempoState _stateFor(Duration elapsed, TempoStatus status) {
    var cursor = Duration.zero;
    var completedBeats = 0;
    for (var index = 0; index < kDefaultRound.length; index++) {
      final stage = kDefaultRound[index];
      final end = cursor + stage.length;
      if (elapsed < end) {
        final local = elapsed - cursor;
        final beats = local.inMicroseconds * stage.bpm ~/
            Duration.microsecondsPerMinute;
        final instruction = local < kTempoFocusLength
            ? kTempoFocusWords[index % kTempoFocusWords.length]
            : stage.label;
        return TempoState(
          status: status,
          elapsed: elapsed,
          stageIndex: index,
          beatCount: completedBeats + beats,
          instruction: instruction,
        );
      }
      completedBeats += stage.length.inMicroseconds * stage.bpm ~/
          Duration.microsecondsPerMinute;
      cursor = end;
    }
    return TempoState(
      status: status,
      elapsed: elapsed,
      stageIndex: kDefaultRound.length,
      beatCount: completedBeats,
      instruction: 'HOLD',
    );
  }
}

final tempoControllerProvider =
    NotifierProvider.autoDispose<TempoController, TempoState>(
      TempoController.new,
    );
