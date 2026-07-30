import 'package:flutter/material.dart';
import 'package:veloura/theme/app_colors.dart';

/// Compact game header with consistent back navigation and info actions.
class GameAppBar extends StatelessWidget {
  const GameAppBar({required this.title, this.leading, this.onInfo, super.key});

  final String title;

  /// Kept for source compatibility; game headers intentionally use one back UI.
  final Widget? leading;
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              onPressed: Navigator.of(context).maybePop,
              icon: const Icon(Icons.arrow_back, size: 22),
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onInfo != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'How to play',
                onPressed: onInfo,
                icon: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
