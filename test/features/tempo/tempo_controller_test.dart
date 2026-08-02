import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/session_repository.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/features/tempo/domain/tempo_round.dart';
import 'package:veloura/features/tempo/presentation/follow_the_tempo_screen.dart';
import 'package:veloura/features/tempo/presentation/tempo_controller.dart';
import 'package:veloura/theme/app_theme.dart';

class _MemoryRepository implements SessionRepository {
  GameSession? value;

  @override
  Future<AppResult<GameSession?>> load() async => AppResult.success(value);

  @override
  Future<AppResult<void>> save(GameSession session) async {
    value = session;
    return const AppResult.success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'game_vibration': false});
  });

  test('start builds a round of short tasks with randomized durations', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(tempoControllerProvider.notifier);
    controller.setRandom(Random(7));

    controller.start();

    final state = container.read(tempoControllerProvider);
    expect(state.status, TempoStatus.running);
    expect(state.round.length, kTempoTaskCount);
    for (final task in state.round) {
      expect(task.duration, greaterThanOrEqualTo(const Duration(seconds: 15)));
      expect(task.duration, lessThanOrEqualTo(const Duration(seconds: 25)));
    }
    expect(state.taskIndex, 0);
    expect(state.progress, 0);
  });

  test('ring progress fills as a task elapses', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(tempoControllerProvider.notifier);
    controller.setRandom(Random(7));

    controller.start();
    final first = container.read(tempoControllerProvider).currentTask!;
    controller.advance(first.duration ~/ 2);

    final state = container.read(tempoControllerProvider);
    expect(state.taskIndex, 0);
    expect(state.progress, closeTo(0.5, 0.01));
    expect(state.secondsLeft, first.duration.inSeconds ~/ 2);
  });

  test('completing a task resets the ring and advances the next', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(tempoControllerProvider.notifier);
    controller.setRandom(Random(7));

    controller.start();
    final first = container.read(tempoControllerProvider).currentTask!;
    controller.advance(first.duration);

    final state = container.read(tempoControllerProvider);
    expect(state.taskIndex, 1);
    expect(state.progress, 0);
  });

  test('round completes after every task elapses', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(tempoControllerProvider.notifier);
    controller.setRandom(Random(7));

    controller.start();
    var roundSeconds = 0;
    for (final task in container.read(tempoControllerProvider).round) {
      roundSeconds += task.duration.inSeconds;
    }
    controller.advance(Duration(seconds: roundSeconds));

    expect(
      container.read(tempoControllerProvider).status,
      TempoStatus.complete,
    );
  });

  test('stop and pause cancel progression until explicitly resumed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(tempoControllerProvider.notifier);
    controller.setRandom(Random(7));

    controller.start();
    controller.advance(const Duration(seconds: 5));
    controller.pause();
    final pausedAt = container.read(tempoControllerProvider).elapsedInTask;
    controller.advance(const Duration(seconds: 5));
    expect(container.read(tempoControllerProvider).elapsedInTask, pausedAt);

    controller.resume();
    controller.advance(const Duration(seconds: 1));
    expect(
      container.read(tempoControllerProvider).elapsedInTask,
      pausedAt + const Duration(seconds: 1),
    );

    controller.stop();
    expect(container.read(tempoControllerProvider).status, TempoStatus.idle);
    expect(container.read(tempoControllerProvider).round, isEmpty);
  });

  testWidgets('running screen disposes its clock and animation cleanly', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const FollowTheTempoScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith(
            (ref) async => _MemoryRepository(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.dark,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
