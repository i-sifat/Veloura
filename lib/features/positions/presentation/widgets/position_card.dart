import 'package:flutter/material.dart';
import 'package:veloura/features/positions/domain/intimacy_position.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Stateful image card with local favorite feedback and resilient art fallback.
class PositionCard extends StatefulWidget {
  const PositionCard({required this.position, super.key});

  final IntimacyPosition position;

  @override
  State<PositionCard> createState() => _PositionCardState();
}

class _PositionCardState extends State<PositionCard> {
  var _favorite = false;

  @override
  Widget build(BuildContext context) {
    final position = widget.position;
    final colors = AppColors.of(context);
    return Container(
      width: 252,
      height: 360,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameTokens.sheet,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: position.zone.color.withValues(alpha: 0.50),
        ),
        boxShadow: const [GameTokens.tileShadow],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: position.zone.color.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  position.zone.label,
                  style: TextStyle(color: position.zone.color),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: _favorite ? 'Remove favorite' : 'Favorite position',
                onPressed: () => setState(() => _favorite = !_favorite),
                icon: Icon(
                  _favorite ? Icons.favorite : Icons.favorite_border,
                  color: _favorite ? GameTokens.rose : colors.textSecondary,
                ),
              ),
            ],
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                position.art,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(
                    position.zone.icon,
                    size: 72,
                    color: position.zone.color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            position.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            position.setup,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
