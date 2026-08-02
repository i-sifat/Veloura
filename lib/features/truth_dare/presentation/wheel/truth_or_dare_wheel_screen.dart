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

/// Fast roulette that decides Truth or Dare, then reveals a matching prompt.
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
      // Fixed 5s throw every spin, per spec: full speed out of the gate,
      // then a long decelerating tail via the ease-out curve below.
      duration: const Duration(seconds: 5),
    )..addListener(_tickHaptic);
  }

  void _tickHaptic() {
    final degrees = _rotation.value * 180 / math.pi;
    final tick = (degrees / WheelMath.segmentDegrees).floor();
    final now = DateTime.now();
    if (tick != _lastTick &&
        now.difference(_lastHaptic) >= const Duration(milliseconds: 32)) {
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
    // Always continue forward (clockwise) from wherever the wheel currently
    // sits, so a repeated spin never has to wind backward to reach its
    // landing segment.
    final endDegrees = WheelMath.nextEndDegrees(
      currentDegrees: _settledRotation * 180 / math.pi,
      target: prepared.target,
      turns: prepared.turns,
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
        CurvedAnimation(parent: _animation, curve: const _RouletteSpinCurve()),
      );
      _lastTick = -1;
      await _animation.forward(from: 0);
      _settledRotation = end;
      await HapticFeedback.heavyImpact();
    }

    await ref.read(wheelControllerProvider.notifier).resolvePrompt();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _resultOpen = true);
    await ResultSheet.show<void>(context, child: const _WheelResult());
    if (mounted) setState(() => _resultOpen = false);
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
              Text('Truth or Dare', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              const Text(
                'The wheel decides Truth or Dare, then deals a matching prompt.',
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
          title: 'Truth or Dare',
          onInfo: _showInfo,
          headline: AnimatedOpacity(
            duration: GameTokens.fadeDuration,
            opacity: hideHeadline ? 0 : 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'LET THE WHEEL\nDECIDE',
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
          footnote: const Text('The landed segment chooses the prompt type'),
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

/// Launches at full speed and eases smoothly into the selected segment, like
/// a real roulette that starts fast and gradually slows to a stop.
class _RouletteSpinCurve extends Curve {
  const _RouletteSpinCurve();

  @override
  double transformInternal(double t) => 1 - math.pow(1 - t, 5).toDouble();
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
      height: math.min(MediaQuery.sizeOf(context).height * 0.62, 480),
      child: Column(
        children: [
          Row(
            children: [
              // Balances the trailing favorite button's width so the
              // headline below reads as centered in the row, not just
              // center-aligned text squeezed to the left of the icon.
              const SizedBox(width: 48),
              Expanded(
                child: Text(
                  'The wheel chose ${item.kind.name.toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: item.favorite ? 'Remove favorite' : 'Favorite prompt',
                onPressed: () => ref
                    .read(wheelControllerProvider.notifier)
                    .toggleFavorite(),
                icon: Icon(
                  item.favorite ? Icons.favorite : Icons.favorite_border,
                  color: item.favorite ? GameTokens.rose : colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Solid, on-brand card carrying the prompt (no photo background).
          // The prompt scrolls within this fixed area so it can never spill
          // under the Done button below.
          Expanded(
            child: _PromptBox(
              kind: item.kind.name,
              prompt: item.prompt,
              isTruth: isTruth,
            ),
          ),
          const SizedBox(height: 16),
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
            label: 'Another ${item.kind.name}',
            onPressed: () => ref.read(wheelControllerProvider.notifier).skip(),
          ),
        ],
      ),
    );
  }
}

/// The rich prompt surface: a solid, on-brand gradient (no photo) with a red
/// border, a high-contrast kind chip and a centered, scrollable prompt.
class _PromptBox extends StatelessWidget {
  const _PromptBox({
    required this.kind,
    required this.prompt,
    required this.isTruth,
  });

  final String kind;
  final String prompt;
  final bool isTruth;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GameTokens.cardRadius),
        // Solid, premium gradient instead of the old hero photo: always
        // contrasts cleanly with the TRUTH/DARE pill, regardless of device
        // or content.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: GameTokens.truthOrDare,
        ),
        border: Border.all(color: colors.primary.withValues(alpha: 0.45)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Soft top sheen for depth now that there's no photo to add it.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33FFFFFF), Colors.transparent],
                stops: [0, 0.55],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    // Bumped alpha + a white hairline so the pill stays
                    // clearly readable against the new solid background.
                    color: (isTruth ? const Color(0xFF4B2B8F) : GameTokens.rose)
                        .withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    kind.toUpperCase(),
                    style: TextStyle(
                      color: isTruth ? const Color(0xFFE6DBFF) : Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      prompt,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
