import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/onboarding/presentation/onboarding_controller.dart';
import 'package:veloura/features/onboarding/presentation/onboarding_pages.dart';
import 'package:veloura/features/onboarding/presentation/onboarding_tokens.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';

/// Six-screen first-launch experience and couple setup.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  final _nameA = TextEditingController();
  final _nameB = TextEditingController();
  var _page = 0;
  var _saving = false;
  var _yourSex = 'female';
  var _partnerSex = 'female';

  @override
  void dispose() {
    _pages.dispose();
    _nameA.dispose();
    _nameB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: OnboardingTokens.background,
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: OnboardingTokens.backgroundGradient),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: OnboardingTokens.maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                OnboardingTokens.pagePadding,
                4,
                OnboardingTokens.pagePadding,
                24,
              ),
              child: Column(
                children: [
                  _OnboardingNav(
                    page: _page,
                    onBack: _back,
                    onSkip: () => _goTo(OnboardingTokens.setupStartIndex),
                  ),
                  Expanded(child: _pageView()),
                  const SizedBox(height: 16),
                  _OnboardingFooter(
                    page: _page,
                    saving: _saving,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _pageView() => PageView(
    controller: _pages,
    physics: const NeverScrollableScrollPhysics(),
    onPageChanged: (value) => setState(() => _page = value),
    children: [
      const OnboardingIntroPage(
        variant: 0,
        brand: true,
        title: 'Stronger together',
        body: 'Fun and intimate games that bring you closer, every day.',
      ),
      const OnboardingIntroPage(
        variant: 1,
        title: 'Deep conversations\nand playful moments',
        body: 'From flirty questions to spicy challenges, every game is designed to spark connection.',
      ),
      const OnboardingIntroPage(
        variant: 2,
        title: 'Track your journey\nand grow together',
        body: 'Celebrate your progress, keep your streak alive and make memories as a couple.',
      ),
      NamesPage(nameA: _nameA, nameB: _nameB),
      SexPage(
        yours: _yourSex,
        partners: _partnerSex,
        onYoursChanged: (value) => setState(() => _yourSex = value),
        onPartnersChanged: (value) => setState(() => _partnerSex = value),
      ),
      const ReadyPage(),
    ],
  );

  Future<void> _next() async {
    if (_page < OnboardingTokens.pageCount - 1) {
      await _goTo(_page + 1);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(onboardingControllerProvider.notifier).finish(
        nameA: _nameA.text.trim().isEmpty ? 'You' : _nameA.text.trim(),
        nameB: _nameB.text.trim().isEmpty ? 'Partner' : _nameB.text.trim(),
      );
      if (mounted) context.go('/home');
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not finish setup. Please try again.')),
      );
    }
  }

  Future<void> _back() async {
    if (_page > 0) await _goTo(_page - 1);
  }

  Future<void> _goTo(int page) => _pages.animateToPage(
    page,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
  );
}

class _OnboardingNav extends StatelessWidget {
  const _OnboardingNav({required this.page, required this.onBack, required this.onSkip});

  final int page;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        if (page >= OnboardingTokens.setupStartIndex && page < OnboardingTokens.pageCount - 1)
          IconButton(
            key: const ValueKey('onboarding-back'),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          )
        else
          const SizedBox(width: 48),
        const Spacer(),
        if (page < OnboardingTokens.setupStartIndex)
          TextButton(
            key: const ValueKey('onboarding-skip'),
            onPressed: onSkip,
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
      ],
    ),
  );
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({required this.page, required this.saving, required this.onPressed});

  final int page;
  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final intro = page < OnboardingTokens.setupStartIndex;
    return Row(
      children: [
        if (intro) _Dots(current: page),
        if (intro) const Spacer(),
        if (intro && page < 2)
          SizedBox.square(
            dimension: 54,
            child: IconButton.filled(
              key: const ValueKey('onboarding-next'),
              tooltip: 'Continue',
              onPressed: onPressed,
              style: IconButton.styleFrom(backgroundColor: OnboardingTokens.pink),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          )
        else
          Expanded(
            child: PrimaryCta(
              key: const ValueKey('onboarding-next'),
              label: switch (page) {
                2 => 'Get started',
                5 => 'Go to Home',
                _ => 'Continue',
              },
              busy: saving,
              onPressed: saving ? null : onPressed,
            ),
          ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      OnboardingTokens.setupStartIndex,
      (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: index == current ? OnboardingTokens.pink : OnboardingTokens.border,
        ),
      ),
    ),
  );
}
