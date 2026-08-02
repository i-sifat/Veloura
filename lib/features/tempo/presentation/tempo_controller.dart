import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/tempo/domain/tempo_round.dart';

enum TempoStatus { idle, running, paused, complete }

/// Immutable state for one Follow the Tempo round of short tasks.
class TempoState {
  const TempoState({
    this.status = TempoStatus.idle,
    this.round = const [],
    this.taskIndex = 0,
    this.elapsedInTask = Duration.zero,
  });

  final TempoStatus status;

  /// The tasks for the current round, built when the round starts.
  final List<TempoTask> round;

  /// Index of the active task in [round].
  final int taskIndex;

  /// Time spent inside the current task.
  final Duration elapsedInTask;

  TempoTask? get currentTask =>
      taskIndex < round.length ? round[taskIndex] : null;

  bool get isFinale => taskIndex >= round.length;

  /// 0..1 how full the ring should be for the active task. Fills clockwise
  /// as time elapses and returns to zero when the next task begins.
  double get progress {
    final task = currentTask;
    if (task == null || task.duration <= Duration.zero) return 0;
    return (elapsedInTask.inMilliseconds / task.duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  /// Whole seconds remaining in the active task, for the ring center.
  int get secondsLeft {
    final task = currentTask;
    if (task == null) return 0;
    final remaining = task.duration - elapsedInTask;
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    return seconds < 0 ? 0 : seconds;
  }

  /// The tempo word shown on screen.
  String get instruction => currentTask?.label ?? 'SLOW';
}

/// Owns the round clock and exposes deterministic elapsed-time progression.
class TempoController extends Notifier<TempoState> {
  Timer? _timer;
  DateTime? _lastTick;
  Random? _random;

  @override
  TempoState build() {
    ref.onDispose(_cancelClock);
    return const TempoState();
  }

  /// Injects the RNG used to pick task durations. Public for deterministic
  /// unit tests.
  void setRandom(Random random) => _random = random;

  void start() {
    _cancelClock();
    state = TempoState(
      status: TempoStatus.running,
      round: buildTempoRound(random: _random),
    );
    _startClock();
  }

  void stop() {
    _cancelClock();
    state = const TempoState();
  }

  void pause() {
    if (state.status != TempoStatus.running) return;
    _cancelClock();
    state = TempoState(
      status: TempoStatus.paused,
      round: state.round,
      taskIndex: state.taskIndex,
      elapsedInTask: state.elapsedInTask,
    );
  }

  void resume() {
    if (state.status != TempoStatus.paused) return;
    state = TempoState(
      status: TempoStatus.running,
      round: state.round,
      taskIndex: state.taskIndex,
      elapsedInTask: state.elapsedInTask,
    );
    _startClock();
  }

  /// Advances the round by [delta]. Public for deterministic unit tests.
  void advance(Duration delta) {
    if (state.status != TempoStatus.running || delta <= Duration.zero) return;
    final round = state.round;
    var taskIndex = state.taskIndex;
    var elapsed = state.elapsedInTask;
    var remaining = delta;

    while (taskIndex < round.length) {
      final task = round[taskIndex];
      final left = task.duration - elapsed;
      if (remaining < left) {
        elapsed += remaining;
        break;
      }
      remaining -= left;
      taskIndex += 1;
      elapsed = Duration.zero;
    }

    if (taskIndex >= round.length) {
      _cancelClock();
      state = TempoState(
        status: TempoStatus.complete,
        round: round,
        taskIndex: round.length,
      );
      return;
    }

    state = TempoState(
      status: TempoStatus.running,
      round: round,
      taskIndex: taskIndex,
      elapsedInTask: elapsed,
    );
  }

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
}

final tempoControllerProvider =
    NotifierProvider.autoDispose<TempoController, TempoState>(
      TempoController.new,
    );
