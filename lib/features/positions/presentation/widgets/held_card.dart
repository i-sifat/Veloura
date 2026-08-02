import 'package:flutter/material.dart';
import 'package:veloura/features/positions/domain/position_zone.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Face-down card requiring deliberate press-and-hold before reveal.
class HeldCard extends StatefulWidget {
  const HeldCard({required this.zone, required this.onReveal, super.key});

  final PositionZone zone;
  final VoidCallback onReveal;

  @override
  State<HeldCard> createState() => _HeldCardState();
}

class _HeldCardState extends State<HeldCard>
    with SingleTickerProviderStateMixin {
  static const _cardRadius = 22.0;

  late final AnimationController _hold;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onReveal();
      });
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPressStart: (_) => _hold.forward(from: 0),
    onLongPressEnd: (_) {
      if (!_hold.isCompleted) _hold.reverse();
    },
    // +20% over the original 232x320 footprint.
    child: SizedBox(
      width: 278,
      height: 384,
      child: AnimatedBuilder(
        animation: _hold,
        builder: (context, child) => CustomPaint(
          foregroundPainter: _HoldProgressPainter(_hold.value),
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_cardRadius),
            gradient: const LinearGradient(
              colors: GameTokens.creativeConnections,
            ),
            border: Border.all(color: const Color(0x1AFFFFFF)),
            boxShadow: const [GameTokens.tileShadow],
          ),
          child: Column(
            children: [
              _ZoneChip(zone: widget.zone),
              const Spacer(),
              Icon(widget.zone.icon, size: 64, color: Colors.white24),
              const Spacer(),
              const Text('Press and hold'),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({required this.zone});
  final PositionZone zone;

  @override
  Widget build(BuildContext context) => Container(
    height: 26,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: zone.color.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(zone.icon, size: 13, color: zone.color),
        const SizedBox(width: 6),
        Text(zone.label, style: TextStyle(color: zone.color)),
      ],
    ),
  );
}

/// Traces the card's own rounded-rect edge (matching its 22px corner
/// radius exactly) as [progress] climbs from 0 to 1, rather than drawing a
/// separate shape around it.
class _HoldProgressPainter extends CustomPainter {
  const _HoldProgressPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(_HeldCardState._cardRadius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = GameTokens.rose;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      final length = metric.length * progress;
      if (length <= 0) continue;
      canvas.drawPath(metric.extractPath(0, length), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HoldProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
