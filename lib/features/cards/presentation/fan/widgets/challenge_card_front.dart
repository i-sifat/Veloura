import 'package:flutter/material.dart';
import 'package:veloura/features/cards/domain/challenge_item.dart';
import 'package:veloura/features/cards/domain/intensity_deck.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Revealed card face using the existing challenge title and description.
class ChallengeCardFront extends StatelessWidget {
  const ChallengeCardFront({
    required this.item,
    required this.deck,
    required this.number,
    super.key,
  });

  final ChallengeItem item;
  final IntensityDeck deck;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GameTokens.sheet,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: deck.glow.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: deck.glow.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: deck.glow.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  deck.label.toUpperCase(),
                  style: TextStyle(
                    color: deck.glow,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$number',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Flexible(
            child: Text(
              item.description,
              maxLines: 8,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
