import 'package:flutter/material.dart';
import 'package:veloura/features/cards/domain/intensity_deck.dart';
import 'package:veloura/features/cards/presentation/fan/widgets/challenge_card_back.dart';

/// Twelve numbered mystery cards arranged as a compact 3 x 4 deal.
class CardFan extends StatelessWidget {
  const CardFan({
    required this.deck,
    required this.locked,
    required this.onPick,
    super.key,
  });

  final IntensityDeck deck;
  final bool locked;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) => GridView.builder(
    key: const ValueKey('challenge-card-grid'),
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
    physics: const BouncingScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 0.72,
    ),
    itemCount: 12,
    itemBuilder: (context, index) => Semantics(
      button: true,
      label: '${deck.label} mystery card ${index + 1}',
      child: GestureDetector(
        key: ValueKey('challenge-card-${index + 1}'),
        onTap: () => onPick(index + 1),
        child: ChallengeCardBack(
          number: index + 1,
          deck: deck,
          locked: locked,
        ),
      ),
    ),
  );
}
