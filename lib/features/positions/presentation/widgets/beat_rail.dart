import 'package:flutter/material.dart';
import 'package:veloura/features/positions/domain/tempo_beat.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Large, unrushable beat display with visible script progress.
class BeatRail extends StatelessWidget {
  const BeatRail({
    required this.beats,
    required this.index,
    required this.onAdvance,
    super.key,
  });

  final List<TempoBeat> beats;
  final int index;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final beat = beats[index];
    return Semantics(
      button: index < beats.length - 1,
      label: beat.count == null ? beat.label : '${beat.count} ${beat.label}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: index < beats.length - 1 ? onAdvance : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 210,
              height: 210,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: GameTokens.rose.withValues(alpha: 0.34),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: GameTokens.rose.withValues(alpha: 0.15),
                    blurRadius: 42,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (beat.count != null)
                    Text(
                      '${beat.count}',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: GameTokens.rose,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      beat.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: beat.count == null ? 0 : 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var beatIndex = 0; beatIndex < beats.length; beatIndex++) ...[
                  if (beatIndex > 0) const SizedBox(width: 6),
                  Container(
                    width: 18,
                    height: 3,
                    decoration: BoxDecoration(
                      color: beatIndex <= index
                          ? GameTokens.rose
                          : GameTokens.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
