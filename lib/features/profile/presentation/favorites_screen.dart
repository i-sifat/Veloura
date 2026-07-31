import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/profile/domain/profile_models.dart';
import 'package:veloura/features/profile/presentation/profile_controller.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_design_tokens.dart';

/// Unified read-only view over existing per-feature favorite stores.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final colors = AppColors.of(context);
    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            message: '$error',
            onRetry: () => ref.invalidate(profileControllerProvider),
          ),
          data: (state) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Text(
                      'Favorites',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.favorites.isEmpty
                    ? _EmptyFavorites(colors: colors)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 120),
                        itemCount: state.favorites.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _FavoriteCard(
                          item: state.favorites[index],
                          colors: colors,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 72,
            color: colors.primary.withValues(alpha: .5),
          ),
          const SizedBox(height: 18),
          Text(
            'Your saved favorites will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, height: 1.4),
          ),
        ],
      ),
    ),
  );
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.item, required this.colors});
  final FavoriteEntry item;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
      border: Border.all(color: colors.divider),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary.withValues(alpha: .16),
          ),
          child: Icon(Icons.favorite, size: 18, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colors.divider,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.source,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ),
      ],
    ),
  );
}
