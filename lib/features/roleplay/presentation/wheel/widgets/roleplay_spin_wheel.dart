import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/features/roleplay/presentation/wheel/roleplay_wheel_controller.dart';
import 'package:veloura/features/roleplay/presentation/wheel/widgets/roleplay_wheel_painter.dart';
import 'package:veloura/features/truth_dare/presentation/wheel/widgets/wheel_pointer.dart';

/// Animated six-petal roulette cycling through the three roleplay
/// categories. Same construction as Truth or Dare's `SpinWheel` (reuses its
/// [WheelPointer] as-is), recolored and relabeled for Passionate Roleplay.
class RoleplaySpinWheel extends StatelessWidget {
  const RoleplaySpinWheel({required this.rotation, this.winningSegment, super.key});

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
                      painter: RoleplayWheelPainter(winningSegment: winningSegment),
                    ),
                    for (var index = 0; index < 6; index++)
                      Transform.translate(
                        offset: Offset(
                          math.cos(-math.pi / 2 + (index + 0.5) * math.pi / 3) *
                              radius *
                              0.66,
                          math.sin(-math.pi / 2 + (index + 0.5) * math.pi / 3) *
                              radius *
                              0.66,
                        ),
                        child: Transform.rotate(
                          angle: -rotation,
                          child: Container(
                            width: 66,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white.withValues(alpha: 0.94),
                              border: Border.all(color: const Color(0x14000000)),
                            ),
                            child: Text(
                              _label(RoleplayWheelMath.categoryForTarget(index)),
                              style: const TextStyle(
                                color: Color(0xFF6C1450),
                                fontSize: 9,
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

  static String _label(RoleplayCategory category) => switch (category) {
    RoleplayCategory.fantasy => 'FANTASY',
    RoleplayCategory.romance => 'ROMANCE',
    RoleplayCategory.adventure => 'ADVENTURE',
  };
}
