import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';
import 'package:veloura/features/games/domain/game_catalog_entry.dart';
import 'package:veloura/features/games/presentation/games_hub_screen.dart';
import 'package:veloura/features/games/presentation/widgets/game_tile.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/session_repository.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
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

  testWidgets('hub renders all six catalog tiles in a two-column grid', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(kGameCatalog, hasLength(6));
    expect(find.byKey(const ValueKey('games-grid')), findsOneWidget);
    expect(find.text('SELECT A GAME'), findsOneWidget);
    final scrollable = find.byType(Scrollable).last;
    for (final entry in kGameCatalog) {
      final tile = find.byKey(ValueKey('game-tile-${entry.id}'));
      await tester.scrollUntilVisible(tile, 180, scrollable: scrollable);
      expect(tile, findsOneWidget);
    }
  });

  test('catalog artwork is bundled for every game', () async {
    for (final entry in kGameCatalog) {
      final data = await rootBundle.load(entry.art);
      expect(data.lengthInBytes, greaterThan(0), reason: entry.art);
    }
  });

  testWidgets('missing art falls back to a themed glyph', (tester) async {
    const missingEntry = GameCatalogEntry(
      id: 'missing_art',
      title: 'Missing Art',
      route: '/missing',
      art: 'assets/does_not_exist.png',
      gradient: [Color(0xFF51124D), Color(0xFF19061D)],
      fallbackIcon: Icons.casino_outlined,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 220,
            child: GameTile(entry: missingEntry, locked: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fallback-missing_art')), findsOneWidget);
  });

  testWidgets('first visit requires player setup', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text("Who's playing?"), findsOneWidget);
    expect(find.text('Start playing'), findsOneWidget);
  });
}
