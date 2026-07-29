import 'package:flutter/material.dart';
import 'package:veloura/features/cards/domain/challenge_item.dart';
import 'package:veloura/models/difficulty.dart';

/// User-facing heat decks. Categories remain an independent optional filter.
enum IntensityDeck {
  romantic,
  spicy,
  superhot;

  String get label => switch (this) {
    romantic => 'Romantic',
    spicy => 'Spicy',
    superhot => 'Superhot',
  };

  IconData get icon => switch (this) {
    romantic => Icons.favorite,
    spicy => Icons.local_fire_department,
    superhot => Icons.whatshot,
  };

  List<Color> get gradient => switch (this) {
    romantic => const [Color(0xFF8F3E75), Color(0xFF4A1A52)],
    spicy => const [Color(0xFFFF4D6D), Color(0xFFC81E67)],
    superhot => const [Color(0xFFE93763), Color(0xFF7D123D)],
  };

  Color get glow => switch (this) {
    romantic => const Color(0xFFD58BC8),
    spicy => const Color(0xFFFF718D),
    superhot => const Color(0xFFFF3E68),
  };

  /// Maps existing content metadata into three clear play modes.
  bool accepts(ChallengeItem item) => switch (this) {
    romantic => !item.premium &&
        (item.difficulty == Difficulty.cute ||
            item.difficulty == Difficulty.romantic),
    spicy => !item.premium && item.difficulty == Difficulty.spicy,
    superhot => item.premium || item.difficulty == Difficulty.extreme,
  };
}
