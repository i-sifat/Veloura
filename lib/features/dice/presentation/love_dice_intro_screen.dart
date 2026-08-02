import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_design_tokens.dart';

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
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.42),
            radius: .78,
            colors: [Color(0x3DFF4D7D), Color(0xFF090B12)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: context.pop,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Save game',
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark_border),
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
                      color: colors.primary,
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
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                const _InfoCard(
                  icon: Icons.group,
                  title: '2 Players',
                  subtitle: 'Best with your partner',
                ),
                const SizedBox(height: 10),
                const _InfoCard(
                  icon: Icons.local_fire_department,
                  title: 'Spicy level',
                  subtitle: 'Medium   🔥 🔥 ☆',
                  accent: true,
                ),
                const SizedBox(height: 10),
                const _InfoCard(
                  icon: Icons.auto_awesome,
                  title: 'What to expect',
                  subtitle: 'Fun, flirty and a little bit spicy 😉',
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _navigating ? null : _startGame,
                    iconAlignment: IconAlignment.end,
                    icon: _navigating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(_navigating ? 'Starting…' : 'Start game'),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: () => _showHowToPlay(context),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('How to play?'),
                  style: TextButton.styleFrom(foregroundColor: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Text(
          'Roll both dice together. One die chooses the action and the other chooses where. Pass the turn after each result.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent ? colors.primary : colors.textSecondary, size: 30),
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
                Text(subtitle, style: TextStyle(color: colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
