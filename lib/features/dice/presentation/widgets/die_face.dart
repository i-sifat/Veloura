import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:veloura/theme/app_colors.dart';

/// One live-text face of a Veloura die.
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
    final colors = AppColors.of(context);
    final opacity = textOpacity.clamp(0.0, 1.0).toDouble();
    final shade = brightness.clamp(0.0, 1.0).toDouble();
    final shadedColor = Color.lerp(colors.card, Colors.black, 1 - shade)!;
    final labelWidget = Opacity(
      opacity: opacity,
      child: Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              letterSpacing: 0.2,
              color: colors.textPrimary,
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
          borderRadius: BorderRadius.circular(size * 0.18),
          border: Border.all(
            color: colors.secondary.withValues(alpha: 0.3),
          ),
          gradient: RadialGradient(
            center: const Alignment(-0.5, -0.6),
            radius: 0.9,
            colors: [
              Color.lerp(shadedColor, Colors.white, 0.08)!,
              shadedColor,
            ],
          ),
        ),
        child: filteredLabel,
      ),
    );
  }
}
