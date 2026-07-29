import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/features/tempo/domain/tempo_round.dart';
import 'package:veloura/features/tempo/presentation/tempo_controller.dart';
import 'package:veloura/features/tempo/presentation/widgets/pulse_ring.dart';
import 'package:veloura/features/tempo/presentation/widgets/stage_dots.dart';
import 'package:veloura/shared/widgets/game/game_shell.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/shared/widgets/game/result_sheet.dart';
import 'package:veloura/shared/widgets/game/secondary_text_button.dart';
import 'package:veloura/theme/game_tokens.dart';

/// A no-reading pacing game built around a single visual pulse.
class FollowTheTempoScreen extends ConsumerStatefulWidget {
  const FollowTheTempoScreen({super.key});

  @override
  ConsumerState<FollowTheTempoScreen> createState() =>
      _FollowTheTempoScreenState();
}

class _FollowTheTempoScreenState extends ConsumerState<FollowTheTempoScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulse;
  DateTime? _lastHaptic;
  var _vibration = true;
  var _wasRunningBeforePause = false;
  var _resultOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulse = AnimationController(vsync: this, duration: kDefaultRound.first.beatPeriod);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _vibration = preferences.getBool('game_vibration') ?? true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(tempoControllerProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasRunningBeforePause =
          ref.read(tempoControllerProvider).status == TempoStatus.running;
      notifier.pause();
      _pulse.stop();
    } else if (state == AppLifecycleState.resumed && _wasRunningBeforePause) {
      notifier.resume();
      _syncPulse(ref.read(tempoControllerProvider));
      _wasRunningBeforePause = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tempoControllerProvider);
    ref.listen(tempoControllerProvider, _onTempoChanged);
    final running = state.status == TempoStatus.running;
    final activeDot = state.stageIndex.clamp(0, 2);
    return GameShell(
      title: 'Follow the Tempo',
      onInfo: _showInfo,
      hero: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseRing(
            animation: _pulse,
            label: state.instruction,
            running: running,
            finale: state.isFinale,
            reduceMotion: MediaQuery.disableAnimationsOf(context),
          ),
          const SizedBox(height: 16),
          StageDots(activeIndex: activeDot),
        ],
      ),
      footnote: state.stageIndex == 0
          ? Text(
              'Match the pulse',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            )
          : null,
      cta: running
          ? _StopButton(onPressed: _stop)
          : PrimaryCta(label: 'Start', onPressed: _start),
    );
  }

  void _onTempoChanged(TempoState? previous, TempoState next) {
    if (previous?.stageIndex != next.stageIndex ||
        previous?.status != next.status) {
      _syncPulse(next);
    }
    if (next.beatCount != previous?.beatCount &&
        next.status == TempoStatus.running &&
        !next.isFinale) {
      final now = DateTime.now();
      if (_vibration &&
          (_lastHaptic == null ||
              now.difference(_lastHaptic!) >= const Duration(milliseconds: 500))) {
        _lastHaptic = now;
        HapticFeedback.lightImpact();
      }
    }
    if (next.isFinale && previous?.isFinale != true && _vibration) {
      HapticFeedback.heavyImpact();
    }
    if (next.status == TempoStatus.complete &&
        previous?.status != TempoStatus.complete) {
      ref.read(sessionControllerProvider.notifier).nextTurn();
      WidgetsBinding.instance.addPostFrameCallback((_) => _showResult());
    }
  }

  void _syncPulse(TempoState state) {
    if (state.status != TempoStatus.running || state.isFinale) {
      _pulse.stop();
      if (state.isFinale) _pulse.value = 1;
      return;
    }
    _pulse.duration = kDefaultRound[state.stageIndex].beatPeriod;
    _pulse.repeat();
  }

  void _start() => ref.read(tempoControllerProvider.notifier).start();

  void _stop() {
    ref.read(tempoControllerProvider.notifier).stop();
    _pulse
      ..stop()
      ..value = 0;
  }

  Future<void> _showResult() async {
    if (!mounted || _resultOpen) return;
    _resultOpen = true;
    await ResultSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Round complete', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 24),
          PrimaryCta(
            label: 'Again',
            onPressed: () {
              Navigator.of(context).pop();
              _start();
            },
          ),
          SecondaryTextButton(
            label: 'Done',
            onPressed: () {
              Navigator.of(context).pop();
              _stop();
            },
          ),
        ],
      ),
    );
    _resultOpen = false;
  }

  void _showInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GameTokens.sheet,
      builder: (context) => const Padding(
        padding: EdgeInsets.all(24),
        child: SafeArea(
          top: false,
          child: Text('Match the pulse together. The pace builds across three stages.'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    super.dispose();
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: GameTokens.ctaHeight,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: GameTokens.rose,
        side: const BorderSide(color: GameTokens.rose, width: 1.5),
        shape: const StadiumBorder(),
      ),
      child: const Text('Stop'),
    ),
  );
}
