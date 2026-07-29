import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/session_repository.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';

class _MemorySessionRepository implements SessionRepository {
  GameSession? value;
  var shouldFail = false;

  @override
  Future<AppResult<GameSession?>> load() async => shouldFail
      ? const AppResult.failure('load failed')
      : AppResult.success(value);

  @override
  Future<AppResult<void>> save(GameSession session) async {
    if (shouldFail) return const AppResult.failure('save failed');
    value = session;
    return const AppResult.success(null);
  }
}

void main() {
  test('creates defaults and nextTurn flips active player', () async {
    final repository = _MemorySessionRepository();
    final container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(sessionControllerProvider.future);
    expect(initial.a.name, 'You');
    expect(initial.b.name, 'Partner');
    expect(initial.activeIndex, 0);

    await container.read(sessionControllerProvider.notifier).nextTurn();
    expect(container.read(sessionControllerProvider).requireValue.activeIndex, 1);
    expect(repository.value?.activeIndex, 1);
  });

  test('setPlayers trims names and resetTurns restores player A', () async {
    final repository = _MemorySessionRepository();
    final container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.future);

    final controller = container.read(sessionControllerProvider.notifier);
    await controller.setPlayers(
      nameA: 'A very long player name',
      colorA: 1,
      nameB: '  Bea  ',
      colorB: 2,
    );
    await controller.nextTurn();
    await controller.resetTurns();

    final value = container.read(sessionControllerProvider).requireValue;
    expect(value.a.name, hasLength(12));
    expect(value.b.name, 'Bea');
    expect(value.activeIndex, 0);
  });
}
