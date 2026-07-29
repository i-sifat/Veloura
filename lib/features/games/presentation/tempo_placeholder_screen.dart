import 'package:flutter/material.dart';
import 'package:veloura/shared/widgets/game/game_shell.dart';
import 'package:veloura/shared/widgets/game/game_tile_glyph.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';

/// Safe routed placeholder until Follow the Tempo is built in 4.5.6.
class TempoPlaceholderScreen extends StatelessWidget {
  const TempoPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => const GameShell(
    title: 'Follow the Tempo',
    hero: GameTileGlyph(icon: Icons.graphic_eq),
    footnote: Text('A shared rhythm experience is coming next.'),
    cta: PrimaryCta(label: 'Coming soon', onPressed: null),
  );
}
