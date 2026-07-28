import 'package:flutter/material.dart';
import 'package:veloura/theme/app_colors.dart';

/// Section title with an optional “See all” action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.onSeeAll, super.key});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text('See all', style: TextStyle(color: colors.secondary)),
          ),
      ],
    );
  }
}
