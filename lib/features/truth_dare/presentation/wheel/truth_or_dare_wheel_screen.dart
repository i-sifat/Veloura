import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/features/truth_dare/domain/truth_dare_item.dart';
import 'package:veloura/features/truth_dare/presentation/wheel/wheel_controller.dart';
import 'package:veloura/features/truth_dare/presentation/wheel/widgets/spin_wheel.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/game/game_shell.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/shared/widgets/game/result_sheet.dart';
import 'package:veloura/shared/widgets/game/secondary_text_button.dart';
import 'package:veloura/shared/widgets/loading_shimmer.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Premium pinwheel entry mode over the existing Truth or Dare pack.
class TruthOrDareWheelScreen extends ConsumerStatefulWidget {
  const TruthOrDareWheelScreen({super.key});

  @override
  ConsumerState<TruthOrDareWheelScreen> createState() =>
      _TruthOrDareWheelScreenState();
}

class _TruthOrDareWheelScreenState
    extends ConsumerState<TruthOrDareWheelScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  Animation<double> _rotation = const AlwaysStoppedAnimation(0);
  double _settledRotation = 0;
  int _lastTick = -1;
  DateTime _lastHaptic = DateTime.fromMillisecondsSinceEpoch(0);
  bool _resultOpen = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..addListener(_tickHaptic);
  }

  void _tickHaptic() {
    final degrees = _rotation.value * 180 / math.pi;
    final tick = (degrees / WheelMath.segmentDegrees).floor();
    final now = DateTime.now();
    if (tick != _lastTick &&
        now.difference(_lastHaptic) >= const Duration(milliseconds: 45)) {
      _lastTick = tick;
      _lastHaptic = now;
      unawaited(HapticFeedback.selectionClick());
    }
  }

  Future<void> _spin() async {
    final current = ref.read(wheelControllerProvider).asData?.value;
    if (current == null || current.spinning) return;
    ref.read(wheelControllerProvider.notifier).prepareSpin();
    final prepared = ref.read(wheelControllerProvider).requireValue;
    final end = prepared.endDegrees * math.pi / 180;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion) {
      _settledRotation = end;
      _rotation = AlwaysStoppedAnimation(end);
      setState(() {});
      await Future<void>.delayed(GameTokens.fadeDuration);
    } else {
      _rotation = Tween<double>(begin: _settledRotation, end: end).animate(
        CurvedAnimation(
          parent: _animation,
          curve: const Cubic(0.12, 0.78, 0.06, 1),
        ),
      );
      _lastTick = -1;
      await _animation.forward(from: 0);
      _settledRotation = end;
      await HapticFeedback.heavyImpact();
    }

    await ref.read(wheelControllerProvider.notifier).resolvePrompt();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _resultOpen = true);
    await _showResultSheet();
    if (mounted) setState(() => _resultOpen = false);
  }

  Future<void> _showResultSheet() => ResultSheet.show<void>(
    context,
    child: const _WheelResult(),
  );

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
              Text('Truth or dare', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              const Text(
                'Spin for a surprise, or browse every card at your pace.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SecondaryTextButton(
                label: 'Browse all',
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/games/truth-or-dare/browse');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animation
      ..removeListener(_tickHaptic)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wheel = ref.watch(wheelControllerProvider);
    return wheel.when(
      loading: () => const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(20),
          child: LoadingShimmer(height: 520),
        ),
      ),
      error: (error, _) => Scaffold(
        body: ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(wheelControllerProvider),
        ),
      ),
      data: (state) {
        final hideHeadline = state.spinning || _resultOpen;
        final diameter = math.min(MediaQuery.sizeOf(context).width - 72, 320.0);
        return GameShell(
          title: 'Truth or dare',
          onInfo: _showInfo,
          leading: IconButton(
            tooltip: 'Games',
            onPressed: () => context.go('/games'),
            icon: const Icon(Icons.home_outlined, size: 22),
          ),
          headline: AnimatedOpacity(
            duration: GameTokens.fadeDuration,
            opacity: hideHeadline ? 0 : 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SPIN THE WHEEL\nTO PLAY',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.02,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          hero: SizedBox.square(
            dimension: diameter,
            child: AnimatedBuilder(
              animation: _rotation,
              builder: (context, _) => SpinWheel(
                rotation: _rotation.value,
                winningSegment: state.item == null ? null : state.target,
              ),
            ),
          ),
          footnote: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Superhot Roulette requires Premium.')),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department, size: 14, color: GameTokens.rose),
                  SizedBox(width: 6),
                  Text('Superhot Roulette'),
                  SizedBox(width: 6),
                  Icon(Icons.info_outline, size: 14),
                ],
              ),
            ),
          ),
          cta: PrimaryCta(
            label: 'Spin the wheel',
            icon: Icons.refresh,
            busy: state.spinning,
            onPressed: state.spinning ? null : () => unawaited(_spin()),
          ),
        );
      },
    );
  }
}

class _WheelResult extends ConsumerWidget {
  const _WheelResult();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wheelControllerProvider).asData?.value;
    final item = state?.item;
    if (state == null || item == null) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final isTruth = item.kind == TruthDareKind.truth;
    final colors = AppColors.of(context);
    return SizedBox(
      height: math.max(MediaQuery.sizeOf(context).height * 0.40, 300),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: item.favorite ? 'Remove favorite' : 'Favorite prompt',
              onPressed: () => ref
                  .read(wheelControllerProvider.notifier)
                  .toggleFavorite(),
              icon: Icon(
                item.favorite ? Icons.favorite : Icons.favorite_border,
                color: item.favorite ? GameTokens.rose : colors.textSecondary,
              ),
            ),
          ),
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (isTruth ? const Color(0xFF4B2B8F) : GameTokens.rose)
                  .withValues(alpha: isTruth ? 0.30 : 0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              item.kind.name.toUpperCase(),
              style: TextStyle(
                color: isTruth ? const Color(0xFFB39CFF) : GameTokens.rose,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Center(
              child: Text(
                item.prompt,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          PrimaryCta(
            label: 'Done',
            onPressed: () async {
              await ref.read(wheelControllerProvider.notifier).complete();
              await ref.read(sessionControllerProvider.notifier).nextTurn();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          SecondaryTextButton(
            label: 'Skip',
            onPressed: () => ref.read(wheelControllerProvider.notifier).skip(),
          ),
        ],
      ),
    );
  }
}
