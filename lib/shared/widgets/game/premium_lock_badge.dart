import 'package:flutter/material.dart';
import 'package:veloura/theme/app_colors.dart';

/// Compact premium lock treatment for game tiles and settings.
class PremiumLockBadge extends StatelessWidget {
  const PremiumLockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.of(context).accent;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 12, color: accent),
          const SizedBox(width: 3),
          Text(
            'PRO',
            style: TextStyle(
              color: accent,
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
