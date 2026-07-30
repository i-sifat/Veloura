import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/onboarding/presentation/onboarding_controller.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Four-step first-launch introduction and couple setup.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pageCount = 4;

  final _pages = PageController();
  final _nameA = TextEditingController();
  final _nameB = TextEditingController();
  var _page = 0;
  var _saving = false;

  @override
  void dispose() {
    _pages.dispose();
    _nameA.dispose();
    _nameB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isLastPage = _page == _pageCount - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'VELOURA',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      letterSpacing: 3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_page + 1} / $_pageCount',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (_page + 1) / _pageCount,
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (value) => setState(() => _page = value),
                  children: [
                    const _IntroPage(
                      icon: Icons.favorite_rounded,
                      title: 'Make space for each other',
                      body:
                          'Playful games, thoughtful questions, and small daily rituals designed for two.',
                    ),
                    const _IntroPage(
                      icon: Icons.lock_outline,
                      title: 'Private by default',
                      body:
                          'Your names, favorites, progress, and game history stay on this device unless you choose a connected service later.',
                    ),
                    const _IntroPage(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Take turns, stay connected',
                      body:
                          'Veloura carries both of your names into every game and keeps track of whose turn comes next.',
                    ),
                    _PlayersPage(nameA: _nameA, nameB: _nameB),
                  ],
                ),
              ),
              PrimaryCta(
                label: isLastPage ? 'Start connecting' : 'Continue',
                icon: isLastPage ? Icons.favorite : Icons.arrow_forward,
                busy: _saving,
                onPressed: _saving ? null : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _next() async {
    if (_page < _pageCount - 1) {
      await _pages.nextPage(
        duration: GameTokens.sheetDuration,
        curve: Curves.easeOutCubic,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .finish(
            nameA: _nameA.text.trim().isEmpty ? 'You' : _nameA.text,
            nameB: _nameB.text.trim().isEmpty ? 'Partner' : _nameB.text,
          );
      if (mounted) context.go('/home');
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not finish setup. Please try again.'),
        ),
      );
    }
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: GameTokens.passionateRoleplay),
            boxShadow: [GameTokens.ctaShadow],
          ),
          child: Icon(icon, size: 48),
        ),
        const SizedBox(height: 32),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Text(
          body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: AppColors.of(context).textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _PlayersPage extends StatelessWidget {
  const _PlayersPage({required this.nameA, required this.nameB});
  final TextEditingController nameA;
  final TextEditingController nameB;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Column(
        children: [
          const Icon(
            Icons.people_alt_outlined,
            size: 64,
            color: GameTokens.roseLight,
          ),
          const SizedBox(height: 18),
          Text(
            "Who's playing?",
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved on this device. You can change these names later in Profile.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.of(context).textSecondary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameA,
            maxLength: 12,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your name',
              prefixIcon: Icon(Icons.person_outline),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameB,
            maxLength: 12,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: "Partner's name",
              prefixIcon: Icon(Icons.favorite_outline),
              counterText: '',
            ),
          ),
        ],
      ),
    ),
  );
}
