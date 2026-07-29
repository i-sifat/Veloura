import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/cards/domain/challenge_item.dart';
import 'package:veloura/features/cards/domain/intensity_deck.dart';
import 'package:veloura/models/difficulty.dart';

ChallengeItem item(Difficulty difficulty, {bool premium = false}) => ChallengeItem(
  id: '${difficulty.name}-$premium',
  title: 'Title',
  description: 'Description',
  challengeCategory: ChallengeCategory.romance,
  difficulty: difficulty,
  estimatedMinutes: 10,
  premium: premium,
  createdAt: DateTime(2026),
);

void main() {
  test('non-premium content maps cleanly to Romantic or Spicy', () {
    expect(IntensityDeck.romantic.accepts(item(Difficulty.cute)), isTrue);
    expect(IntensityDeck.romantic.accepts(item(Difficulty.romantic)), isTrue);
    expect(IntensityDeck.spicy.accepts(item(Difficulty.spicy)), isTrue);
    expect(IntensityDeck.superhot.accepts(item(Difficulty.extreme)), isTrue);
  });

  test('premium cards map only to Superhot regardless of base difficulty', () {
    for (final difficulty in Difficulty.values) {
      final premium = item(difficulty, premium: true);
      expect(IntensityDeck.superhot.accepts(premium), isTrue);
      expect(IntensityDeck.romantic.accepts(premium), isFalse);
      expect(IntensityDeck.spicy.accepts(premium), isFalse);
    }
  });
}
