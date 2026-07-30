import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/player.dart';
import 'package:veloura/features/session/domain/session_repository.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/shared/widgets/game/turn_chip_bar.dart';

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

void main() {
  testWidgets('later games show locally saved onboarding names', (tester) async {
    final repository = _SavedSessionRepository(
      GameSession(
        a: const Player(id: 'a', name: 'Alex', colorValue: 0xFFFF4D6D),
        b: const Player(id: 'b', name: 'Jamie', colorValue: 0xFF8E4BD1),
        activeIndex: 0,
        startedAt: DateTime(2026),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith((ref) async => repository),
        ],
        child: const MaterialApp(home: Scaffold(body: TurnChipBar())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Jamie'), findsOneWidget);
  });
}
