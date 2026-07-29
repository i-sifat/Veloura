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
import 'package:veloura/features/dice/presentation/widgets/die_motion.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/game/game_shell.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/shared/widgets/loading_shimmer.dart';
import 'package:veloura/theme/app_colors.dart';

/// Full-board, shake-enabled Lustful Rolls experience.
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
    await (reduceMotion
        ? HapticFeedback.selectionClick()
        : HapticFeedback.mediumImpact());
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
    return dice.when(
      loading: () => const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(20),
          child: LoadingShimmer(height: 520),
        ),
      ),
      error: (error, _) => Scaffold(
        body: ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(diceControllerProvider),
        ),
      ),
      data: (state) => GameShell(
        title: 'Lustful rolls',
        board: true,
        hero: _DiceStage(state: state, onRoll: _roll),
        footnote: Text(
          'Tap the board or shake to throw',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
        cta: PrimaryCta(
          label: state.status == DiceRollStatus.rolling
              ? 'Throwing…'
              : state.current == null
              ? 'Throw'
              : 'Throw again',
          icon: Icons.casino_outlined,
          busy: state.status == DiceRollStatus.rolling,
          onPressed: state.status == DiceRollStatus.rolling
              ? null
              : () => unawaited(_roll()),
        ),
      ),
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
        _settledMotion(index, values.length),
    ];
    _faces = [
      for (var index = 0; index < values.length; index++)
        _buildFaces(pools[index], values[index], 0),
    ];
    _landed = List<bool>.filled(values.length, true);
    _announced = false;
    _animation.value = 1;
  }

  DieMotion _settledMotion(int index, int count) {
    final end = count == 2
        ? (index == 0 ? (-0.30, 0.15) : (0.30, -0.10))
        : switch (index) {
            0 => (-0.38, -0.04),
            1 => (0.35, -0.16),
            _ => (0.02, 0.48),
          };
    return DieMotion(
      delay: Duration.zero,
      turnsX: 0,
      turnsY: 0,
      landingFaceIndex: 0,
      lift: 0.16,
      liftPx: 36,
      wobbleAmplitude: 0.10,
      startX: end.$1,
      startY: end.$2,
      endX: end.$1,
      endY: end.$2,
      restTiltX: index.isEven ? 0.28 : -0.24,
      restTiltY: index.isEven ? -0.38 : 0.36,
    );
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
    final values = [
      record.action,
      record.body,
      if (record.extra != null) record.extra!,
    ];
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
    record?.body ?? 'Target',
    if (useThirdDie) record?.extra ?? 'Twist',
  ];

  List<String> _buildFaces(List<String> pool, String result, int landingIndex) {
    final decoys = pool.where((value) => value != result).toList()
      ..shuffle(_random);
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
        unawaited(HapticFeedback.lightImpact());
      }
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) _announceResult();
  }

  void _announceResult() {
    final summary = widget.state.current?.summary;
    if (_announced || summary == null) return;
    _announced = true;
    SemanticsService.sendAnnouncement(
      View.of(context),
      summary,
      TextDirection.ltr,
    );
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
    final dieSize = widget.state.useThirdDie ? 70.0 : 80.0;
    return Semantics(
      button: true,
      label: 'Throw dice',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.state.status == DiceRollStatus.rolling
            ? null
            : () => unawaited(widget.onRoll()),
        child: RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, constraints) => AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                final progress = _reduceMotion ? 1.0 : _animation.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var index = 0; index < _motions.length; index++)
                      _BoardDie(
                        frame: _motions[index].at(progress),
                        faces: _faces[index],
                        size: dieSize,
                        boardSize: constraints.biggest,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardDie extends StatelessWidget {
  const _BoardDie({
    required this.frame,
    required this.faces,
    required this.size,
    required this.boardSize,
  });

  final DieFrame frame;
  final List<String> faces;
  final double size;
  final Size boardSize;

  @override
  Widget build(BuildContext context) {
    final usableWidth = math.max(0.0, boardSize.width - size);
    final usableHeight = math.max(0.0, boardSize.height - size);
    final left = usableWidth / 2 + frame.translateX * usableWidth / 2;
    final top = usableHeight / 2 + frame.translateY * usableHeight / 2;
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size + 28,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: size * 0.88,
            child: Container(
              width: size * frame.shadowWidthFactor,
              height: size * 0.24,
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
          Transform.translate(
            offset: Offset(0, frame.bounceY),
            child: Transform.rotate(
              angle: frame.rotationZ,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(
                  frame.scaleX,
                  frame.scaleY,
                  1,
                ),
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
          ),
        ],
      ),
    );
  }
}
