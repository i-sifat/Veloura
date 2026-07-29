import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/cards/domain/intensity_deck.dart';
import 'package:veloura/features/cards/presentation/fan/widgets/card_fan.dart';

void main() {
  testWidgets('deal always renders twelve numbered mystery cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 760,
            child: CardFan(
              deck: IntensityDeck.spicy,
              locked: false,
              onPick: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('challenge-card-grid')), findsOneWidget);
    for (var number = 1; number <= 12; number++) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('challenge-card-$number')),
        150,
        scrollable: find.byType(Scrollable),
      );
      expect(find.byKey(ValueKey('challenge-card-$number')), findsOneWidget);
    }
  });
}
