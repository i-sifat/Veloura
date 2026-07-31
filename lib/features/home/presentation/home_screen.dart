import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';
import 'package:veloura/features/games/domain/game_catalog_entry.dart';
import 'package:veloura/features/home/presentation/home_controller.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_design_tokens.dart';

/// Returns a rotating, deterministic set of four games for the current day.
List<GameCatalogEntry> popularGamesFor(DateTime date) {
  final day = DateTime(date.year, date.month, date.day)
      .difference(DateTime(date.year))
      .inDays;
  return List.generate(
    4,
    (index) => kGameCatalog[(day + index) % kGameCatalog.length],
    growable: false,
  );
}

/// Home discovery shell renovated from the approved visual direction.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final colors = AppColors.of(context);
    final games = popularGamesFor(DateTime.now());

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            _Greeting(greeting: state.greeting, streak: state.streakDays),
            const SizedBox(height: 24),
            const _TonightCard(),
            const SizedBox(height: 28),
            Row(
              children: [
                Text(
                  'Popular games',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/games'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _PopularRow(games: games),
            const SizedBox(height: 24),
            _ScienceCard(quote: state.quote),
          ],
        ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good evening', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          label: '$streak day streak',
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surface,
                  border: Border.all(color: colors.primary.withValues(alpha: .55)),
                ),
                child: Text(
                  '🔥 $streak',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 6),
              Text('Day streak', style: TextStyle(color: colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TonightCard extends StatelessWidget {
  const _TonightCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: 296,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDesignTokens.radius),
        border: Border.all(color: colors.primary.withValues(alpha: .35)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF371122), Color(0xFF1B101C)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: 22,
            child: Icon(
              Icons.favorite_border_rounded,
              size: 150,
              color: colors.primary.withValues(alpha: .8),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🔥  Tonight\'s pick', style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 22),
              Text(
                'Spice up\nyour connection',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Fun & intimacy games for\na deeper bond.'),
              const Spacer(),
              SizedBox(
                width: 168,
                child: FilledButton.icon(
                  onPressed: () => context.go('/games'),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Let's play"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PopularRow extends StatelessWidget {
  const _PopularRow({required this.games});

  final List<GameCatalogEntry> games;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 174,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: games.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, index) => _PopularTile(game: games[index]),
    ),
  );
}

class _PopularTile extends StatelessWidget {
  const _PopularTile({required this.game});

  final GameCatalogEntry game;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final title = game.id == 'lustful_rolls' ? 'Love Dice' : game.title;
    return Semantics(
      button: true,
      label: 'Open $title',
      child: InkWell(
        key: ValueKey('popular-${game.id}'),
        onTap: () => context.push(game.route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 118,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  game.art,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    game.fallbackIcon,
                    size: 58,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScienceCard extends StatelessWidget {
  const _ScienceCard({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology_outlined, color: colors.primary, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Science says',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(quote, style: TextStyle(color: colors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.textSecondary),
        ],
      ),
    );
  }
}
