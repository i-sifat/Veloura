import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veloura/shared/widgets/game/game_app_bar.dart';
import 'package:veloura/shared/widgets/game/game_backdrop.dart';
import 'package:veloura/shared/widgets/game/turn_chip_bar.dart';
import 'package:veloura/theme/app_design_tokens.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Shared game composition enforcing one hero and one primary action.
class GameShell extends StatelessWidget {
  const GameShell({
    required this.title,
    required this.hero,
    required this.cta,
    this.headline,
    this.footnote,
    this.progress,
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

  /// Optional decorative progress indicator (e.g. [StepProgressBar]) shown
  /// between the app bar and the turn chip bar. Defaults to null so every
  /// other game screen using [GameShell] is unaffected.
  final Widget? progress;
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
              if (progress != null) ...[
                progress!,
                const SizedBox(height: AppDesignTokens.spaceSm),
              ],
              const TurnChipBar(),
              const SizedBox(height: AppDesignTokens.spaceSm),
              ?headline,
              Expanded(child: Center(child: RepaintBoundary(child: hero))),
              ?footnote,
              const SizedBox(height: AppDesignTokens.spaceLg),
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
