import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';
import 'package:veloura/features/home/presentation/home_screen.dart';

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
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    final first = popularGamesFor(DateTime.now()).first;
    final popularCard = find.byKey(ValueKey('popular-${first.id}'));
    await tester.ensureVisible(popularCard);
    await tester.tap(popularCard);
    await tester.pumpAndSettle();

    expect(find.text('Opened ${first.id}'), findsOneWidget);
  });
}
