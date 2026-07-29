import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/session_repository.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
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

  test('60 bpm stage emits exactly 30 beats over 30 seconds', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(tempoControllerProvider.notifier);

    controller.start();
    controller.advance(const Duration(seconds: 30));

    final state = container.read(tempoControllerProvider);
    expect(state.beatCount, 30);
    expect(state.stageIndex, 1);
  });

  test('round advances through three stages and a three-second hold', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(tempoControllerProvider.notifier);

    controller.start();
    controller.advance(const Duration(seconds: 90));
    expect(container.read(tempoControllerProvider).instruction, 'HOLD');

    controller.advance(const Duration(seconds: 3));
    expect(
      container.read(tempoControllerProvider).status,
      TempoStatus.complete,
    );
  });

  test('stop and pause cancel progression until explicitly resumed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(tempoControllerProvider.notifier);

    controller.start();
    controller.advance(const Duration(seconds: 5));
    controller.pause();
    final pausedAt = container.read(tempoControllerProvider).elapsed;
    controller.advance(const Duration(seconds: 5));
    expect(container.read(tempoControllerProvider).elapsed, pausedAt);

    controller.resume();
    controller.advance(const Duration(seconds: 1));
    expect(
      container.read(tempoControllerProvider).elapsed,
      pausedAt + const Duration(seconds: 1),
    );

    controller.stop();
    expect(container.read(tempoControllerProvider).status, TempoStatus.idle);
    expect(container.read(tempoControllerProvider).elapsed, Duration.zero);
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
