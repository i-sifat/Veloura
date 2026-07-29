import 'package:flutter/material.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Two-role assignment surface; the active player picks one role.
class RolePickRow extends StatelessWidget {
  const RolePickRow({
    required this.story,
    required this.session,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final RoleplayStory story;
  final GameSession session;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _RoleCard(
          role: story.characterA,
          index: 0,
          selectedIndex: selectedIndex,
          session: session,
          onSelected: onSelected,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _RoleCard(
          role: story.characterB,
          index: 1,
          selectedIndex: selectedIndex,
          session: session,
          onSelected: onSelected,
        ),
      ),
    ],
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.index,
    required this.selectedIndex,
    required this.session,
    required this.onSelected,
  });

  final RoleplayCharacter role;
  final int index;
  final int? selectedIndex;
  final GameSession session;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex == index;
    final partnerAssigned = selectedIndex != null && !selected;
    return GestureDetector(
      onTap: () => onSelected(index),
      child: AnimatedContainer(
        duration: GameTokens.fadeDuration,
        height: 210,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? GameTokens.glassStrong : GameTokens.glass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? GameTokens.rose : GameTokens.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (partnerAssigned)
              Align(
                alignment: Alignment.topRight,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(session.passive.colorValue),
                  child: Text(session.passive.name[0]),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.theater_comedy_outlined,
                  size: 28,
                  color: Color(0xE0FFFFFF),
                ),
                const Spacer(),
                Text(
                  role.name.toUpperCase(),
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
