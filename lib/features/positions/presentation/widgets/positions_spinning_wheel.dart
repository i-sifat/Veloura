import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:spinning_wheel/spinning_wheel.dart';
import 'package:veloura/features/positions/domain/position_zone.dart';
import 'package:veloura/features/positions/presentation/widgets/positions_wheel_pointer.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Flick-to-spin Creative Positions wheel, built on `package:spinning_wheel`.
///
/// The package only animates a supplied [Image]; it doesn't draw the wheel
/// itself. This widget renders that image (and a small center hub image)
/// from [PositionZone] colors/icons at runtime with `dart:ui`, so no extra
/// design assets are needed.
class PositionsSpinningWheel extends StatefulWidget {
  const PositionsSpinningWheel({
    required this.zoneCount,
    required this.interactive,
    required this.onSpinStarted,
    required this.onZoneLanded,
    super.key,
  });

  final int zoneCount;
  final bool interactive;
  final VoidCallback onSpinStarted;
  final ValueChanged<PositionZone> onZoneLanded;

  @override
  State<PositionsSpinningWheel> createState() =>
      _PositionsSpinningWheelState();
}

class _PositionsSpinningWheelState extends State<PositionsSpinningWheel> {
  Future<_WheelFaceImages>? _images;
  bool _spinReported = false;

  @override
  void initState() {
    super.initState();
    _images = _renderFaceImages(widget.zoneCount);
  }

  @override
  void didUpdateWidget(PositionsSpinningWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoneCount != widget.zoneCount) {
      _images = _renderFaceImages(widget.zoneCount);
    }
    if (!oldWidget.interactive && widget.interactive) {
      _spinReported = false;
    }
  }

  void _onUpdate(double _) {
    if (_spinReported) return;
    _spinReported = true;
    widget.onSpinStarted();
  }

  void _onEnd(int dividerIndex) {
    final zone = PositionZone.values[dividerIndex % widget.zoneCount];
    widget.onZoneLanded(zone);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final diameter = math.min(constraints.maxWidth, constraints.maxHeight);
      return FutureBuilder<_WheelFaceImages>(
        future: _images,
        builder: (context, snapshot) {
          final images = snapshot.data;
          if (images == null) {
            return SizedBox.square(
              dimension: diameter,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          return SizedBox.square(
            dimension: diameter,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                IgnorePointer(
                  ignoring: !widget.interactive,
                  child: SpinningWheel(
                    Image.memory(images.face, key: const ValueKey('positions-wheel-face')),
                    width: diameter,
                    height: diameter,
                    dividers: widget.zoneCount,
                    initialSpinAngle: 0,
                    spinResistance: 0.78,
                    canInteractWhileSpinning: false,
                    secondaryImage: Image.memory(images.hub),
                    secondaryImageHeight: diameter * 0.16,
                    secondaryImageWidth: diameter * 0.16,
                    onUpdate: _onUpdate,
                    onEnd: _onEnd,
                  ),
                ),
                const Positioned(top: -4, child: PositionsWheelPointer()),
              ],
            ),
          );
        },
      );
    },
  );
}

class _WheelFaceImages {
  const _WheelFaceImages({required this.face, required this.hub});

  final Uint8List face;
  final Uint8List hub;
}

Future<_WheelFaceImages> _renderFaceImages(int zoneCount) async {
  const dimension = 640.0;
  final face = await _rasterize(dimension, (canvas, size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final sweep = 2 * math.pi / zoneCount;
    for (var index = 0; index < zoneCount; index++) {
      final zone = PositionZone.values[index];
      final start = -math.pi / 2 + index * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        Paint()..color = zone.color,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: 0.20),
      );
      final iconAngle = start + sweep / 2;
      final iconCenter =
          center + Offset(math.cos(iconAngle), math.sin(iconAngle)) * radius * 0.62;
      _paintIcon(canvas, zone.icon, iconCenter, size.width * 0.085);
      _paintLabel(canvas, zone.label, center, iconAngle, radius * 0.86);
    }
    canvas.drawCircle(
      center,
      radius - 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white.withValues(alpha: 0.85),
    );
  });

  const hubDimension = 160.0;
  final hub = await _rasterize(hubDimension, (canvas, size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      size.width / 2 - 4,
      Paint()
        ..shader = const RadialGradient(
          colors: [GameTokens.rose, GameTokens.roseDeep],
        ).createShader(Rect.fromCircle(center: center, radius: size.width / 2)),
    );
    canvas.drawCircle(
      center,
      size.width / 2 - 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white,
    );
    _paintIcon(canvas, Icons.favorite, center, size.width * 0.34);
  });

  return _WheelFaceImages(face: face, hub: hub);
}

void _paintIcon(Canvas canvas, IconData icon, Offset center, double fontSize) {
  final painter = TextPainter(textDirection: TextDirection.ltr)
    ..text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    )
    ..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

void _paintLabel(
  Canvas canvas,
  String label,
  Offset center,
  double angle,
  double radius,
) {
  final painter = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center)
    ..text = TextSpan(
      text: label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: Colors.white,
      ),
    )
    ..layout();
  final labelCenter =
      center + Offset(math.cos(angle), math.sin(angle)) * radius;
  painter.paint(canvas, labelCenter - Offset(painter.width / 2, painter.height / 2));
}

Future<Uint8List> _rasterize(
  double dimension,
  void Function(Canvas canvas, Size size) paint,
) async {
  final recorder = ui.PictureRecorder();
  final size = Size.square(dimension);
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, dimension, dimension));
  paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(dimension.round(), dimension.round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}
