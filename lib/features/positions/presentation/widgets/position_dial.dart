import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veloura/features/positions/domain/position_zone.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Interactive six/ five-zone dial whose needle is driven by resolved degrees.
class PositionDial extends StatelessWidget {
  const PositionDial({
    required this.degrees,
    required this.zoneCount,
    required this.spinning,
    this.onFlick,
    super.key,
  });

  final double degrees;
  final int zoneCount;
  final bool spinning;
  final ValueChanged<double>? onFlick;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = math.min(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanEnd: onFlick == null
            ? null
            : (details) {
                final velocity = details.velocity.pixelsPerSecond.dx / 100;
                onFlick!(velocity.abs() < 1.5 ? 4.8 : velocity);
              },
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0x24FFFFFF), GameTokens.bgTop],
                  ),
                  border: Border.all(color: GameTokens.hairline),
                  boxShadow: const [GameTokens.tileShadow],
                ),
              ),
              for (var index = 0; index < zoneCount; index++)
                _ZonePuck(
                  zone: PositionZone.values[index],
                  index: index,
                  count: zoneCount,
                  radius: size * 0.39,
                ),
              AnimatedRotation(
                turns: degrees / 360,
                duration: spinning
                    ? const Duration(milliseconds: 4200)
                    : GameTokens.fadeDuration,
                curve: const Cubic(0.16, 0.84, 0.04, 1),
                child: CustomPaint(
                  size: Size.square(size * 0.82),
                  painter: const _NeedlePainter(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ZonePuck extends StatelessWidget {
  const _ZonePuck({
    required this.zone,
    required this.index,
    required this.count,
    required this.radius,
  });

  final PositionZone zone;
  final int index;
  final int count;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final angle = -math.pi / 2 + index * math.pi * 2 / count;
    return Transform.translate(
      offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      child: Semantics(
        label: '${zone.label} zone',
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: zone.color.withValues(alpha: 0.16),
            border: Border.all(
              color: zone.color.withValues(alpha: 0.60),
              width: 1.5,
            ),
          ),
          child: Icon(zone.icon, color: zone.color, size: 20),
        ),
      ),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  const _NeedlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final tip = Offset(center.dx, size.height * 0.04);
    final path = Path()
      ..moveTo(center.dx - 7, center.dy + 20)
      ..lineTo(tip.dx - 2, tip.dy + 16)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + 2, tip.dy + 16)
      ..lineTo(center.dx + 7, center.dy + 20)
      ..close();
    canvas.drawShadow(path, Colors.black, 6, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFFC9A6B8), Color(0xFFF7E7EF)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      center,
      19,
      Paint()
        ..shader = const RadialGradient(
          colors: [GameTokens.rose, GameTokens.roseDeep],
        ).createShader(Rect.fromCircle(center: center, radius: 19)),
    );
    canvas.drawCircle(
      center,
      19,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
