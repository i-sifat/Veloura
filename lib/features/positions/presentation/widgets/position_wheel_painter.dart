import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veloura/features/positions/domain/position_zone.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Paints the curved petals, rim and centre hub for [PositionWheel],
/// mirroring the Truth or Dare `WheelPainter` 1:1 but with one petal per
/// [PositionZone] tinted in that zone's own color instead of a fixed
/// ten-way palette.
class PositionWheelPainter extends CustomPainter {
  const PositionWheelPainter({required this.zoneCount, this.winningZoneIndex});

  final int zoneCount;
  final int? winningZoneIndex;

  /// Same curvature ratio as the ten-petal Truth or Dare wheel (a 13°
  /// control-point offset within each 36° sweep), scaled to whatever
  /// sweep this zone count produces.
  static const _controlFraction = 13 / 36;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: centre, radius: radius);
    final sweep = math.pi * 2 / zoneCount;

    canvas.drawCircle(
      centre,
      radius + 3,
      Paint()
        ..color = GameTokens.rose.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );

    for (var index = 0; index < zoneCount; index++) {
      final zone = PositionZone.values[index];
      final start = -math.pi / 2 + index * sweep;
      final controlAngle = start + sweep * _controlFraction;
      final control = Offset(
        centre.dx + math.cos(controlAngle) * radius * 0.55,
        centre.dy + math.sin(controlAngle) * radius * 0.55,
      );
      final path = Path()
        ..moveTo(centre.dx, centre.dy)
        ..arcTo(rect, start, sweep, false)
        ..quadraticBezierTo(control.dx, control.dy, centre.dx, centre.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = zone.color);
      if (winningZoneIndex == index) {
        canvas.drawPath(
          path,
          Paint()..color = Colors.white.withValues(alpha: 0.30),
        );
      }
    }

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      centre,
      17,
      Paint()
        ..shader = const RadialGradient(
          colors: [GameTokens.rose, GameTokens.roseDeep],
        ).createShader(Rect.fromCircle(center: centre, radius: 17)),
    );
    canvas.drawCircle(
      centre,
      17,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
    canvas.drawCircle(
      centre,
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant PositionWheelPainter oldDelegate) =>
      oldDelegate.zoneCount != zoneCount ||
      oldDelegate.winningZoneIndex != winningZoneIndex;
}
