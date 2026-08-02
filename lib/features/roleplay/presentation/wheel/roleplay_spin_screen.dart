import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/roleplay/domain/roleplay_scenario.dart';
import 'package:veloura/features/roleplay/presentation/wheel/roleplay_wheel_controller.dart';
import 'package:veloura/features/roleplay/presentation/wheel/widgets/roleplay_spin_wheel.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/game/game_shell.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/shared/widgets/game/result_sheet.dart';
import 'package:veloura/shared/widgets/game/secondary_text_button.dart';
import 'package:veloura/shared/widgets/loading_shimmer.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Spins to pick a roleplay category + scenario, then reveals it with the
/// couple's real names swapped in. Same shell/interaction pattern as
/// [TruthOrDareWheelScreen], recolored for Passionate Roleplay.
class RoleplaySpinScreen extends ConsumerStatefulWidget {
  const RoleplaySpinScreen({super.key});

  @override
  ConsumerState<RoleplaySpinScreen> createState() => _RoleplaySpinScreenState();
}

class _RoleplaySpinScreenState extends ConsumerState<RoleplaySpinScreen>
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
      duration: const Duration(seconds: 5),
    )..addListener(_tickHaptic);
  }

  void _tickHaptic() {
    final degrees = _rotation.value * 180 / math.pi;
    final tick = (degrees / RoleplayWheelMath.segmentDegrees).floor();
    final now = DateTime.now();
    if (tick != _lastTick &&
        now.difference(_lastHaptic) >= const Duration(milliseconds: 32)) {
      _lastTick = tick;
      _lastHaptic = now;
      unawaited(HapticFeedback.selectionClick());
    }
  }

  Future<void> _spin() async {
    final current = ref.read(roleplayWheelControllerProvider).asData?.value;
    if (current == null || current.spinning) return;
    ref.read(roleplayWheelControllerProvider.notifier).prepareSpin();
    final prepared = ref.read(roleplayWheelControllerProvider).requireValue;
    final endDegrees = RoleplayWheelMath.nextEndDegrees(
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

    await ref.read(roleplayWheelControllerProvider.notifier).resolveScenario();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _resultOpen = true);
    await ResultSheet.show<void>(context, child: const _ScenarioResult());
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
              Text(
                'Passionate Roleplay',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'The wheel decides a category, then deals a scenario for the '
                'two of you to act out - roles are re-cast at random every spin.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SecondaryTextButton(
                label: 'Got it',
                onPressed: () => Navigator.pop(context),
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
    final wheel = ref.watch(roleplayWheelControllerProvider);
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
          onRetry: () => ref.invalidate(roleplayWheelControllerProvider),
        ),
      ),
      data: (state) {
        final hideHeadline = state.spinning || _resultOpen;
        final diameter = math.min(MediaQuery.sizeOf(context).width - 72, 320.0);
        return GameShell(
          title: 'Passionate Roleplay',
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
                'SPIN FOR YOUR\nNEXT SCENE',
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
              builder: (context, _) => RoleplaySpinWheel(
                rotation: _rotation.value,
                winningSegment: state.scenario == null ? null : state.target,
              ),
            ),
          ),
          footnote: const Text('The landed category chooses the scenario'),
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

/// Launches at full speed and eases into the selected segment.
class _RouletteSpinCurve extends Curve {
  const _RouletteSpinCurve();

  @override
  double transformInternal(double t) => 1 - math.pow(1 - t, 5).toDouble();
}

class _ScenarioResult extends ConsumerStatefulWidget {
  const _ScenarioResult();

  @override
  ConsumerState<_ScenarioResult> createState() => _ScenarioResultState();
}

class _ScenarioResultState extends ConsumerState<_ScenarioResult> {
  var _revealedTwists = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roleplayWheelControllerProvider).asData?.value;
    final scenario = state?.scenario;
    final session = ref.watch(gameSessionStateProvider).asData?.value;
    if (state == null || scenario == null || session == null) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final nameA = state.characterASecond ? session.b.name : session.a.name;
    final nameB = state.characterASecond ? session.a.name : session.b.name;
    final colors = AppColors.of(context);
    return SizedBox(
      height: math.min(MediaQuery.sizeOf(context).height * 0.68, 540),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Text(
                  _categoryLabel(scenario.roleplayCategory),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: scenario.favorite ? 'Remove favorite' : 'Favorite scenario',
                onPressed: () => ref
                    .read(roleplayWheelControllerProvider.notifier)
                    .toggleFavorite(),
                icon: Icon(
                  scenario.favorite ? Icons.favorite : Icons.favorite_border,
                  color: scenario.favorite ? GameTokens.rose : colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _ScenarioBox(
              scenario: scenario,
              nameA: nameA,
              nameB: nameB,
              revealedTwists: _revealedTwists,
              onRevealTwist: scenario.twists.isEmpty
                  ? null
                  : () => setState(
                      () => _revealedTwists = math.min(
                        _revealedTwists + 1,
                        scenario.twists.length,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryCta(
            label: 'Done',
            onPressed: () async {
              await ref.read(sessionControllerProvider.notifier).nextTurn();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          SecondaryTextButton(
            label: 'Another scene',
            onPressed: () {
              setState(() => _revealedTwists = 0);
              ref.read(roleplayWheelControllerProvider.notifier).another();
            },
          ),
        ],
      ),
    );
  }

  static String _categoryLabel(RoleplayCategory category) => switch (category) {
    RoleplayCategory.fantasy => 'FANTASY SCENE',
    RoleplayCategory.romance => 'ROMANCE SCENE',
    RoleplayCategory.adventure => 'ADVENTURE SCENE',
  };
}

/// Solid, on-brand gradient card carrying the scenario (no photo background),
/// matching Truth or Dare's `_PromptBox` treatment.
class _ScenarioBox extends StatelessWidget {
  const _ScenarioBox({
    required this.scenario,
    required this.nameA,
    required this.nameB,
    required this.revealedTwists,
    required this.onRevealTwist,
  });

  final RoleplayScenario scenario;
  final String nameA;
  final String nameB;
  final int revealedTwists;
  final VoidCallback? onRevealTwist;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GameTokens.cardRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: GameTokens.passionateRoleplay,
        ),
        border: Border.all(color: colors.primary.withValues(alpha: 0.45)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
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
              children: [
                Text(
                  scenario.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _RolePill(label: '$nameA \u2192 ${scenario.roleA}'),
                    _RolePill(label: '$nameB \u2192 ${scenario.roleB}'),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          scenario.describeFor(nameA: nameA, nameB: nameB),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        for (var index = 0; index < revealedTwists; index++)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              scenario.twists[index],
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (onRevealTwist != null && revealedTwists < scenario.twists.length) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onRevealTwist,
                    child: const Text(
                      'Reveal a twist',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
}
