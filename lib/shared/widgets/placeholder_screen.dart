import 'package:flutter/material.dart';
import 'package:veloura/shared/widgets/empty_state.dart';

/// Accessible placeholder used until a planned feature phase lands.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.icon,
    super.key,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: EmptyState(
        title: title,
        message: '$title is ready for its planned feature phase.',
        icon: icon,
      ),
    );
  }
}
