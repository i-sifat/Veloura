import 'package:flutter/material.dart';
import 'package:veloura/theme/app_colors.dart';

/// Low-emphasis secondary action used below the primary CTA.
class SecondaryTextButton extends StatelessWidget {
  const SecondaryTextButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.of(context).textSecondary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}
