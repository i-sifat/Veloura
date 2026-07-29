import 'package:flutter/material.dart';
import 'package:veloura/theme/game_tokens.dart';

/// One authored beat with speaker and compact progress dots.
class BeatView extends StatelessWidget {
  const BeatView({required this.line, required this.speaker, required this.index, required this.total, super.key});

  final String line;
  final String speaker;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (dot) => Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(shape: BoxShape.circle, color: dot == index ? GameTokens.rose : Colors.white24),
        )),
      ),
      const SizedBox(height: 30),
      AnimatedSwitcher(
        duration: GameTokens.fadeDuration,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation), child: child),
        ),
        child: Text(line, key: ValueKey(line), textAlign: TextAlign.center, maxLines: 5, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 12),
      Chip(label: Text(speaker.toUpperCase())),
    ],
  );
}
