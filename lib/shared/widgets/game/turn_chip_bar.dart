import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Shared active-player indicator shown by every game shell.
class TurnChipBar extends ConsumerWidget {
  const TurnChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionStateProvider);
    return SizedBox(
      height: 36,
      child: session.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (value) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PlayerChip(name: value.active.name, color: value.active.colorValue),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.chevron_right, size: 14, color: GameTokens.rose),
            ),
            Opacity(
              opacity: 0.45,
              child: _PlayerChip(
                name: value.passive.name,
                color: value.passive.colorValue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.name, required this.color});

  final String name;
  final int color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(
        radius: 13,
        backgroundColor: Color(color),
        child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 12)),
      ),
      const SizedBox(width: 6),
      Text(
        name,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ],
  );
}
