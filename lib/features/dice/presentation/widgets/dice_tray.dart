import 'package:flutter/material.dart';
import 'package:veloura/theme/app_colors.dart';

/// Fixed-height, non-blurred surface where the animated dice land.
class DiceTray extends StatelessWidget {
  const DiceTray({
    required this.onRoll,
    required this.child,
    this.enabled = true,
    super.key,
  });

  static const height = 260.0;

  final VoidCallback onRoll;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return RepaintBoundary(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: 'Roll dice',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onRoll : null,
          child: Container(
            key: const ValueKey('dice-tray'),
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.divider),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.surface, colors.background],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    colors.background.withValues(alpha: 0.35),
                  ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
