import 'package:flutter/material.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Non-blurred glass-like surface safe around animated widgets.
class GlassPanel extends StatelessWidget {
  const GlassPanel({required this.child, this.padding = const EdgeInsets.all(16), super.key});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: GameTokens.glass,
      borderRadius: BorderRadius.circular(GameTokens.cardRadius),
      border: Border.all(color: GameTokens.hairline),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [GameTokens.glassStrong, GameTokens.glass],
      ),
    ),
    child: child,
  );
}
