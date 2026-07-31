import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';
import 'package:veloura/features/games/domain/game_catalog_entry.dart';
import 'package:veloura/features/home/presentation/home_controller.dart';
import 'package:veloura/shared/widgets/glass_card.dart';
import 'package:veloura/shared/widgets/section_header.dart';
import 'package:veloura/theme/app_colors.dart';

/// Returns a rotating, deterministic set of three games for the current day.
List<GameCatalogEntry> popularGamesFor(DateTime date) {
  final day = DateTime(date.year, date.month, date.day)
      .difference(DateTime(date.year))
      .inDays;
  return List.generate(
    3,
    (index) => kGameCatalog[(day + index) % kGameCatalog.length],
    growable: false,
  );
}

/// Home discovery shell.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final colors = AppColors.of(context);
    final popularGames = popularGamesFor(DateTime.now());

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList.list(
              children: [
                _Greeting(greeting: state.greeting, streak: state.streakDays),
                const SizedBox(height: 24),
                _FeaturedCard(
                  title: state.featuredTitle,
                  onTap: () => context.push('/home/conversation'),
                ),
                const SizedBox(height: 28),
                const SectionHeader(title: 'Popular tonight'),
                const SizedBox(height: 12),
                _PopularRow(games: popularGames),
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
  const _FeaturedCard({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      label: 'Open Conversation Starters',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.forum_outlined, color: colors.accent),
                  const Spacer(),
                  Icon(Icons.arrow_forward, color: colors.textSecondary),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'CONVERSATION STARTERS',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 6),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Swipe through questions made for couples who already know each other.',
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularRow extends StatelessWidget {
  const _PopularRow({required this.games});

  final List<GameCatalogEntry> games;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 118,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [for (final game in games) _PopularTile(game: game)],
    ),
  );
}

class _PopularTile extends StatelessWidget {
  const _PopularTile({required this.game});

  final GameCatalogEntry game;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      label: 'Open ${game.title}',
      child: InkWell(
        key: ValueKey('popular-${game.id}'),
        onTap: () => context.push(game.route),
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
            children: [
              Icon(game.fallbackIcon, color: colors.secondary),
              Text(game.title),
            ],
          ),
        ),
      ),
    );
  }
}
