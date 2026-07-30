import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';
import 'package:veloura/features/home/presentation/home_screen.dart';

void main() {
  test('popular games rotate by day and never include Conversation', () {
    final first = popularGamesFor(DateTime(2026, 7, 30));
    final next = popularGamesFor(DateTime(2026, 7, 31));

    expect(first, hasLength(3));
    expect(first.map((game) => game.id).toSet(), hasLength(3));
    expect(first.map((game) => game.title), isNot(contains('Conversation')));
    expect(next.first.id, isNot(first.first.id));
  });

  testWidgets('every Popular tonight card opens its game route', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: HomeScreen()),
        ),
        GoRoute(
          path: '/home/conversation',
          builder: (_, _) => const Scaffold(body: Text('Conversation')),
        ),
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
    await tester.tap(find.byKey(ValueKey('popular-${first.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Opened ${first.id}'), findsOneWidget);
    expect(find.text('Premium experiences are coming in Phase 6.'), findsNothing);
  });
}
