import 'package:flutter/material.dart';
import 'package:veloura/features/conversation/domain/conversation_item.dart';
import 'package:veloura/theme/app_design_tokens.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Premium prompt card used by the Conversation Starters swipe stack.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    required this.item,
    this.showSwipeHint = false,
    super.key,
  });

  final ConversationItem item;
  final bool showSwipeHint;

  @override
  Widget build(BuildContext context) => Container(
    width: 240,
    height: 340,
    padding: const EdgeInsets.all(AppDesignTokens.spaceXxl),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: GameTokens.creativeConnections,
      ),
      border: Border.all(color: const Color(0x1AFFFFFF)),
      boxShadow: const [GameTokens.tileShadow],
    ),
    child: Stack(
      children: [
        const _PeelAccent(),
        Column(
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                // Intrinsic height (no fixed 24px) so a two-line category
                // label like "GETTING TO KNOW YOU AGAIN" grows the pill
                // instead of clipping its wrapped second line underneath a
                // fixed-height box.
                constraints: const BoxConstraints(minWidth: 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignTokens.spaceMd,
                  vertical: AppDesignTokens.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: GameTokens.glassStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  categoryTitle(item.conversationCategory).toUpperCase(),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    height: 1.25,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Flexible(
              flex: 6,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 192,
                    child: Text(
                      item.prompt,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        height: AppDesignTokens.lineHeightTight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            AnimatedOpacity(
              duration: GameTokens.fadeDuration,
              opacity: showSwipeHint ? 1 : 0,
              // Longer copy than the old "SWIPE" label, so it's wrapped in a
              // FittedBox (same pattern as the prompt text above) instead of
              // being sized to its natural, overflowing width.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Swipe to reveal answer',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppDesignTokens.spaceXs),
                    const Icon(Icons.chevron_right, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Sticker-style "peeled corner" accent tinted from the card's own gradient
/// (instead of a flat white sheen), so it reads as an intentional lifted
/// edge that belongs to this card rather than a generic highlight.
class _PeelAccent extends StatelessWidget {
  const _PeelAccent();

  @override
  Widget build(BuildContext context) => Positioned(
    top: -6,
    right: -6,
    child: Transform.rotate(
      angle: -0.5,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.white.withValues(alpha: 0.32),
              GameTokens.creativeConnections.last.withValues(alpha: 0),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(-3, 5),
            ),
          ],
        ),
      ),
    ),
  );
}

String categoryTitle(ConversationCategory value) => switch (value) {
  ConversationCategory.deep => 'Deep',
  ConversationCategory.funny => 'Funny',
  ConversationCategory.romantic => 'Romantic',
  ConversationCategory.future => 'Future',
  ConversationCategory.rediscover => 'Getting to know you again',
};
