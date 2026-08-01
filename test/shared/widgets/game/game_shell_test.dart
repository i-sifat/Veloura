import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/player.dart';
import 'package:veloura/features/session/domain/session_repository.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/shared/widgets/game/game_shell.dart';

class _SavedSessionRepository implements SessionRepository {
  _SavedSessionRepository(this.value);

  GameSession value;

  @override
  Future<AppResult<GameSession?>> load() async => AppResult.success(value);

  @override
  Future<AppResult<void>> save(GameSession session) async {
    value = session;
    return const AppResult.success(null);
  }
}

GameSession _session() => GameSession(
  a: const Player(id: 'a', name: 'You', colorValue: 0xFFFF4D6D),
  b: const Player(id: 'b', name: 'Partner', colorValue: 0xFF8E4BD1),
  activeIndex: 0,
  startedAt: DateTime(2026),
);

Widget _wrap(Widget shell) => ProviderScope(
  overrides: [
    sessionRepositoryProvider.overrideWith(
      (ref) async => _SavedSessionRepository(_session()),
    ),
  ],
  child: MaterialApp(home: shell),
);

void main() {
  testWidgets('progress slot is absent by default, so other games are unaffected', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const GameShell(
          title: 'Test game',
          hero: Text('hero'),
          cta: Text('cta'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('progress-marker')), findsNothing);
  });

  testWidgets('progress slot renders above the turn chip bar when supplied', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        GameShell(
          title: 'Test game',
          progress: const Text(
            'progress-marker',
            key: ValueKey('progress-marker'),
          ),
          hero: const Text('hero'),
          cta: const Text('cta'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('progress-marker')), findsOneWidget);
  });
}
