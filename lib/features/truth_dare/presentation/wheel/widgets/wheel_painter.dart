import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Paints the ten curved petals, rim and centre hub.
class WheelPainter extends CustomPainter {
  const WheelPainter({this.winningSegment});

  final int? winningSegment;

  static const _petals = [
    Color(0xFF7E255F),
    Color(0xFFD12B72),
    Color(0xFF9A2C83),
    Color(0xFFFF4D6D),
    Color(0xFF6C3A92),
    Color(0xFFE23B88),
    Color(0xFF8E2A63),
    Color(0xFFC81E67),
    Color(0xFF70408F),
    Color(0xFFEF5B83),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: centre, radius: radius);
    const sweep = math.pi * 2 / 10;

    canvas.drawCircle(
      centre,
      radius + 3,
      Paint()
        ..color = GameTokens.rose.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );

    for (var index = 0; index < 10; index++) {
      final start = -math.pi / 2 + index * sweep;
      final controlAngle = start + 13 * math.pi / 180;
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
  bool shouldRepaint(covariant WheelPainter oldDelegate) =>
      oldDelegate.winningSegment != winningSegment;
}
