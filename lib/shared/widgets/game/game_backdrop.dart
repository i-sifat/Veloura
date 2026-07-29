import 'package:flutter/material.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Layered plum game backdrop without runtime blur.
class GameBackdrop extends StatelessWidget {
  const GameBackdrop({required this.child, this.board = false, super.key});

  final Widget child;
  final bool board;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [GameTokens.bgTop, GameTokens.bgMid, GameTokens.bgBottom],
        stops: [0, 0.55, 1],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.35),
              radius: 0.95,
              colors: [Color(0x8C5B1668), Colors.transparent],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.05,
              colors: [Colors.transparent, GameTokens.vignette],
            ),
          ),
        ),
        if (board)
          Padding(
            padding: const EdgeInsets.all(16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: GameTokens.hairline),
              ),
            ),
          ),
        child,
      ],
    ),
  );
}
