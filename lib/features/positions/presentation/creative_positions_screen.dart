import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/positions/domain/session_intensity.dart';
import 'package:veloura/features/positions/presentation/positions_controller.dart';
import 'package:veloura/features/positions/presentation/widgets/held_card.dart';
import 'package:veloura/features/positions/presentation/widgets/position_card.dart';
import 'package:veloura/features/positions/presentation/widgets/position_wheel.dart';
import 'package:veloura/features/premium/provider.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/features/tempo/presentation/widgets/tempo_ring.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/game/game_shell.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/shared/widgets/game/secondary_text_button.dart';
import 'package:veloura/shared/widgets/loading_shimmer.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Dial-to-card-to-session Creative Positions game. The dial itself is
/// inherited 1:1 from the Truth or Dare wheel screen: an explicit
/// [AnimationController]-driven tween spins forward-only to a fairly
/// chosen zone, mirroring `TruthOrDareWheelScreen` down to the easing
/// curve, just with position zones instead of Truth/Dare segments.
class CreativePositionsScreen extends ConsumerStatefulWidget {
  const CreativePositionsScreen({super.key});

  @override
  ConsumerState<CreativePositionsScreen> createState() =>
      _CreativePositionsScreenState();
}

class _CreativePositionsScreenState
    extends ConsumerState<CreativePositionsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation;
  late final AnimationController _pulse;
  Animation<double> _rotation = const AlwaysStoppedAnimation(0);
  double _settledRotation = 0;
  Timer? _cooldownTimer;
  var _wasRunningBeforePause = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animation = AnimationController(
      vsync: this,
      // Same fixed 5s throw as the Truth or Dare wheel.
      duration: const Duration(seconds: 5),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: PositionSessionIntensity.soft.beatPeriod,
    );
  }

  Future<void> _spin() async {
    final current = ref.read(positionsControllerProvider).asData?.value;
    if (current == null || current.stage == RoundStage.spinning) return;
    final premium = ref.read(isPremiumProvider);
    final zoneCount = premium ? 6 : 5;
    ref.read(positionsControllerProvider.notifier).beginSpin();
    final prepared = ref.read(positionsControllerProvider).requireValue;
    final target = prepared.zone!.index;
    // Always continue forward (clockwise) from wherever the wheel
    // currently sits, so a repeated spin never has to wind backward to
    // reach its landing zone.
    final endDegrees = PositionWheelMath.nextEndDegrees(
      currentDegrees: _settledRotation * 180 / math.pi,
      target: target,
      turns: prepared.turns,
      zoneCount: zoneCount,
    );
    final end = endDegrees * math.pi / 180;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion) {
      _settledRotation = end;
      _rotation = AlwaysStoppedAnimation(end);
      setState(() {});
      await Future<void>.delayed(GameTokens.fadeDuration);
    } else {
      _rotation = Tween<double>(begin: _settledRotation, end: end).animate(
        CurvedAnimation(parent: _animation, curve: const _DialSpinCurve()),
      );
      await _animation.forward(from: 0);
      _settledRotation = end;
      await HapticFeedback.heavyImpact();
    }

    if (!mounted) return;
    ref.read(positionsControllerProvider.notifier).finishSpin();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(positionsControllerProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasRunningBeforePause =
          ref.read(positionsControllerProvider).asData?.value.stage ==
          RoundStage.tempo;
      notifier.pauseSession();
      _pulse.stop();
    } else if (state == AppLifecycleState.resumed && _wasRunningBeforePause) {
      notifier.resumeSession();
      _syncPulse(ref.read(positionsControllerProvider).requireValue);
      _wasRunningBeforePause = false;
    }
  }

  /// Round finished (timed out or tapped Done): pass the turn and arm the
  /// cooldown restart. The controller already moved to [RoundStage.cooldown].
  Future<void> _afterRoundComplete() async {
    await ref.read(sessionControllerProvider.notifier).nextTurn();
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) ref.read(positionsControllerProvider.notifier).restart();
    });
  }

  void _onRoundChanged(
    PositionsRoundState? previous,
    PositionsRoundState? next,
  ) {
    if (previous?.stage != next?.stage && next != null) {
      _syncPulse(next);
    }
    if (previous?.stage == RoundStage.tempo &&
        next?.stage == RoundStage.cooldown) {
      unawaited(_afterRoundComplete());
    }
  }

  /// Runs the heartbeat pulse while a session is active; stops it otherwise.
  void _syncPulse(PositionsRoundState state) {
    if (state.stage != RoundStage.tempo) {
      _pulse.stop();
      _pulse.value = 0;
      return;
    }
    _pulse.duration = state.sessionIntensity.beatPeriod;
    _pulse.repeat();
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
                'Creative Positions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Spin the wheel to choose a zone, hold to reveal, then hold your position while the heartbeat ring counts down.',
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
    WidgetsBinding.instance.removeObserver(this);
    _animation.dispose();
    _pulse.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final round = ref.watch(positionsControllerProvider);
    final session = ref.watch(sessionControllerProvider).asData?.value;
    ref.listen<PositionsRoundState?>(
      positionsControllerProvider.select((state) => state.asData?.value),
      _onRoundChanged,
    );
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
            child: _hero(context, state, premium),
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
    if (state.stage != RoundStage.invite &&
        state.stage != RoundStage.cooldown) {
      return null;
    }
    return Align(
      alignment: Alignment.center,
      child: Text(
        '${leader.toUpperCase()},\nSPIN TO CHOOSE',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.02,
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, PositionsRoundState state, bool premium) =>
      switch (state.stage) {
        RoundStage.invite ||
        RoundStage.spinning ||
        RoundStage.cooldown => _wheel(context, state, premium),
        RoundStage.held => HeldCard(
          key: const ValueKey('held-card'),
          zone: state.zone!,
          onReveal: () =>
              ref.read(positionsControllerProvider.notifier).reveal(),
        ),
        RoundStage.revealed => PositionCard(
          key: ValueKey(state.position!.id),
          position: state.position!,
        ),
        RoundStage.tempo => TempoRing(
          key: ValueKey('session-${state.sessionSeconds}'),
          animation: _pulse,
          label: state.sessionIntensity.label,
          secondsLeft: state.sessionSecondsLeft,
          progress: state.sessionProgress,
          running: true,
          finale: false,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
        ),
      };

  Widget _wheel(BuildContext context, PositionsRoundState state, bool premium) {
    final zoneCount = premium ? 6 : 5;
    final diameter = math.min(MediaQuery.sizeOf(context).width - 72, 320.0);
    return SizedBox.square(
      key: const ValueKey('position-wheel'),
      dimension: diameter,
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (context, _) => PositionWheel(
          rotation: _rotation.value,
          zoneCount: zoneCount,
          winningZoneIndex:
              state.stage == RoundStage.spinning || state.zone == null
              ? null
              : state.zone!.index,
        ),
      ),
    );
  }

  Widget? _footnote(BuildContext context, PositionsRoundState state) {
    final colors = AppColors.of(context);
    final text = switch (state.stage) {
      RoundStage.invite => 'The landed zone chooses your position',
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
      label: 'Spin the wheel',
      icon: Icons.refresh,
      onPressed: () => unawaited(_spin()),
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
          onPressed: () =>
              ref.read(positionsControllerProvider.notifier).enterTempo(),
        ),
        SecondaryTextButton(
          label: 'Pass',
          onPressed: () =>
              ref.read(positionsControllerProvider.notifier).pass(),
        ),
      ],
    ),
    RoundStage.tempo => SecondaryTextButton(
      label: 'Done',
      onPressed: () =>
          ref.read(positionsControllerProvider.notifier).finishSession(),
    ),
    RoundStage.cooldown => const PrimaryCta(
      label: 'Spin again',
      onPressed: null,
    ),
  };
}

/// Launches at full speed and eases smoothly into the selected zone -
/// identical curve to the Truth or Dare wheel's `_RouletteSpinCurve`.
class _DialSpinCurve extends Curve {
  const _DialSpinCurve();

  @override
  double transformInternal(double t) => 1 - math.pow(1 - t, 5).toDouble();
}
