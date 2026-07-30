import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/games/domain/game_catalog_entry.dart';
import 'package:veloura/shared/widgets/game/game_tile_glyph.dart';
import 'package:veloura/shared/widgets/game/premium_lock_badge.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Pressable full-art game destination with a resilient artwork fallback.
class GameTile extends StatefulWidget {
  const GameTile({required this.entry, required this.locked, super.key});

  final GameCatalogEntry entry;
  final bool locked;

  @override
  State<GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<GameTile> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${widget.entry.title} game',
    button: true,
    child: AnimatedScale(
      duration: GameTokens.tapScaleDuration,
      scale: _pressed ? 0.97 : 1,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          HapticFeedback.lightImpact();
          if (widget.locked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${widget.entry.title} unlocks with Veloura Premium.',
                ),
              ),
            );
          } else {
            context.push(widget.entry.route);
          }
        },
        child: Container(
          key: ValueKey('game-tile-${widget.entry.id}'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GameTokens.tileRadius),
            border: Border.all(color: GameTokens.roseLight, width: 3),
            boxShadow: const [GameTokens.tileShadow],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                widget.entry.art,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, _, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: widget.entry.gradient),
                  ),
                  child: GameTileGlyph(
                    key: ValueKey('fallback-${widget.entry.id}'),
                    icon: widget.entry.fallbackIcon,
                  ),
                ),
              ),
              if (widget.locked)
                const Positioned(top: 10, right: 10, child: PremiumLockBadge()),
            ],
          ),
        ),
      ),
    ),
  );
}
