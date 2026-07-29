import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/app.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/session_repository.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';

class _MemorySessionRepository implements SessionRepository {
  GameSession? value;

  @override
  Future<AppResult<GameSession?>> load() async => AppResult.success(value);

  @override
  Future<AppResult<void>> save(GameSession session) async {
    value = session;
    return const AppResult.success(null);
  }
}

Widget _app() => ProviderScope(
  overrides: [
    sessionRepositoryProvider.overrideWith(
      (ref) async => _MemorySessionRepository(),
    ),
  ],
  child: const VelouraApp(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'session_players_configured': true});
  });

  testWidgets('Veloura launches into the five-tab Home shell', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Make time for each other'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Games exposes all Phase 4.5 catalog entries', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Games'));
    await tester.pumpAndSettle();

    expect(kGameCatalog, hasLength(6));
    final scrollable = find.byType(Scrollable).last;
    for (final entry in kGameCatalog) {
      final tile = find.byKey(ValueKey('game-tile-${entry.id}'));
      await tester.scrollUntilVisible(tile, 180, scrollable: scrollable);
      expect(tile, findsOneWidget);
    }
  });

  testWidgets('remaining navigation branches are reachable', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final label in ['Daily', 'Favorites', 'Profile']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
        find.text('$label is ready for its planned feature phase.'),
        findsOneWidget,
      );
    }
  });
}
