import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:veloura/theme/app_colors.dart';

/// Reduced-complexity shimmer placeholder for loading surfaces.
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({this.height = 120, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final placeholder = Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
      ),
    );
    if (reduceMotion) return placeholder;
    return placeholder.animate(onPlay: (controller) => controller.repeat()).shimmer(
      duration: 1200.ms,
      color: colors.secondary.withValues(alpha: 0.16),
    );
  }
}
