import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veloura/features/positions/domain/position_zone.dart';
import 'package:veloura/features/positions/presentation/widgets/position_wheel_painter.dart';
import 'package:veloura/features/truth_dare/presentation/wheel/widgets/wheel_pointer.dart';

/// Animated prize wheel with one petal per [PositionZone], inherited 1:1
/// from the Truth or Dare `SpinWheel`: an externally driven [rotation]
/// (radians, supplied by an `AnimationController`-backed tween on the
/// screen) spins the face while each zone's label pill counter-rotates to
/// stay upright. Only the petal colors (per-zone instead of one fixed
/// palette) and labels (position zones instead of Truth/Dare) differ.
class PositionWheel extends StatelessWidget {
  const PositionWheel({
    required this.rotation,
    required this.zoneCount,
    this.winningZoneIndex,
    super.key,
  });

  /// Current wheel rotation in radians.
  final double rotation;

  /// Number of zone petals to draw (5 free, 6 premium).
  final int zoneCount;

  /// Index of the zone to highlight once the wheel has settled, or null
  /// while spinning / before any round has landed.
  final int? winningZoneIndex;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final diameter = math.min(constraints.maxWidth, constraints.maxHeight);
      final radius = diameter / 2;
      final sweep = math.pi * 2 / zoneCount;
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
                      painter: PositionWheelPainter(
                        zoneCount: zoneCount,
                        winningZoneIndex: winningZoneIndex,
                      ),
                    ),
                    for (var index = 0; index < zoneCount; index++)
                      Transform.translate(
                        offset: Offset(
                          math.cos(-math.pi / 2 + (index + 0.5) * sweep) *
                              radius *
                              0.66,
                          math.sin(-math.pi / 2 + (index + 0.5) * sweep) *
                              radius *
                              0.66,
                        ),
                        child: Transform.rotate(
                          angle: -rotation,
                          child: _ZonePill(zone: PositionZone.values[index]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Positioned(top: -3, child: WheelPointer()),
          ],
        ),
      );
    },
  );
}

/// One zone's icon + label, tinted to that zone's own color. Mirrors the
/// Truth or Dare wheel's white DARE/TRUTH pill shape.
class _ZonePill extends StatelessWidget {
  const _ZonePill({required this.zone});

  final PositionZone zone;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${zone.label} zone',
    child: Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.94),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(zone.icon, size: 11, color: zone.color),
          const SizedBox(width: 3),
          Text(
            zone.label,
            style: TextStyle(
              color: zone.color,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    ),
  );
}
