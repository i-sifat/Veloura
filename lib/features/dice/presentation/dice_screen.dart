import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:veloura/features/dice/domain/dice_roll_record.dart';
import 'package:veloura/features/dice/presentation/dice_controller.dart';
import 'package:veloura/features/dice/presentation/dice_state.dart';
import 'package:veloura/features/dice/presentation/widgets/dice_cube.dart';
import 'package:veloura/features/dice/presentation/widgets/dice_tray.dart';
import 'package:veloura/features/dice/presentation/widgets/die_motion.dart';
import 'package:veloura/features/premium/provider.dart';
import 'package:veloura/shared/widgets/empty_state.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/loading_shimmer.dart';

/// Animated, shake-enabled Dice game.
class DiceScreen extends ConsumerStatefulWidget {
  const DiceScreen({super.key});

  @override
  ConsumerState<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends ConsumerState<DiceScreen> {
  StreamSubscription<AccelerometerEvent>? _shakeSubscription;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _shakeSubscription = accelerometerEventStream().listen(
      _onAcceleration,
      onError: (_) {},
    );
  }

  void _onAcceleration(AccelerometerEvent event) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final now = DateTime.now();
    if (magnitude > 22 &&
        now.difference(_lastShake) > const Duration(seconds: 2)) {
      _lastShake = now;
      unawaited(_roll());
    }
  }

  Future<void> _roll() async {
    final diceValue = ref.read(diceControllerProvider).asData?.value;
    if (diceValue == null || diceValue.status == DiceRollStatus.rolling) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      await HapticFeedback.selectionClick();
    } else {
      await HapticFeedback.mediumImpact();
    }
    await ref.read(diceControllerProvider.notifier).roll(
      animationDuration: reduceMotion ? Duration.zero : DieMotion.totalDuration,
    );
  }

  @override
  void dispose() {
    unawaited(_shakeSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dice = ref.watch(diceControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dice')),
      body: dice.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingShimmer(height: 280),
        ),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(diceControllerProvider),
        ),
        data: (state) => _DiceBody(state: state, onRoll: _roll),
      ),
    );
  }
}

class _DiceBody extends ConsumerWidget {
  const _DiceBody({required this.state, required this.onRoll});

  final DiceState state;
  final Future<void> Function() onRoll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(diceControllerProvider.notifier);
    final premium = ref.watch(isPremiumProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        _DiceStage(state: state, onRoll: onRoll),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: state.status == DiceRollStatus.rolling ? null : onRoll,
          icon: const Icon(Icons.casino),
          label: Text(
            state.status == DiceRollStatus.rolling ? 'Rolling…' : 'Roll dice',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the tray, tap Roll, or shake your phone',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Add intensity / time die'),
          subtitle: const Text('Roll three dice instead of two'),
          value: state.useThirdDie,
          onChanged: state.status == DiceRollStatus.rolling
              ? null
              : controller.setThirdDie,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(premium ? Icons.tune : Icons.lock_outline),
          title: const Text('Custom dice faces'),
          subtitle: Text(
            premium
                ? (state.customFacesEnabled
                      ? 'Custom set active'
                      : 'Create your own set')
                : 'Premium feature',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => premium
              ? _showCustomFaces(context, ref, state)
              : _showPremiumMessage(context),
        ),
        const SizedBox(height: 24),
        Text('Roll history', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (state.history.isEmpty)
          const EmptyState(
            title: 'No rolls yet',
            message: 'Give it a shake to create your first combination.',
            icon: Icons.casino_outlined,
          )
        else
          ...state.history.map(
            (record) => _HistoryTile(
              record: record,
              onTap: () => controller.selectRecord(record),
              onFavorite: () => controller.toggleFavorite(record.id),
            ),
          ),
      ],
    );
  }
}

class _DiceStage extends StatefulWidget {
  const _DiceStage({required this.state, required this.onRoll});

