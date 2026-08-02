import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veloura/features/dice/presentation/widgets/word_die_face.dart';
import 'package:veloura/features/dice/presentation/widgets/word_die_motion.dart';

/// A fixed, roughly-normalized light direction used purely for cosmetic
/// per-face shading (see [_WordDieState._visibleFaces]).
const (double, double, double) _lightDirection = (-0.42, -0.58, 0.70);

/// The new word-cube die: six ivory faces, each showing one word from
/// [wordPool], rolled via a decelerating tumble into one of the six fixed
/// landing rotations. No pips, no numbers - purely word-driven.
class WordDie extends StatefulWidget {
  const WordDie({
    required this.wordPool,
    this.size = 120,
    this.initialWord,
    super.key,
  });

  /// Words to choose from. May contain more than six entries; six are
  /// sampled per roll (one result + up to five decoys for the other faces).
  final List<String> wordPool;
  final double size;

  /// Word shown on the resting face before the first roll. Defaults to the
  /// pool's first entry.
  final String? initialWord;

  @override
  State<WordDie> createState() => WordDieState();
}

class WordDieState extends State<WordDie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random();

  double _restRotationX = 0;
  double _restRotationY = 0;
  double _liveRotationX = 0;
  double _liveRotationY = 0;
  late List<String> _faceWords;

  bool get isRolling => _controller.isAnimating;

  @override
  void initState() {
    super.initState();
    _faceWords = _buildFaces(
      widget.initialWord ?? widget.wordPool.first,
      kDieFaceDefinitions.length - 1,
    );
    _controller = AnimationController(vsync: this);
  }

  List<String> _buildFaces(String result, int landingIndex) {
    final decoys = widget.wordPool.where((word) => word != result).toList()
      ..shuffle(_random);
    final faces = List<String>.filled(kDieFaceDefinitions.length, result);
    var decoyIndex = 0;
    for (var index = 0; index < faces.length; index++) {
      if (index == landingIndex) continue;
      faces[index] = decoys.isEmpty
          ? result
          : decoys[decoyIndex++ % decoys.length];
    }
    return faces;
  }

  /// Rolls the die: picks a random result word, tumbles forward through a
  /// decelerating 5-segment sequence, then eases onto the chosen face.
  /// Returns the resulting word once the roll settles.
  Future<String> roll() async {
    if (isRolling) return _faceWords[kDieFaceDefinitions.length - 1];
    final plan = planRoll(
      random: _random,
      currentRotationX: _restRotationX,
      currentRotationY: _restRotationY,
    );
    final resultWord = widget.wordPool[_random.nextInt(widget.wordPool.length)];
    setState(() => _faceWords = _buildFaces(resultWord, plan.landingFaceIndex));

    final startX = _restRotationX;
    final startY = _restRotationY;
    final deltaX = plan.rotationXTarget - startX;
    final deltaY = plan.rotationYTarget - startY;
    final progress = plan.tumble.buildProgressCurve();

    _controller.duration = plan.totalDuration;
    void tick() {
      final t = progress.transform(_controller.value);
      setState(() {
        _liveRotationX = startX + deltaX * t;
        _liveRotationY = startY + deltaY * t;
      });
    }

    _controller.addListener(tick);
    await _controller.forward(from: 0);
    _controller.removeListener(tick);

    _restRotationX = plan.rotationXTarget;
    _restRotationY = plan.rotationYTarget;
    setState(() {
      _liveRotationX = _restRotationX;
      _liveRotationY = _restRotationY;
    });
    return resultWord;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static (double, double, double) _rotateNormal(
    (double, double, double) normal,
    double rotationX,
    double rotationY,
  ) {
    final (nx, ny, nz) = normal;
    // rotateY applied first (innermost), matching how the whole cube's
    // Transform below is chained: ..rotateX(x)..rotateY(y).
    final x1 = nx * math.cos(rotationY) + nz * math.sin(rotationY);
    const y1Factor = 1.0; // ny unchanged by rotateY
    final z1 = -nx * math.sin(rotationY) + nz * math.cos(rotationY);
    final y1 = ny * y1Factor;
    // then rotateX.
    final y2 = y1 * math.cos(rotationX) - z1 * math.sin(rotationX);
    final z2 = y1 * math.sin(rotationX) + z1 * math.cos(rotationX);
    return (x1, y2, z2);
  }

  List<_VisibleFace> _visibleFaces() {
    final visible = <_VisibleFace>[];
    for (var index = 0; index < kDieFaceDefinitions.length; index++) {
      final normal = _rotateNormal(
        kDieFaceDefinitions[index].normal,
        _liveRotationX,
        _liveRotationY,
      );
      if (normal.$3 <= 0.000001) continue;
      final lambert = math.max(
        0.0,
        normal.$1 * _lightDirection.$1 +
            normal.$2 * _lightDirection.$2 +
            normal.$3 * _lightDirection.$3,
      );
      visible.add(
        _VisibleFace(index: index, depth: normal.$3, brightness: 0.48 + 0.52 * lambert),
      );
    }
    visible.sort((a, b) => a.depth.compareTo(b.depth));
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleFaces();
    final half = widget.size / 2;
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0022)
            ..rotateX(_liveRotationX)
            ..rotateY(_liveRotationY),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final face in visible)
                Positioned.fill(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateY(kDieFaceDefinitions[face.index].yaw)
                      ..rotateX(kDieFaceDefinitions[face.index].pitch)
                      ..translateByDouble(0.0, 0.0, half, 1.0),
                    child: WordDieFace(
                      word: _faceWords[face.index],
                      size: widget.size,
                      brightness: face.brightness,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibleFace {
  const _VisibleFace({
    required this.index,
    required this.depth,
    required this.brightness,
  });

  final int index;
  final double depth;
  final double brightness;
}
