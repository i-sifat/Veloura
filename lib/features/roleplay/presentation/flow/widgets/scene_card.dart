import 'package:flutter/material.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/shared/widgets/game/game_tile_glyph.dart';
import 'package:veloura/shared/widgets/game/premium_lock_badge.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Full-bleed scene preview backed entirely by existing story metadata.
class SceneCard extends StatelessWidget {
  const SceneCard({required this.story, required this.locked, super.key});

  final RoleplayStory story;
  final bool locked;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(colors: GameTokens.passionateRoleplay),
      boxShadow: const [GameTokens.tileShadow],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/games/scenes/${story.id}.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const GameTileGlyph(
            icon: Icons.theater_comedy_outlined,
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xB8000000)],
              stops: [0.45, 1],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (locked) const Align(alignment: Alignment.topRight, child: PremiumLockBadge()),
              const Spacer(),
              Text(
                story.title.toUpperCase(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                story.setting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              Chip(label: Text(story.estimatedDuration)),
            ],
          ),
        ),
      ],
    ),
  );
}
