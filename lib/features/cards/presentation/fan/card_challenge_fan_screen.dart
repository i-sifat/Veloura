import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:veloura/features/cards/domain/challenge_item.dart';
import 'package:veloura/features/cards/domain/intensity_deck.dart';
import 'package:veloura/features/cards/presentation/fan/fan_controller.dart';
import 'package:veloura/features/cards/presentation/fan/widgets/card_fan.dart';
import 'package:veloura/features/cards/presentation/fan/widgets/challenge_card_front.dart';
import 'package:veloura/features/cards/presentation/fan/widgets/consent_sheet.dart';
import 'package:veloura/features/premium/provider.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/game/game_app_bar.dart';
import 'package:veloura/shared/widgets/game/game_backdrop.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/shared/widgets/game/secondary_text_button.dart';
import 'package:veloura/shared/widgets/game/turn_chip_bar.dart';
import 'package:veloura/shared/widgets/loading_shimmer.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Twelve-card mystery draw with heat-first selection and optional categories.
class CardChallengeFanScreen extends ConsumerStatefulWidget {
  const CardChallengeFanScreen({super.key});

  @override
  ConsumerState<CardChallengeFanScreen> createState() =>
      _CardChallengeFanScreenState();
}

class _CardChallengeFanScreenState
    extends ConsumerState<CardChallengeFanScreen> {
  var _superhotConsentShown = false;

  Future<void> _pick(int number, CardFanState state) async {
    final premium = ref.read(isPremiumProvider);
    if (state.deck == IntensityDeck.superhot && !premium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Superhot cards unlock with Premium.')),
      );
      return;
    }
    if (state.deck == IntensityDeck.superhot && !_superhotConsentShown) {
      final accepted = await ConsentSheet.show(context);
      if (!mounted || accepted == null) return;
      if (!accepted) {
        ref
            .read(cardFanControllerProvider.notifier)
            .selectDeck(IntensityDeck.spicy);
        return;
      }
      _superhotConsentShown = true;
    }

    ref.read(cardFanControllerProvider.notifier).pickNumber(number);
    final picked = ref.read(cardFanControllerProvider).requireValue.selected;
    if (picked == null || !mounted) return;
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    final action = await showGeneralDialog<_RevealAction>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Challenge card',
      barrierColor: GameTokens.scrim,
      transitionDuration: GameTokens.sheetDuration,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _RevealCardDialog(item: picked, deck: state.deck, number: number),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
    );
    if (!mounted) return;
    switch (action) {
      case _RevealAction.done:
        await ref
            .read(cardFanControllerProvider.notifier)
            .completeSelected();
        await ref.read(sessionControllerProvider.notifier).nextTurn();
        break;
      case _RevealAction.skip:
        ref.read(cardFanControllerProvider.notifier).redeal();
        await ref.read(sessionControllerProvider.notifier).nextTurn();
        break;
      case null:
        ref.read(cardFanControllerProvider.notifier).redeal();
        break;
    }
  }

  void _showInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GameTokens.sheet,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pick a mystery card',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Choose heat first. Category is optional. Every number is a surprise.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SecondaryTextButton(
                label: 'Browse all challenges',
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/games/card-challenge/browse');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCategoryPicker(CardFanState state) async {
    final selected = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: GameTokens.sheet,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a category',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: state.category == null,
                    onSelected: (_) => Navigator.pop(context, 'all'),
                  ),
                  for (final category in ChallengeCategory.values)
                    ChoiceChip(
                      label: Text(_categoryLabel(category)),
                      selected: state.category == category,
                      onSelected: (_) => Navigator.pop(context, category),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    ref.read(cardFanControllerProvider.notifier).selectCategory(
      selected == 'all' ? null : selected as ChallengeCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fan = ref.watch(cardFanControllerProvider);
    return fan.when(
      loading: () => const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(20),
          child: LoadingShimmer(height: 520),
        ),
      ),
      error: (error, _) => Scaffold(
        body: ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(cardFanControllerProvider),
        ),
      ),
      data: (state) {
        final premium = ref.watch(isPremiumProvider);
        final locked = state.deck == IntensityDeck.superhot && !premium;
        return Scaffold(
          body: GameBackdrop(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GameTokens.screenPadH,
                ),
                child: Column(
                  children: [
                    GameAppBar(
                      title: 'Card challenge',
                      leading: IconButton(
                        tooltip: 'Games',
                        onPressed: () => context.go('/games'),
                        icon: const Icon(Icons.home_outlined, size: 22),
                      ),
                      onInfo: _showInfo,
                    ),
                    const TurnChipBar(),
                    const SizedBox(height: 12),
                    _DeckSelector(
                      selected: state.deck,
                      onSelected: ref
                          .read(cardFanControllerProvider.notifier)
                          .selectDeck,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'CHOOSE ONE',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        ActionChip(
                          avatar: const Icon(Icons.tune, size: 16),
                          label: Text(
                            state.category == null
                                ? 'All categories'
                                : _categoryLabel(state.category!),
                          ),
                          onPressed: () => _showCategoryPicker(state),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: state.pool.isEmpty
                          ? Center(
                              child: Text(
                                'No unused cards match this filter.',
                                style: TextStyle(
                                  color: AppColors.of(context).textSecondary,
                                ),
                              ),
                            )
                          : CardFan(
                              deck: state.deck,
                              locked: locked,
                              onPick: (number) => _pick(number, state),
                            ),
                    ),
                    if (locked) const _SuperhotLockBanner(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Persistent notice shown while browsing the locked Superhot deck.
class _SuperhotLockBanner extends StatelessWidget {
  const _SuperhotLockBanner();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFF7D9E6),
      borderRadius: BorderRadius.circular(GameTokens.cardRadius),
    ),
    child: const Text(
      'Superhot cards unlock with Premium.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Color(0xFF7D123D), fontWeight: FontWeight.w600),
    ),
  );
}

class _DeckSelector extends StatelessWidget {
  const _DeckSelector({required this.selected, required this.onSelected});

  final IntensityDeck selected;
  final ValueChanged<IntensityDeck> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final deck in IntensityDeck.values) ...[
        if (deck.index > 0) const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelected(deck),
            child: AnimatedContainer(
              duration: GameTokens.fadeDuration,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: selected == deck
                    ? LinearGradient(colors: deck.gradient)
                    : null,
                color: selected == deck ? null : GameTokens.glass,
                border: Border.all(
                  color: selected == deck
                      ? deck.glow.withValues(alpha: 0.70)
                      : GameTokens.hairline,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(deck.icon, size: 16),
                  const SizedBox(height: 3),
                  Text(
                    deck.label,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

enum _RevealAction { done, skip }

class _RevealCardDialog extends ConsumerStatefulWidget {
  const _RevealCardDialog({
    required this.item,
    required this.deck,
    required this.number,
  });

  final ChallengeItem item;
  final IntensityDeck deck;
  final int number;

  @override
  ConsumerState<_RevealCardDialog> createState() => _RevealCardDialogState();
}

class _RevealCardDialogState extends ConsumerState<_RevealCardDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    unawaited(_flip.forward().whenComplete(HapticFeedback.mediumImpact));
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveItem =
        ref.watch(cardFanControllerProvider).asData?.value.selected ??
        widget.item;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: liveItem.favorite
                        ? 'Remove favorite'
                        : 'Favorite',
                    onPressed: () => ref
                        .read(cardFanControllerProvider.notifier)
                        .toggleFavorite(),
                    icon: Icon(
                      liveItem.favorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Share challenge',
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Veloura challenge: ${liveItem.title}\n${liveItem.description}',
                      ),
                    ),
                    icon: const Icon(Icons.share_outlined),
                  ),
                ],
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _flip,
                builder: (context, _) {
                  final angle = math.pi * _flip.value;
                  final showFront = _flip.value >= 0.5;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(angle),
                    child: SizedBox(
                      width: 230,
                      height: 340,
                      child: showFront
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: ChallengeCardFront(
                                item: liveItem,
                                deck: widget.deck,
                                number: widget.number,
                              ),
                            )
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: widget.deck.gradient,
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Center(
                                child: Icon(
                                  widget.deck.icon,
                                  size: 72,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
              const Spacer(),
              PrimaryCta(
                label: 'Done',
                onPressed: () => Navigator.pop(context, _RevealAction.done),
              ),
              const SizedBox(height: 4),
              SecondaryTextButton(
                label: 'Skip',
                onPressed: () => Navigator.pop(context, _RevealAction.skip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _categoryLabel(ChallengeCategory category) => switch (category) {
  ChallengeCategory.romance => 'Romance',
  ChallengeCategory.adventure => 'Adventure',
  ChallengeCategory.connection => 'Connection',
  ChallengeCategory.playful => 'Playful',
  ChallengeCategory.kindness => 'Kindness',
  ChallengeCategory.creativity => 'Creativity',
  ChallengeCategory.wellness => 'Wellness',
  ChallengeCategory.surprise => 'Surprise',
};
