import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/positions/domain/intimacy_position.dart';
import 'package:veloura/features/positions/domain/position_repository.dart';
import 'package:veloura/features/positions/domain/position_zone.dart';
import 'package:veloura/features/positions/domain/session_intensity.dart';
import 'package:veloura/features/positions/presentation/positions_controller.dart';
import 'package:veloura/features/premium/provider.dart';

class _MemoryPositionRepository implements PositionRepository {
  @override
  Future<AppResult<List<IntimacyPosition>>> loadAll() async {
    return AppResult.success([
      for (var index = 0; index < PositionZone.values.length; index++)
        IntimacyPosition(
          id: 'position-$index',
          zone: PositionZone.values[index],
          name: 'Position $index',
          setup: 'Setup $index',
          heatMin: 1,
          isPremium: false,
          art: 'art/$index',
        ),
    ]);
  }
}

Future<ProviderContainer> makeContainer({bool premium = false}) async {
  final container = ProviderContainer(
    overrides: [
      positionsRandomProvider.overrideWithValue(Random(7)),
      positionRepositoryProvider.overrideWith(
        (ref) => _MemoryPositionRepository(),
      ),
      isPremiumProvider.overrideWithValue(premium),
    ],
  );
  addTearDown(container.dispose);
  await container.read(positionsControllerProvider.future);
  return container;
}

/// Spins, reveals a position and starts the timed session for the round.
void spinToSession(ProviderContainer container) {
  final notifier = container.read(positionsControllerProvider.notifier);
  notifier.beginSpin();
  notifier.finishSpin();
  notifier.reveal();
  notifier.enterTempo();
}

void main() {
  test('enterTempo opens a timed session scaled to heat', () async {
    final container = await makeContainer();
    final notifier = container.read(positionsControllerProvider.notifier);

    notifier.beginSpin();
    notifier.finishSpin();
    notifier.reveal();
    notifier.enterTempo();

    final state = container.read(positionsControllerProvider).requireValue;
    expect(state.stage, RoundStage.tempo);
    expect(state.sessionIntensity, PositionSessionIntensity.soft);
    expect(state.sessionSeconds, 60);
    expect(state.sessionSecondsLeft, 60);
    expect(state.sessionProgress, 0);
  });

  test('session ring fills as time elapses', () async {
    final container = await makeContainer();
    final notifier = container.read(positionsControllerProvider.notifier);
    spinToSession(container);

    notifier.advanceSession(const Duration(seconds: 30));

    final state = container.read(positionsControllerProvider).requireValue;
    expect(state.sessionProgress, closeTo(0.5, 0.01));
    expect(state.sessionSecondsLeft, 30);
  });

  test('session completes the round and advances heat on its own', () async {
    final container = await makeContainer();
    final notifier = container.read(positionsControllerProvider.notifier);
    spinToSession(container);
    final total = container
        .read(positionsControllerProvider)
        .requireValue
        .sessionSeconds;

    notifier.advanceSession(Duration(seconds: total));

    final state = container.read(positionsControllerProvider).requireValue;
    expect(state.stage, RoundStage.cooldown);
    expect(state.completedRounds, 1);
    expect(state.cooldownEndsAt, isNotNull);
  });

  test('finishSession ends the round early', () async {
    final container = await makeContainer();
    final notifier = container.read(positionsControllerProvider.notifier);
    spinToSession(container);

    notifier.finishSession();

    expect(
      container.read(positionsControllerProvider).requireValue.stage,
      RoundStage.cooldown,
    );
  });

  test('pause and resume stop and restart the session clock', () async {
    final container = await makeContainer();
    final notifier = container.read(positionsControllerProvider.notifier);
    spinToSession(container);

    notifier.advanceSession(const Duration(seconds: 5));
    notifier.pauseSession();
    final pausedAt = container
        .read(positionsControllerProvider)
        .requireValue
        .elapsedInSession;
    notifier.advanceSession(const Duration(seconds: 5));
    expect(
      container.read(positionsControllerProvider).requireValue.elapsedInSession,
      pausedAt,
    );

    notifier.resumeSession();
    notifier.advanceSession(const Duration(seconds: 1));
    expect(
      container.read(positionsControllerProvider).requireValue.elapsedInSession,
      pausedAt + const Duration(seconds: 1),
    );
  });

  test('heat rising through completed rounds escalates intensity', () async {
    final container = await makeContainer();
    final notifier = container.read(positionsControllerProvider.notifier);

    for (var round = 0; round < 4; round++) {
      spinToSession(container);
      final total = container
          .read(positionsControllerProvider)
          .requireValue
          .sessionSeconds;
      notifier.advanceSession(Duration(seconds: total));
      notifier.restart();
    }

    spinToSession(container);
    final state = container.read(positionsControllerProvider).requireValue;
    expect(state.sessionIntensity, PositionSessionIntensity.fast);
    expect(state.sessionSeconds, 90);
  });
}
