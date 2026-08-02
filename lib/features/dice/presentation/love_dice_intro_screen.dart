import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/shared/widgets/game/game_backdrop.dart';
import 'package:veloura/shared/widgets/game/glass_panel.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/shared/widgets/game/secondary_text_button.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Pre-start presentation for Love Dice; gameplay remains in [DiceScreen].
class LoveDiceIntroScreen extends StatefulWidget {
  const LoveDiceIntroScreen({super.key});

  @override
  State<LoveDiceIntroScreen> createState() => _LoveDiceIntroScreenState();
}

class _LoveDiceIntroScreenState extends State<LoveDiceIntroScreen> {
  // Guards against a fast double-tap queuing two pushes of '/play' - without
  // this, a second tap while the first push is still settling can stack a
  // second DiceScreen on top; popping either one then lands back on this
  // intro, which reads as "Start game keeps leading back to Start game".
  var _navigating = false;

  Future<void> _startGame() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    try {
      await context.push('/games/lustful-rolls/play');
    } finally {
      // The pushed route may have been popped back to this screen (e.g. the
      // player left the game), so re-arm the button for another round.
      if (mounted) setState(() => _navigating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: GameBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GameTokens.screenPadH,
            8,
            GameTokens.screenPadH,
            24,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: context.pop,
                    icon: const Icon(Icons.arrow_back, size: 22),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Save game',
                    onPressed: () {},
                    icon: Icon(
                      Icons.bookmark_border,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 176,
                child: Image.asset(
                  'assets/lustful_rolls.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.casino_rounded,
                    size: 128,
                    color: GameTokens.roseLight,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Love Dice',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Let fate decide what happens next.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 32),
              const _InfoRow(
                icon: Icons.group,
                title: '2 Players',
                subtitle: 'Best with your partner',
              ),
              const SizedBox(height: 10),
              const _InfoRow(
                icon: Icons.local_fire_department,
                title: 'Spicy level',
                subtitle: 'Medium   \u{1F525} \u{1F525} \u2606',
                accent: true,
              ),
              const SizedBox(height: 10),
              const _InfoRow(
                icon: Icons.auto_awesome,
                title: 'What to expect',
                subtitle: 'Fun, flirty and a little bit spicy \u{1F609}',
              ),
              const Spacer(),
              PrimaryCta(
                label: _navigating ? 'Starting\u2026' : 'Start game',
                icon: Icons.arrow_forward,
                busy: _navigating,
                onPressed: _navigating ? null : _startGame,
              ),
              const SizedBox(height: 4),
              SecondaryTextButton(
                label: 'How to play?',
                onPressed: () => _showHowToPlay(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GameTokens.sheet,
      showDragHandle: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Text(
          'Roll both dice together. One die chooses the action and the other '
          'chooses where. Pass the turn after each result.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool accent;

  @override
  Widget build(BuildContext context) => GlassPanel(
    child: Row(
      children: [
        Icon(
          icon,
          color: accent ? GameTokens.roseLight : Colors.white.withValues(alpha: 0.72),
          size: 28,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
