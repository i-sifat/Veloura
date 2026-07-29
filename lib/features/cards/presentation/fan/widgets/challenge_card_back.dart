import 'package:flutter/material.dart';
import 'package:veloura/features/cards/domain/intensity_deck.dart';
import 'package:veloura/shared/widgets/game/premium_lock_badge.dart';

/// Numbered premium card back that reveals no challenge details.
class ChallengeCardBack extends StatelessWidget {
  const ChallengeCardBack({
    required this.number,
    required this.deck,
    required this.locked,
    super.key,
  });

  final int number;
  final IntensityDeck deck;
  final bool locked;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: deck.gradient,
      ),
      border: Border.all(color: deck.glow.withValues(alpha: 0.55), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: deck.glow.withValues(alpha: 0.28),
          blurRadius: 18,
          spreadRadius: -2,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(deck.icon, size: 28, color: Colors.white.withValues(alpha: 0.90)),
              const SizedBox(height: 10),
              Text(
                '$number',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (locked)
          const Positioned(top: 8, right: 8, child: PremiumLockBadge()),
      ],
    ),
  );
}
