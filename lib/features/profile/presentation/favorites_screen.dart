import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';
import 'package:veloura/features/games/domain/game_catalog_entry.dart';
import 'package:veloura/features/games/presentation/game_favorites_controller.dart';
import 'package:veloura/features/profile/domain/profile_models.dart';
import 'package:veloura/features/profile/presentation/profile_controller.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_design_tokens.dart';

enum _FavoritesTab { games, challenges }

/// Starred whole games and starred in-game content, per the approved design.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  var _tab = _FavoritesTab.games;
  var _searching = false;
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final favoriteGameIds =
        ref.watch(gameFavoritesControllerProvider).asData?.value ??
        const <String>{};
    final profile = ref.watch(profileControllerProvider);

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  _Header(
                    searching: _searching,
                    onSearch: () => setState(() {
                      _searching = !_searching;
                      if (!_searching) _query = '';
                    }),
                    onClearAll: _tab == _FavoritesTab.games && favoriteGameIds.isNotEmpty
                        ? () =>
                              ref.read(gameFavoritesControllerProvider.notifier).clear()
                        : null,
                  ),
                  if (_searching) ...[
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search favorites',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _TabSwitcher(
                    tab: _tab,
                    onChanged: (value) => setState(() => _tab = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: switch (_tab) {
                _FavoritesTab.games => _GamesTab(
                  favoriteIds: favoriteGameIds,
                  query: _query,
                ),
                _FavoritesTab.challenges => profile.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ErrorState(
                    message: '$error',
                    onRetry: () => ref.invalidate(profileControllerProvider),
                  ),
                  data: (state) =>
                      _ChallengesTab(favorites: state.favorites, query: _query),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.searching,
    required this.onSearch,
    required this.onClearAll,
  });

  final bool searching;
  final VoidCallback onSearch;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Text(
          'Favorites',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Search favorites',
          onPressed: onSearch,
          icon: Icon(searching ? Icons.close : Icons.search, size: 26),
        ),
        PopupMenuButton<String>(
          tooltip: 'More',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'clear') onClearAll?.call();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'clear',
              enabled: onClearAll != null,
              child: Text(
                'Clear all favorites',
                style: TextStyle(
                  color: onClearAll != null ? colors.primary : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.tab, required this.onChanged});

  final _FavoritesTab tab;
  final ValueChanged<_FavoritesTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          _TabSegment(
            label: 'Games',
            selected: tab == _FavoritesTab.games,
            onTap: () => onChanged(_FavoritesTab.games),
          ),
          _TabSegment(
            label: 'Challenges',
            selected: tab == _FavoritesTab.challenges,
            onTap: () => onChanged(_FavoritesTab.challenges),
          ),
        ],
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  const _TabSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : colors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _GamesTab extends StatelessWidget {
  const _GamesTab({required this.favoriteIds, required this.query});

  final Set<String> favoriteIds;
  final String query;

  @override
  Widget build(BuildContext context) {
    final entries = kGameCatalog
        .where((entry) => favoriteIds.contains(entry.id))
        .where((entry) {
          if (query.isEmpty) return true;
          return gameDisplayInfo(
            entry,
          ).$1.toLowerCase().contains(query.toLowerCase());
        })
        .toList();

    return Column(
      children: [
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Star a game from the Games tab to see it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.of(context).textSecondary),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _GameFavoriteRow(entry: entries[index]),
                ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: _FavoritesTipCard(),
        ),
      ],
    );
  }
}

class _GameFavoriteRow extends ConsumerWidget {
  const _GameFavoriteRow({required this.entry});

  final GameCatalogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final info = gameDisplayInfo(entry);
    return Container(
      key: ValueKey('favorite-game-${entry.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_indicator, color: colors.textSecondary),
          const SizedBox(width: 8),
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(
              entry.art,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(entry.fallbackIcon, color: colors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.$1,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(info.$2, style: TextStyle(color: colors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.group_outlined, size: 16, color: colors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      info.$3,
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove from favorites',
            onPressed: () =>
                ref.read(gameFavoritesControllerProvider.notifier).toggle(entry.id),
            icon: Icon(Icons.favorite, color: colors.primary),
          ),
        ],
      ),
    );
  }
}

class _FavoritesTipCard extends StatelessWidget {
  const _FavoritesTipCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bookmark, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favorite your top games',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Quick access to the games you and your partner love.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab({required this.favorites, required this.query});

  final List<FavoriteEntry> favorites;
  final String query;

  @override
  Widget build(BuildContext context) {
    final entries = favorites.where((item) {
      if (query.isEmpty) return true;
      return item.label.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Your saved favorites will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.of(context).textSecondary),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _ChallengeFavoriteRow(entry: entries[index]),
    );
  }
}

class _ChallengeFavoriteRow extends StatelessWidget {
  const _ChallengeFavoriteRow({required this.entry});

  final FavoriteEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconForSource(entry.source), color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(entry.source, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.favorite, color: colors.primary),
        ],
      ),
    );
  }
}

IconData _iconForSource(String source) => switch (source) {
  'Dice' => Icons.casino_outlined,
  'Truth or Dare' => Icons.track_changes_outlined,
  'Challenges' => Icons.style_outlined,
  'Conversation' => Icons.chat_bubble_outline,
  'Roleplay' => Icons.theater_comedy_outlined,
  _ => Icons.favorite_outline,
};
