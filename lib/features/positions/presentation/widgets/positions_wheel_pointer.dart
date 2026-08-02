import 'package:flutter/material.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Fixed twelve-o'clock pointer above the Creative Positions wheel,
/// marking which slice is selected once the wheel settles.
class PositionsWheelPointer extends StatelessWidget {
  const PositionsWheelPointer({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(22, 17),
    painter: _PositionsPointerPainter(),
  );
}

class _PositionsPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..quadraticBezierTo(size.width / 2, 3, size.width, 0)
      ..close();
    canvas.drawShadow(path, Colors.black, 6, false);
    canvas.drawPath(path, Paint()..color = GameTokens.rose);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.70),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
