import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veloura/features/conversation/domain/conversation_item.dart';
import 'package:veloura/features/conversation/presentation/stack/widgets/question_card.dart';

/// Three-painted, four-preloaded swipe stack with velocity-aware dismissal.
class QuestionStack extends StatefulWidget {
  const QuestionStack({
    required this.items,
    required this.onAdvance,
    required this.showSwipeHint,
    super.key,
  });

  final List<ConversationItem> items;
  final Future<void> Function() onAdvance;
  final bool showSwipeHint;

  @override
  State<QuestionStack> createState() => _QuestionStackState();
}

class _QuestionStackState extends State<QuestionStack> {
  static const _distanceThreshold = 96.0;
  static const _velocityThreshold = 700.0;

  double _dragX = 0;
  Duration _duration = Duration.zero;
  bool _committing = false;

  @override
  Widget build(BuildContext context) {
    final painted = widget.items.take(3).toList(growable: false);
    return SizedBox(
      width: 300,
      height: 370,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (var index = painted.length - 1; index >= 0; index--)
            _buildCard(context, painted[index], index),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ConversationItem item,
    int index,
  ) {
    if (index != 0) {
      return Transform.translate(
        offset: Offset(0, -10.0 * index),
        child: Transform.scale(
          scale: 1 - (0.03 * index),
          child: Opacity(
            opacity: 1 - (0.2 * index),
            child: QuestionCard(item: item),
          ),
        ),
      );
    }

    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final fade = reducedMotion
        ? 1.0
        : (1 - ((_dragX.abs() - _distanceThreshold).clamp(0, 220) / 260))
              .clamp(0.15, 1.0);
    final angle = reducedMotion ? 0.0 : (_dragX / 24) * math.pi / 180;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _committing
          ? null
          : (details) => setState(() {
              _duration = Duration.zero;
              _dragX += details.delta.dx;
            }),
      onHorizontalDragEnd: _committing
          ? null
          : (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (_dragX.abs() >= _distanceThreshold ||
                  velocity.abs() >= _velocityThreshold) {
                final direction = _dragX == 0
                    ? (velocity < 0 ? -1.0 : 1.0)
                    : _dragX.sign;
                _commit(direction, reducedMotion: reducedMotion);
              } else {
                setState(() {
                  _duration = const Duration(milliseconds: 220);
                  _dragX = 0;
                });
              }
            },
      child: AnimatedOpacity(
        duration: reducedMotion ? const Duration(milliseconds: 220) : _duration,
        opacity: fade,
        child: AnimatedContainer(
          duration: reducedMotion ? const Duration(milliseconds: 220) : _duration,
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(_dragX, 0, 0)
            ..rotateZ(angle),
          transformAlignment: Alignment.center,
          child: QuestionCard(
            item: item,
            showSwipeHint: widget.showSwipeHint,
          ),
        ),
      ),
    );
  }

  Future<void> _commit(double direction, {required bool reducedMotion}) async {
    if (_committing) return;
    _committing = true;
    HapticFeedback.lightImpact();
    setState(() {
      _duration = Duration(milliseconds: reducedMotion ? 220 : 320);
      _dragX = reducedMotion
          ? 0
          : direction * MediaQuery.sizeOf(context).width * 1.4;
    });
    await Future<void>.delayed(_duration);
    await widget.onAdvance();
    if (!mounted) return;
    setState(() {
      _dragX = 0;
      _duration = Duration.zero;
      _committing = false;
    });
  }
}
