import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veloura/shared/widgets/game/game_app_bar.dart';
import 'package:veloura/shared/widgets/game/game_backdrop.dart';
import 'package:veloura/shared/widgets/game/turn_chip_bar.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Shared game composition enforcing one hero and one primary action.
class GameShell extends StatelessWidget {
  const GameShell({
    required this.title,
    required this.hero,
    required this.cta,
    this.headline,
    this.footnote,
    this.board = false,
    this.onInfo,
    this.leading,
    super.key,
  });

  final String title;
  final Widget hero;
  final Widget cta;
  final Widget? headline;
  final Widget? footnote;
  final bool board;
  final VoidCallback? onInfo;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: GameBackdrop(
      board: board,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GameTokens.screenPadH),
          child: Column(
            children: [
              GameAppBar(title: title, leading: leading, onInfo: onInfo),
              const TurnChipBar(),
              const SizedBox(height: 8),
              if (headline != null) headline!,
              Expanded(child: Center(child: RepaintBoundary(child: hero))),
              if (footnote != null) footnote!,
              const SizedBox(height: 16),
              cta,
              SizedBox(
                height: math.max(MediaQuery.paddingOf(context).bottom, 12) + 12,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
