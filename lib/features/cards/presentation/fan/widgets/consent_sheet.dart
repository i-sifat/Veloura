import 'package:flutter/material.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/shared/widgets/game/secondary_text_button.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/game_tokens.dart';

/// One-time Superhot reminder that every card can be skipped safely.
abstract final class ConsentSheet {
  static Future<bool?> show(BuildContext context) => showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: const BoxDecoration(
        color: GameTokens.sheet,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GameTokens.sheetRadius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Anything is skippable.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Skip any card. No score or streak is lost.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.of(context).textSecondary),
            ),
            const SizedBox(height: 20),
            PrimaryCta(
              label: 'Got it',
              onPressed: () => Navigator.pop(context, true),
            ),
            SecondaryTextButton(
              label: 'Choose Spicy instead',
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    ),
  );
}
