import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/positions/presentation/positions_controller.dart';
import 'package:veloura/features/positions/presentation/widgets/beat_rail.dart';
import 'package:veloura/features/positions/presentation/widgets/held_card.dart';
import 'package:veloura/features/positions/presentation/widgets/position_card.dart';
import 'package:veloura/features/positions/presentation/widgets/position_wheel.dart';
import 'package:veloura/features/premium/provider.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/game/game_shell.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/shared/widgets/game/secondary_text_button.dart';
import 'package:veloura/shared/widgets/loading_shimmer.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Dial-to-card-to-beats Creative Positions game.
class CreativePositionsScreen extends ConsumerStatefulWidget {
  const CreativePositionsScreen({super.key});

  @override
  ConsumerState<CreativePositionsScreen> createState() =>
      _CreativePositionsScreenState();
}

class _CreativePositionsScreenState
    extends ConsumerState<CreativePositionsScreen> {
  Timer? _spinTimer;
  Timer? _cooldownTimer;
  DateTime? _beatShownAt;

  void _spin([double omega = 4.8]) {
    ref.read(positionsControllerProvider.notifier).beginSpin(omega: omega);
    _spinTimer?.cancel();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _spinTimer = Timer(
      reduceMotion
          ? GameTokens.fadeDuration
          : const Duration(milliseconds: 4500),
      () {
        if (mounted) {
          ref.read(positionsControllerProvider.notifier).finishSpin();
          unawaited(HapticFeedback.heavyImpact());
        }
      },
    );
  }

  void _advanceBeat() {
    final now = DateTime.now();
    final shown = _beatShownAt;
    if (shown != null && now.difference(shown) < const Duration(milliseconds: 1200)) {
      return;
    }
    ref.read(positionsControllerProvider.notifier).advanceBeat();
    _beatShownAt = now;
    unawaited(HapticFeedback.lightImpact());
  }

  Future<void> _finishRound() async {
    ref.read(positionsControllerProvider.notifier).finishRound();
    await ref.read(sessionControllerProvider.notifier).nextTurn();
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) ref.read(positionsControllerProvider.notifier).restart();
    });
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
              Text('Creative Positions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              const Text(
                'Flick the dial, hold to reveal, then follow each beat together.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final round = ref.watch(positionsControllerProvider);
    final session = ref.watch(sessionControllerProvider).asData?.value;
    return round.when(
      loading: () => const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(20),
          child: LoadingShimmer(height: 520),
        ),
      ),
      error: (error, _) => Scaffold(
        body: ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(positionsControllerProvider),
        ),
      ),
      data: (state) {
        final premium = ref.watch(isPremiumProvider);
        final leader = session?.active.name ?? 'You';
        return GameShell(
          title: 'Creative Positions',
          leading: IconButton(
            tooltip: 'Games',
            onPressed: () => context.go('/games'),
            icon: const Icon(Icons.home_outlined, size: 22),
          ),
          onInfo: _showInfo,
          headline: _headline(context, state, leader),
          hero: AnimatedSwitcher(
            duration: GameTokens.sheetDuration,
            child: _hero(state, premium),
          ),
          footnote: _footnote(context, state),
          cta: _actions(state),
        );
      },
    );
  }

  Widget? _headline(
    BuildContext context,
    PositionsRoundState state,
    String leader,
  ) {
    if (state.stage != RoundStage.invite && state.stage != RoundStage.cooldown) {
      return null;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '${leader.toUpperCase()},\nFLICK TO CHOOSE',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.02,
        ),
      ),
    );
  }

  Widget _hero(PositionsRoundState state, bool premium) => switch (state.stage) {
    RoundStage.invite || RoundStage.spinning || RoundStage.cooldown =>
      PositionWheel(
        key: const ValueKey('position-wheel'),
        degrees: state.dialDegrees,
        zoneCount: premium ? 6 : 5,
        spinning: state.stage == RoundStage.spinning,
        onFlick: state.stage == RoundStage.invite ? _spin : null,
      ),
    RoundStage.held => HeldCard(
      key: const ValueKey('held-card'),
      zone: state.zone!,
      onReveal: () => ref.read(positionsControllerProvider.notifier).reveal(),
    ),
    RoundStage.revealed => PositionCard(
      key: ValueKey(state.position!.id),
      position: state.position!,
    ),
    RoundStage.tempo => BeatRail(
      key: ValueKey('beat-${state.beatIndex}'),
      beats: state.beats,
      index: state.beatIndex,
      onAdvance: _advanceBeat,
    ),
  };

  Widget? _footnote(BuildContext context, PositionsRoundState state) {
    final colors = AppColors.of(context);
    final text = switch (state.stage) {
      RoundStage.invite => 'Flick it, or use the button',
      RoundStage.held => 'Press and hold to reveal',
      RoundStage.cooldown => 'Stay close.',
      _ => null,
    };
    return text == null
        ? null
        : Text(text, style: TextStyle(color: colors.textSecondary));
  }

  Widget _actions(PositionsRoundState state) => switch (state.stage) {
    RoundStage.invite => PrimaryCta(
      label: 'Spin the dial',
      icon: Icons.rotate_right,
      onPressed: _spin,
    ),
    RoundStage.spinning => const PrimaryCta(
      label: 'Spinning…',
      busy: true,
      onPressed: null,
    ),
    RoundStage.held => const SizedBox.shrink(),
    RoundStage.revealed => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryCta(
          label: "We're in position",
          onPressed: () {
            ref.read(positionsControllerProvider.notifier).enterTempo();
            _beatShownAt = DateTime.now();
          },
        ),
        SecondaryTextButton(
          label: 'Pass',
          onPressed: () => ref.read(positionsControllerProvider.notifier).pass(),
        ),
      ],
    ),
    RoundStage.tempo => state.beatIndex == state.beats.length - 1
        ? PrimaryCta(label: 'Done', onPressed: _finishRound)
        : const SizedBox.shrink(),
    RoundStage.cooldown => const PrimaryCta(
      label: 'Spin again',
      onPressed: null,
    ),
  };
}
