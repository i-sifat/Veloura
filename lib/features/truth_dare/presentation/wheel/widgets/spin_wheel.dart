import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veloura/features/truth_dare/presentation/wheel/widgets/wheel_painter.dart';
import 'package:veloura/features/truth_dare/presentation/wheel/widgets/wheel_pointer.dart';

/// Animated ten-petal roulette wheel with alternating Truth and Dare segments.
class SpinWheel extends StatelessWidget {
  const SpinWheel({required this.rotation, this.winningSegment, super.key});

  final double rotation;
  final int? winningSegment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final diameter = math.min(constraints.maxWidth, constraints.maxHeight);
      final radius = diameter / 2;
      return SizedBox.square(
        dimension: diameter,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: rotation,
              child: SizedBox.square(
                dimension: diameter,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size.square(diameter),
                      painter: WheelPainter(winningSegment: winningSegment),
                    ),
                    for (var index = 0; index < 10; index++)
                      Transform.translate(
                        offset: Offset(
                          math.cos(-math.pi / 2 + (index + 0.5) * math.pi / 5) *
                              radius *
                              0.66,
                          math.sin(-math.pi / 2 + (index + 0.5) * math.pi / 5) *
                              radius *
                              0.66,
                        ),
                        child: Transform.rotate(
                          angle: -rotation,
                          child: Container(
                            width: 46,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white.withValues(alpha: 0.94),
                              border: Border.all(color: const Color(0x14000000)),
                            ),
                            child: Text(
                              index.isEven ? 'DARE' : 'TRUTH',
                              style: const TextStyle(
                                color: Color(0xFF8E2A63),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(top: -3, child: const WheelPointer()),
          ],
        ),
      );
    },
  );
}
