import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/daily/presentation/daily_controller.dart';
import 'package:veloura/features/premium/provider.dart';
import 'package:veloura/features/profile/domain/profile_models.dart';
import 'package:veloura/features/profile/presentation/profile_controller.dart';
import 'package:veloura/features/profile/presentation/widgets/profile_sheets.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_design_tokens.dart';

/// Couple snapshot, streak stats, premium upsell, and settings entry points.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
          data: (state) => _ProfileBody(state: state),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.state});

  final ProfileState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(dailyControllerProvider).asData?.value.streak ?? 0;
    final isPremium = ref.watch(isPremiumProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        _Header(onSettings: () => showSettingsSheet(context)),
        const SizedBox(height: 18),
        _HeroCard(
          profile: state.profile,
          onEdit: () => editNamesDialog(context, ref, state.profile),
        ),
        const SizedBox(height: 18),
        _StatsRow(
          streak: streak,
          gamesPlayed: state.stats.totalPlays,
          challengesCompleted: state.stats.challengesCompleted,
        ),
        const SizedBox(height: 18),
        if (!isPremium) const _PremiumCard(),
        if (!isPremium) const SizedBox(height: 18),
        _ProfileListRow(
          icon: Icons.emoji_events_outlined,
          label: 'Achievements',
          trailingCount: state.achievements.where((item) => item.unlocked).length,
          onTap: () => showAchievementsSheet(context, state.achievements),
        ),
        _ProfileListRow(
          icon: Icons.history,
          label: 'Game History',
          onTap: () => showHistorySheet(context, state.activity),
        ),
        _ProfileListRow(
          icon: Icons.person_outline,
          label: 'My Partner',
          onTap: () => editNamesDialog(context, ref, state.profile),
        ),
        _ProfileListRow(
          icon: Icons.lock_outline,
          label: 'Privacy',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Privacy settings are coming soon.')),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        'Profile',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const Spacer(),
      IconButton(
        tooltip: 'Settings',
        onPressed: onSettings,
        icon: const Icon(Icons.settings_outlined, size: 26),
      ),
    ],
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile, required this.onEdit});

  final CoupleProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          _AvatarRing(color: colors.buttonFill),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${profile.nameA} & ${profile.nameB}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onEdit,
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: colors.buttonFill),
                    const SizedBox(width: 6),
                    Text(
                      'Together since ${profile.togetherDays(DateTime.now())} days',
                      style: TextStyle(color: colors.buttonFill, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 68,
    height: 68,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 2),
    ),
    child: CircleAvatar(
      backgroundColor: AppColors.of(context).card,
      child: Icon(Icons.favorite_rounded, color: color, size: 28),
    ),
  );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.streak,
    required this.gamesPlayed,
    required this.challengesCompleted,
  });

  final int streak;
  final int gamesPlayed;
  final int challengesCompleted;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          _StatItem(
            icon: Icons.local_fire_department,
            value: '$streak',
            label: 'Day streak',
            color: colors.accent,
          ),
          SizedBox(height: 40, child: VerticalDivider(color: colors.divider)),
          _StatItem(
            icon: Icons.favorite,
            value: '$gamesPlayed',
            label: 'Games played',
            color: colors.buttonFill,
          ),
          SizedBox(height: 40, child: VerticalDivider(color: colors.divider)),
          _StatItem(
            icon: Icons.star,
            value: '$challengesCompleted',
            label: 'Challenges\ncompleted',
            color: colors.accent,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 11),
        ),
      ],
    ),
  );
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
        border: Border.all(color: colors.buttonFill.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.buttonFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.diamond_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Veloura Premium',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Unlock all games, challenges and premium features.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 168,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: colors.buttonFill),
              onPressed: () => context.push('/premium?source=profile'),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Go Premium'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileListRow extends StatelessWidget {
  const _ProfileListRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingCount,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? trailingCount;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            if (trailingCount != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.buttonFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$trailingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
