import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';
import 'package:veloura/features/games/domain/game_catalog_entry.dart';
import 'package:veloura/features/games/presentation/game_favorites_controller.dart';
import 'package:veloura/features/premium/provider.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/features/session/presentation/who_is_playing_sheet.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_design_tokens.dart';

/// Searchable game catalog using the renovated list-card system.
class GamesHubScreen extends ConsumerStatefulWidget {
  const GamesHubScreen({super.key});

  @override
  ConsumerState<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends ConsumerState<GamesHubScreen> {
  var _checkedFirstRun = false;
  var _category = 'All';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final isPremium = ref.watch(isPremiumProvider);
    if (!_checkedFirstRun && session.hasValue) {
      _checkedFirstRun = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showFirstRun(session.requireValue),
      );
    }

    final entries = kGameCatalog.where(_matchesCategory).toList();
    final colors = AppColors.of(context);
    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'Games',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Search games',
                      onPressed: _showSearch,
                      icon: const Icon(Icons.search, size: 30),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final category in const [
                      'All',
                      'Spicy 🔥',
                      'Intimacy 💕',
                      'Fun 😈',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _category = category),
                          selectedColor: colors.primary,
                          backgroundColor: colors.surface,
                          side: BorderSide(color: colors.divider),
                          labelStyle: TextStyle(
                            color: _category == category
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              sliver: SliverList.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final entry = entries[index];
                  return _GameListCard(
                    entry: entry,
                    locked: entry.isPremium && !isPremium,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesCategory(GameCatalogEntry entry) {
    if (_category == 'All') return true;
    if (_category.startsWith('Spicy')) {
      return {'lustful_rolls', 'truth_or_dare', 'passionate_roleplay'}
          .contains(entry.id);
    }
    if (_category.startsWith('Intimacy')) {
      return {'card_challenge', 'creative_connections'}.contains(entry.id);
    }
    return {'follow_the_tempo', 'truth_or_dare'}.contains(entry.id);
  }

  Future<void> _showFirstRun(GameSession session) async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted ||
        (preferences.getBool('session_players_configured') ?? false)) {
      return;
    }
    await WhoIsPlayingSheet.show(context, session: session, dismissible: false);
    await preferences.setBool('session_players_configured', true);
  }

  Future<void> _showSearch() async {
    final selected = await showSearch<GameCatalogEntry>(
      context: context,
      delegate: _GameSearchDelegate(),
    );
    if (selected != null && mounted) context.push(selected.route);
  }
}

class _GameListCard extends ConsumerWidget {
  const _GameListCard({required this.entry, required this.locked});

  final GameCatalogEntry entry;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final info = gameDisplayInfo(entry);
    final favorited =
        ref.watch(gameFavoritesControllerProvider).asData?.value.contains(entry.id) ??
        false;
    return Semantics(
      button: true,
      label: 'Open ${info.$1}',
      child: InkWell(
        key: ValueKey('game-card-${entry.id}'),
        onTap: () {
          if (locked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${info.$1} unlocks with Veloura Premium.'),
              ),
            );
          } else {
            context.push(entry.route);
          }
        },
        borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
        child: Container(
          height: 124,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
            border: Border.all(color: colors.divider),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                child: Image.asset(
                  entry.art,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    entry.fallbackIcon,
                    color: colors.primary,
                    size: 58,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            info.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (entry.id == 'truth_or_dare') ...[
                          const SizedBox(width: 8),
                          _Badge(label: 'HOT', color: colors.primary),
                        ],
                        if (locked) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.lock_outline, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(info.$2, style: TextStyle(color: colors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          info.$3,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('game-favorite-${entry.id}'),
                tooltip: favorited ? 'Remove from favorites' : 'Add to favorites',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => ref
                    .read(gameFavoritesControllerProvider.notifier)
                    .toggle(entry.id),
                icon: Icon(
                  favorited ? Icons.favorite : Icons.favorite_border,
                  color: favorited ? colors.primary : colors.textSecondary,
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _GameSearchDelegate extends SearchDelegate<GameCatalogEntry> {
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => Navigator.of(context).maybePop(),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final matches = kGameCatalog.where((entry) {
      final display = gameDisplayInfo(entry);
      return display.$1.toLowerCase().contains(query.toLowerCase());
    }).toList();
    return ListView(
      children: [
        for (final entry in matches)
          ListTile(
            leading: Icon(entry.fallbackIcon),
            title: Text(gameDisplayInfo(entry).$1),
            subtitle: Text(gameDisplayInfo(entry).$2),
            onTap: () => close(context, entry),
          ),
      ],
    );
  }
}
