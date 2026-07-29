import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/shared/widgets/category_card.dart';

/// Entry point for playable modules.
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          Text('Games', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Choose a playful way to connect.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          CategoryCard(
            title: 'Dice',
            subtitle: 'Roll an action, a place, and an optional twist.',
            icon: Icons.casino_outlined,
            onTap: () => context.push('/games/dice'),
          ),
        ],
      ),
    );
  }
}
