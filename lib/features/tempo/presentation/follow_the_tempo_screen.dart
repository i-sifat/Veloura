import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/features/tempo/domain/tempo_round.dart';
import 'package:veloura/features/tempo/presentation/tempo_controller.dart';
import 'package:veloura/features/tempo/presentation/widgets/stage_dots.dart';
import 'package:veloura/features/tempo/presentation/widgets/tempo_ring.dart';
import 'package:veloura/shared/widgets/game/game_shell.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/shared/widgets/game/result_sheet.dart';
import 'package:veloura/shared/widgets/game/secondary_text_button.dart';
import 'package:veloura/theme/game_tokens.dart';

/// A heartbeat-pacing game built around short tease tasks.
///
/// Each task runs for a short window (around 20 seconds) while the ring fills
/// clockwise and the center shows the tempo word plus the seconds remaining.
/// The ring resets for every task and pulses like a heartbeat along the way.
class FollowTheTempoScreen extends ConsumerStatefulWidget {
  const FollowTheTempoScreen({super.key});

  @override
  ConsumerState<FollowTheTempoScreen> createState() =>
      _FollowTheTempoScreenState();
}

class _FollowTheTempoScreenState extends ConsumerState<FollowTheTempoScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulse;
  var _vibration = true;
  var _wasRunningBeforePause = false;
  var _resultOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulse = AnimationController(
      vsync: this,
      duration: tempoBeatPeriod(kTempoTaskLabels.first),
    );
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
    final inRound = state.round.isNotEmpty;
    return GameShell(
      title: 'Follow the Tempo',
      onInfo: _showInfo,
      hero: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TempoRing(
            animation: _pulse,
            label: state.instruction,
            secondsLeft: state.secondsLeft,
            progress: state.progress,
            running: running,
            finale: state.isFinale,
            reduceMotion: MediaQuery.disableAnimationsOf(context),
          ),
          const SizedBox(height: 16),
          if (inRound)
            StageDots(
              total: state.round.length,
              activeIndex: state.taskIndex.clamp(0, state.round.length - 1),
            ),
        ],
      ),
      footnote: inRound
          ? Text(
              'Task ${(state.taskIndex + 1).clamp(1, state.round.length)} of ${state.round.length}',
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
    if (previous?.taskIndex != next.taskIndex ||
        previous?.status != next.status) {
      _syncPulse(next);
    }
    if (next.taskIndex != previous?.taskIndex &&
        next.status == TempoStatus.running &&
        _vibration) {
      HapticFeedback.lightImpact();
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
    final task = state.currentTask;
    if (state.status != TempoStatus.running || task == null) {
      _pulse.stop();
      if (state.isFinale) _pulse.value = 1;
      return;
    }
    _pulse.duration = task.beatPeriod;
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
          child: Text(
            'Take turns setting the pace. Each short task tells you how fast to move — slow and teasing, or fast and urgent. Follow the heartbeat ring and count down together.',
          ),
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
