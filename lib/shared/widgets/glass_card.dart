import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:veloura/theme/app_colors.dart';

/// Blurred gradient card used for elevated romantic surfaces.
class GlassCard extends StatelessWidget {
  const GlassCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.card.withValues(alpha: 0.92),
                colors.primary.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(color: colors.divider),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
