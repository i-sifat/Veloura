import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/tempo/presentation/tempo_controller.dart';

void main() {
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

  test('stop and pause cancel progression until explicitly resumed', () async {
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
    expect(container.read(tempoControllerProvider).elapsed, pausedAt + const Duration(seconds: 1));

    controller.stop();
    expect(container.read(tempoControllerProvider).status, TempoStatus.idle);
    expect(container.read(tempoControllerProvider).elapsed, Duration.zero);
  });
}
