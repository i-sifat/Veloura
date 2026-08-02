import 'package:flutter/material.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Dot progress marker for a round of short tasks.
class StageDots extends StatelessWidget {
  const StageDots({
    required this.total,
    required this.activeIndex,
    super.key,
  });

  final int total;
  final int activeIndex;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var index = 0; index < total; index++) ...[
        AnimatedContainer(
          key: ValueKey('tempo-stage-$index'),
          duration: GameTokens.fadeDuration,
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == activeIndex
                ? GameTokens.rose
                : Colors.white.withValues(alpha: 0.24),
          ),
        ),
        if (index != total - 1) const SizedBox(width: 8),
      ],
    ],
  );
}
