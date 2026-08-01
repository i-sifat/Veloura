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
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x24FFFFFF), Colors.transparent],
                stops: [0, 0.45],
              ),
            ),
          ),
        ),
        Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignTokens.spaceMd,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GameTokens.glassStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  categoryTitle(item.conversationCategory).toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
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
          ],
        ),
      ],
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