  final DiceState state;
  final Future<void> Function() onRoll;

  @override
  State<_DiceStage> createState() => _DiceStageState();
}

class _DiceStageState extends State<_DiceStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  final math.Random _random = math.Random();
  List<DieMotion> _motions = const [];
  List<List<String>> _faces = const [];
  List<bool> _landed = const [];
  bool _showResult = true;
  bool _announced = false;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: DieMotion.totalDuration,
    )
      ..addListener(_handleAnimationTick)
      ..addStatusListener(_handleAnimationStatus);
    _resetSettled(widget.state);
  }

  @override
  void didUpdateWidget(covariant _DiceStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldStatus = oldWidget.state.status;
    final status = widget.state.status;
    if (oldStatus != DiceRollStatus.rolling &&
        status == DiceRollStatus.rolling) {
      _startRoll(widget.state);
      return;
    }
    if (oldStatus == DiceRollStatus.rolling &&
        status == DiceRollStatus.result) {
      _applyResult(widget.state.current);
      if (_reduceMotion) {
        _animation.value = 1;
        setState(() => _showResult = true);
        _announceResult();
      }
      return;
    }
    if (status != DiceRollStatus.rolling &&
        (oldWidget.state.current?.id != widget.state.current?.id ||
            oldWidget.state.useThirdDie != widget.state.useThirdDie)) {
      _resetSettled(widget.state);
    }
  }

  void _resetSettled(DiceState state) {
    final values = _resultValues(state.current, state.useThirdDie);
    final pools = _pools(state);
    _motions = [
      for (var index = 0; index < values.length; index++)
        DieMotion(
          delay: Duration.zero,
          turnsX: 0,
          turnsY: 0,
          landingFaceIndex: 0,
          lift: 0.08,
          liftPx: 12,
          wobbleAmplitude: 0.08,
        ),
    ];
    _faces = [
      for (var index = 0; index < values.length; index++)
        _buildFaces(pools[index], values[index], 0),
    ];
    _landed = List<bool>.filled(values.length, true);
    _showResult = state.current != null;
    _announced = false;
    _animation.value = 1;
  }

  void _startRoll(DiceState state) {
    final pools = _pools(state);
    _motions = [
      for (var index = 0; index < pools.length; index++)
        DieMotion.random(_random, dieIndex: index),
    ];
    _faces = [
      for (var index = 0; index < pools.length; index++)
        _buildFaces(
          pools[index],
          pools[index][_random.nextInt(pools[index].length)],
          _motions[index].landingFaceIndex,
        ),
    ];
    _landed = List<bool>.filled(_motions.length, false);
    _showResult = false;
    _announced = false;
    if (_reduceMotion) {
      _animation.value = 1;
    } else {
      unawaited(_animation.forward(from: 0));
    }
    setState(() {});
  }

  void _applyResult(DiceRollRecord? record) {
    if (record == null || _faces.isEmpty) return;
    final values = [record.action, record.body, if (record.extra != null) record.extra!];
    final count = math.min(values.length, _faces.length);
    for (var index = 0; index < count; index++) {
      final updated = List<String>.of(_faces[index]);
      updated[_motions[index].landingFaceIndex] = values[index];
      _faces[index] = updated;
    }
    setState(() {});
  }

  List<List<String>> _pools(DiceState state) => [
    state.actions,
    state.bodies,
    if (state.useThirdDie) state.extras,
  ];

  static List<String> _resultValues(
    DiceRollRecord? record,
    bool useThirdDie,
  ) => [
    record?.action ?? 'Action',
    record?.body ?? 'Place',
    if (useThirdDie) record?.extra ?? 'Twist',
  ];

  List<String> _buildFaces(List<String> pool, String result, int landingIndex) {
    final decoys = pool.where((value) => value != result).toList()..shuffle(_random);
    final faces = List<String>.filled(6, result);
    var decoyIndex = 0;
    for (var index = 0; index < faces.length; index++) {
      if (index == landingIndex) continue;
      faces[index] = decoys.isEmpty
          ? result
          : decoys[decoyIndex++ % decoys.length];
    }
    return faces;
  }

  void _handleAnimationTick() {
    for (var index = 0; index < _motions.length; index++) {
      final landed = _motions[index].at(_animation.value).hasLanded;
      if (landed && !_landed[index]) {
        _landed[index] = true;
        // TODO(phase7): guard landing haptics with the persisted setting.
        unawaited(HapticFeedback.lightImpact());
      }
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _showResult = true);
    _announceResult();
  }

  void _announceResult() {
    final summary = widget.state.current?.summary;
    if (_announced || summary == null || !_showResult) return;
    _announced = true;
    SemanticsService.announce(summary, TextDirection.ltr);
  }

  @override
  void dispose() {
    _animation
      ..removeListener(_handleAnimationTick)
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dieSize = widget.state.useThirdDie ? 84.0 : 96.0;
    return DiceTray(
      enabled: widget.state.status != DiceRollStatus.rolling,
      onRoll: () => unawaited(widget.onRoll()),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final progress = _reduceMotion ? 1.0 : _animation.value;
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < _motions.length; index++) ...[
                        if (index > 0) const SizedBox(width: 12),
                        _MotionDie(
                          frame: _motions[index].at(progress),
                          faces: _faces[index],
                          size: dieSize,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: AnimatedOpacity(
                    opacity: _showResult ? 1 : 0,
                    duration: _reduceMotion
                        ? const Duration(milliseconds: 150)
                        : const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: Transform.translate(
                      offset: Offset(0, _showResult ? 0 : 12),
                      child: Center(
                        child: Text(
                          widget.state.current?.summary ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MotionDie extends StatelessWidget {
  const _MotionDie({
    required this.frame,
    required this.faces,
    required this.size,
  });

  final DieFrame frame;
  final List<String> faces;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 12,
            child: RepaintBoundary(
              child: Container(
                width: size * frame.shadowWidthFactor,
                height: size * 0.18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: frame.shadowOpacity),
                      blurRadius: frame.shadowBlur,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, frame.translateY - 10),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(frame.scaleX, frame.scaleY, 1),
              child: DiceCube(
                faces: faces,
                rotationX: frame.rotationX,
                rotationY: frame.rotationY,
                size: size,
                blurSigma: frame.blurSigma,
                textOpacity: frame.textOpacity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.record,
    required this.onTap,
    required this.onFavorite,
  });

  final DiceRollRecord record;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        record.summary,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_formatTime(record.createdAt)),
      trailing: IconButton(
        tooltip: record.favorite ? 'Remove favorite' : 'Favorite roll',
        onPressed: onFavorite,
        icon: Icon(record.favorite ? Icons.favorite : Icons.favorite_border),
      ),
    );
  }

  static String _formatTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}/${local.year} · $hour:$minute $suffix';
  }
}

Future<void> _showPremiumMessage(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Create your own dice'),
    content: const Text(
      'Custom face sets are included with Veloura Premium. '
      'The full upgrade flow arrives in Phase 6.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Got it'),
      ),
    ],
  ),
);

Future<void> _showCustomFaces(
  BuildContext context,
  WidgetRef ref,
  DiceState state,
) async {
  final actions = TextEditingController(text: state.actions.join(', '));
  final bodies = TextEditingController(text: state.bodies.join(', '));
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Custom dice faces'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: actions,
            decoration: const InputDecoration(
              labelText: 'Actions, comma separated',
            ),
          ),
          TextField(
            controller: bodies,
            decoration: const InputDecoration(
              labelText: 'Places, comma separated',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await ref.read(diceControllerProvider.notifier).saveCustomFaces(
              actions.text.split(','),
              bodies.text.split(','),
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  actions.dispose();
  bodies.dispose();
}
