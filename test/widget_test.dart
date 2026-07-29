import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/app.dart';

void main() {
  testWidgets('Veloura launches into the five-tab Home shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VelouraApp()));
    await tester.pumpAndSettle();

    expect(find.text('Make time for each other'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Games exposes all Phase 2 and Phase 3 modules', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VelouraApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Games'));
    await tester.pumpAndSettle();

    expect(find.text('Dice'), findsOneWidget);
    expect(find.text('Truth or Dare'), findsOneWidget);
    expect(find.text('Challenge Cards'), findsOneWidget);
    expect(find.text('Conversation Starters'), findsOneWidget);
  });

  testWidgets('remaining navigation branches are reachable', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VelouraApp()));
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
