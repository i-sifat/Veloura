import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:veloura/theme/game_tokens.dart';

/// One pale, printed face of a transform-composed word die.
class DieFace extends StatelessWidget {
  const DieFace({
    required this.label,
    required this.size,
    required this.brightness,
    this.blurSigma = 0,
    this.textOpacity = 1,
    this.includeSemantics = false,
    super.key,
  });

  final String label;
  final double size;
  final double brightness;
  final double blurSigma;
  final double textOpacity;
  final bool includeSemantics;

  @override
  Widget build(BuildContext context) {
    final opacity = textOpacity.clamp(0.0, 1.0).toDouble();
    final shade = brightness.clamp(0.0, 1.0).toDouble();
    const light = Color(0xFFFFF7FB);
    const mid = Color(0xFFE7D6E2);
    const edge = Color(0xFFC9AEC1);
    final faceTop = Color.lerp(mid, light, 0.42 + shade * 0.50)!;
    final faceBottom = Color.lerp(edge, mid, shade * 0.72)!;

    final labelWidget = Opacity(
      opacity: opacity,
      child: Padding(
        padding: EdgeInsets.all(size * 0.10),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label.toUpperCase(),
            maxLines: 2,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: GameTokens.textOnLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
    final filteredLabel = blurSigma > 0
        ? ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: labelWidget,
          )
        : labelWidget;

    return ExcludeSemantics(
      excluding: !includeSemantics,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.10),
          border: Border.all(color: const Color(0xB3FFFFFF), width: 1.1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [faceTop, faceBottom],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 2,
              offset: Offset(1, 2),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.center,
                  colors: [Color(0x8CFFFFFF), Colors.transparent],
                ),
              ),
            ),
            Center(child: filteredLabel),
          ],
        ),
      ),
    );
  }
}
