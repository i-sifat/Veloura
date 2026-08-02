import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Paints the six curved petals, rim and centre hub for the Passionate
/// Roleplay wheel. Same construction as Truth or Dare's `WheelPainter`,
/// recolored into Roleplay's plum/rose palette and scaled to 6 segments.
class RoleplayWheelPainter extends CustomPainter {
  const RoleplayWheelPainter({this.winningSegment});

  final int? winningSegment;

  static const _petals = [
    Color(0xFF8E0F3C),
    Color(0xFFC2185B),
    Color(0xFF6C1450),
    Color(0xFFA02268),
    Color(0xFF5B2A9D),
    Color(0xFF8E4BD1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: centre, radius: radius);
    const sweep = math.pi * 2 / 6;

    canvas.drawCircle(
      centre,
      radius + 3,
      Paint()
        ..color = GameTokens.roseDeep.withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );

    for (var index = 0; index < 6; index++) {
      final start = -math.pi / 2 + index * sweep;
      final controlAngle = start + 21 * math.pi / 180;
      final control = Offset(
        centre.dx + math.cos(controlAngle) * radius * 0.55,
        centre.dy + math.sin(controlAngle) * radius * 0.55,
      );
      final path = Path()
        ..moveTo(centre.dx, centre.dy)
        ..arcTo(rect, start, sweep, false)
        ..quadraticBezierTo(control.dx, control.dy, centre.dx, centre.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = _petals[index]);
      if (winningSegment == index) {
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
          colors: [GameTokens.roseLight, GameTokens.roseDeep],
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
  bool shouldRepaint(covariant RoleplayWheelPainter oldDelegate) =>
      oldDelegate.winningSegment != winningSegment;
}
