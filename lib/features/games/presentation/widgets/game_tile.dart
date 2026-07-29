import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/games/domain/game_catalog_entry.dart';
import 'package:veloura/shared/widgets/game/game_tile_glyph.dart';
import 'package:veloura/shared/widgets/game/premium_lock_badge.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Pressable gradient game destination with resilient artwork fallback.
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
              const SnackBar(content: Text('Passionate Roleplay unlocks with Veloura Premium.')),
            );
          } else {
            context.push(widget.entry.route);
          }
        },
        child: Container(
          key: ValueKey('game-tile-${widget.entry.id}'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GameTokens.tileRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.entry.gradient,
            ),
            border: Border.all(color: const Color(0x1AFFFFFF)),
            boxShadow: const [GameTokens.tileShadow],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x24FFFFFF), Colors.transparent],
                    stops: [0, 0.45],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: 0.62,
                  widthFactor: 1,
                  child: Image.asset(
                    widget.entry.art,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, _, _) => GameTileGlyph(
                      key: ValueKey('fallback-${widget.entry.id}'),
                      icon: widget.entry.fallbackIcon,
                    ),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x38000000)],
                    stops: [0.55, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    widget.entry.title.toUpperCase(),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1.18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
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
