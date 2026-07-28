import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/home/presentation/home_controller.dart';
import 'package:veloura/shared/widgets/glass_card.dart';
import 'package:veloura/shared/widgets/section_header.dart';
import 'package:veloura/theme/app_colors.dart';

/// Phase 1 Home shell. Real activity data replaces mock values in Phase 9.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final colors = AppColors.of(context);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList.list(
              children: [
                _Greeting(greeting: state.greeting, streak: state.streakDays),
                const SizedBox(height: 24),
                _FeaturedCard(title: state.featuredTitle),
                const SizedBox(height: 28),
                const SectionHeader(title: 'Popular tonight'),
                const SizedBox(height: 12),
                const _PopularRow(),
                const SizedBox(height: 28),
                const _PremiumBanner(),
                const SizedBox(height: 28),
                Text(
                  'Quote of the day',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '“${state.quote}”',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.greeting, required this.streak});

  final String greeting;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good evening', style: Theme.of(context).textTheme.bodyLarge),
              Text(greeting, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
        Semantics(
          label: '$streak day connection streak',
          child: Chip(
            avatar: Icon(Icons.local_fire_department, color: colors.accent),
            label: Text('$streak'),
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: colors.accent),
          const SizedBox(height: 24),
          Text('FEATURED', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Game experiences arrive in the next phases.',
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PopularRow extends StatelessWidget {
  const _PopularRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _PopularTile(label: 'Dice', icon: Icons.casino_outlined),
          _PopularTile(label: 'Truth or Dare', icon: Icons.style_outlined),
          _PopularTile(label: 'Conversation', icon: Icons.forum_outlined),
        ],
      ),
    );
  }
}

class _PopularTile extends StatelessWidget {
  const _PopularTile({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Icon(icon, color: colors.secondary), Text(label)],
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.workspace_premium_outlined),
          SizedBox(width: 12),
          Expanded(child: Text('Premium experiences are coming in Phase 6.')),
        ],
      ),
    );
  }
}
