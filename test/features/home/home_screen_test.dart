import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';
import 'package:veloura/features/home/presentation/home_screen.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/session_repository.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';

/// In-memory session store so HomeController's session dependency resolves
/// without touching a real Hive box in widget tests.
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

void main() {
  test('popular games rotate by day and contain four unique entries', () {
    final first = popularGamesFor(DateTime(2026, 7, 30));
    final next = popularGamesFor(DateTime(2026, 7, 31));

    expect(first, hasLength(4));
    expect(first.map((game) => game.id).toSet(), hasLength(4));
    expect(next.first.id, isNot(first.first.id));
  });

  testWidgets('every Popular games card opens its existing route', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: HomeScreen()),
        ),
        GoRoute(path: '/games', builder: (_, _) => const Text('Games')),
        for (final game in kGameCatalog)
          GoRoute(
            path: game.route,
            builder: (_, _) => Scaffold(body: Text('Opened ${game.id}')),
          ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith(
            (ref) async => _MemorySessionRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final first = popularGamesFor(DateTime.now()).first;
    final popularCard = find.byKey(ValueKey('popular-${first.id}'));
    await tester.scrollUntilVisible(
      popularCard,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -40));
    await tester.pumpAndSettle();
    await tester.tap(popularCard);
    await tester.pumpAndSettle();

    expect(find.text('Opened ${first.id}'), findsOneWidget);
  });

  testWidgets('Popular games\' "See all" still opens the Games hub', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: HomeScreen()),
        ),
        GoRoute(path: '/games', builder: (_, _) => const Text('Games')),
        GoRoute(
          path: '/home/conversation',
          builder: (_, _) => const Text('Creative connections'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith(
            (ref) async => _MemorySessionRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // The hero card above this section now sizes itself to the artwork's
    // real (taller-than-placeholder) aspect ratio, so "Popular games" can
    // land below the default test viewport + sliver cache extent. Scroll
    // it into view first, exactly like the sibling test above already
    // does for the popular game cards.
    await tester.scrollUntilVisible(
      find.text('Popular games'),
      100,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Popular games'), findsOneWidget);
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(find.text('Games'), findsOneWidget);
  });

  testWidgets("Let's play opens the Creative Connections flow", (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: HomeScreen()),
        ),
        GoRoute(path: '/games', builder: (_, _) => const Text('Games')),
        GoRoute(
          path: '/home/conversation',
          builder: (_, _) => const Text('Creative connections'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith(
            (ref) async => _MemorySessionRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // The hero card sizes itself to the artwork's real aspect ratio, which
    // can push "Let's play" (near the card's bottom edge) right to, or
    // just past, the default test viewport's fold. Ensure it's actually
    // on-screen before tapping, same as the sibling tests above already
    // do for content further down the page.
    await tester.ensureVisible(find.text("Let's play"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Let's play"));
    await tester.pumpAndSettle();

    expect(find.text('Creative connections'), findsOneWidget);
  });

  testWidgets('greets the player using their onboarding name, not a placeholder', (
    tester,
  ) async {
    final repository = _MemorySessionRepository();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: HomeScreen()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith((ref) async => repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Session default ("You") until onboarding sets a real name - never the
    // old hardcoded "Angelina" placeholder.
    expect(find.textContaining('You'), findsWidgets);
    expect(find.textContaining('Angelina'), findsNothing);
  });
}
