import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';
import 'package:veloura/features/games/presentation/widgets/game_tile.dart';

void main() {
  testWidgets('game tile uses full-bleed art without duplicate title text', (
    tester,
  ) async {
    final entry = kGameCatalog.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 220,
            child: GameTile(entry: entry, locked: false),
          ),
        ),
      ),
    );

    final tileFinder = find.byKey(ValueKey('game-tile-${entry.id}'));
    final tile = tester.widget<Container>(tileFinder);
    final decoration = tile.decoration! as BoxDecoration;
    final image = tester.widget<Image>(
      find.descendant(of: tileFinder, matching: find.byType(Image)),
    );

    expect(find.text(entry.title.toUpperCase()), findsNothing);
    expect(image.fit, BoxFit.cover);
    expect(decoration.border!.top.width, 3);
  });
}
