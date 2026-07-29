import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/games/presentation/games_hub_screen.dart';
import 'package:veloura/features/games/presentation/widgets/game_tile.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/session_repository.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/shared/widgets/game/game_tile_glyph.dart';
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

Widget _app() => ProviderScope(
  overrides: [
    sessionRepositoryProvider.overrideWith((ref) async => _MemoryRepository()),
  ],
  child: MaterialApp(theme: AppTheme.dark, home: const GamesHubScreen()),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'session_players_configured': true});
  });

  testWidgets('hub renders six tiles in a two-column grid', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(GameTile), findsNWidgets(6));
    expect(find.byKey(const ValueKey('games-grid')), findsOneWidget);
    expect(find.text('SELECT A GAME'), findsOneWidget);
  });

  testWidgets('missing commissioned art falls back to game glyphs', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(GameTileGlyph), findsNWidgets(6));
  });

  testWidgets('first visit requires player setup', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text("Who's playing?"), findsOneWidget);
    expect(find.text('Start playing'), findsOneWidget);
  });
}
