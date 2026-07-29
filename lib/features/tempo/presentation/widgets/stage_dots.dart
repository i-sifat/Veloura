import 'package:flutter/material.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Three-dot progress marker for the timed stages.
class StageDots extends StatelessWidget {
  const StageDots({required this.activeIndex, super.key});

  final int activeIndex;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var index = 0; index < 3; index++) ...[
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
        if (index != 2) const SizedBox(width: 8),
      ],
    ],
  );
}
