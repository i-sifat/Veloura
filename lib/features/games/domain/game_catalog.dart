import 'package:flutter/material.dart';
import 'package:veloura/features/games/domain/game_catalog_entry.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Display-ordered catalog for the Games hub and future random-game action.
const kGameCatalog = <GameCatalogEntry>[
  GameCatalogEntry(
    id: 'lustful_rolls',
    title: 'Lustful Rolls',
    route: '/games/lustful-rolls',
    art: 'assets/lustful_rolls.png',
    gradient: GameTokens.lustfulRolls,
    fallbackIcon: Icons.casino_outlined,
  ),
  GameCatalogEntry(
    id: 'card_challenge',
    title: 'Card Challenge',
    route: '/games/card-challenge',
    art: 'assets/card_challenge.png',
    gradient: GameTokens.cardChallenge,
    fallbackIcon: Icons.style_outlined,
  ),
  GameCatalogEntry(
    id: 'truth_or_dare',
    title: 'Truth or Dare',
    route: '/games/truth-or-dare',
    art: 'assets/truth_dare.png',
    gradient: GameTokens.truthOrDare,
    fallbackIcon: Icons.track_changes_outlined,
  ),
  GameCatalogEntry(
    id: 'creative_connections',
    title: 'Creative Connections',
    route: '/games/creative-connections',
    art: 'assets/creative_positions.png',
    gradient: GameTokens.creativeConnections,
    fallbackIcon: Icons.forum_outlined,
  ),
  GameCatalogEntry(
    id: 'follow_the_tempo',
    title: 'Follow the Tempo',
    route: '/games/follow-the-tempo',
    art: 'assets/follow_tempo.png',
    gradient: GameTokens.followTheTempo,
    fallbackIcon: Icons.graphic_eq,
  ),
  GameCatalogEntry(
    id: 'passionate_roleplay',
    title: 'Passionate Roleplay',
    route: '/games/passionate-roleplay',
    art: 'assets/passionate_roleplay.png',
    gradient: GameTokens.passionateRoleplay,
    fallbackIcon: Icons.theater_comedy_outlined,
    isPremium: true,
  ),
];
