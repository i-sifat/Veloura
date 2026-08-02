import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veloura/features/positions/domain/position_zone.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Classic pie-slice prize wheel. The colored zone wedges spin beneath a
/// fixed pointer at the top; flicking (or tapping the CTA, which calls the
/// same [onFlick] callback with a default velocity) starts the spin.
class PositionWheel extends StatelessWidget {
  const PositionWheel({
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
              AnimatedRotation(
                turns: degrees / 360,
                duration: spinning
                    ? const Duration(milliseconds: 4200)
                    : GameTokens.fadeDuration,
                curve: const Cubic(0.16, 0.84, 0.04, 1),
                child: SizedBox.square(
                  dimension: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size.square(size),
                        painter: _WheelFacePainter(zoneCount: zoneCount),
                      ),
                      for (var index = 0; index < zoneCount; index++)
                        _WedgeLabel(
                          zone: PositionZone.values[index],
                          index: index,
                          count: zoneCount,
                          radius: size * 0.335,
                        ),
                      _Hub(size: size * 0.17),
                    ],
                  ),
                ),
              ),
              IgnorePointer(child: _Pointer(size: size * 0.13)),
            ],
          ),
        ),
      );
    },
  );
}

/// Paints the wheel's rim, the colored pie wedges, and the divider lines
/// between them.
class _WheelFacePainter extends CustomPainter {
  const _WheelFacePainter({required this.zoneCount});

  final int zoneCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rimRect = Rect.fromCircle(center: center, radius: radius);
    final sweep = math.pi * 2 / zoneCount;

    // Outer rim: soft radial base so wedge colors read as an inset surface
    // rather than flat fills.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x1FFFFFFF), GameTokens.bgTop],
        ).createShader(rimRect),
    );

    for (var index = 0; index < zoneCount; index++) {
      final zone = PositionZone.values[index];
      final start = -math.pi / 2 + index * sweep - sweep / 2;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(rimRect, start, sweep, false)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            colors: [zone.color.withValues(alpha: 0.82), zone.color],
          ).createShader(rimRect),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.14),
      );
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = GameTokens.hairline,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelFacePainter oldDelegate) =>
      oldDelegate.zoneCount != zoneCount;
}

/// One zone's icon + label, placed at the middle radius of its wedge.
class _WedgeLabel extends StatelessWidget {
  const _WedgeLabel({
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(zone.icon, color: Colors.white, size: 18),
            const SizedBox(height: 2),
            Text(
              zone.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative center hub, spins with the wheel face (like a hub cap).
class _Hub extends StatelessWidget {
  const _Hub({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        colors: [GameTokens.rose, GameTokens.roseDeep],
      ),
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [GameTokens.tileShadow],
    ),
    child: Icon(Icons.favorite, color: Colors.white, size: size * 0.42),
  );
}

/// Fixed triangular pointer at the top of the wheel; never rotates.
class _Pointer extends StatelessWidget {
  const _Pointer({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Align(
    alignment: const Alignment(0, -1.02),
    child: CustomPaint(
      size: Size(size, size),
      painter: _PointerPainter(),
    ),
  );
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawShadow(path, Colors.black, 6, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7E7EF), Color(0xFFC9A6B8)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
