import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/profile/domain/profile_models.dart';
import 'package:veloura/features/profile/presentation/profile_controller.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_design_tokens.dart';

/// Couple profile, aggregate statistics, achievements, activity and settings.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      'Profile',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SegmentedTabs(controller: _tabs, colors: colors),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _Overview(state: state),
                    _Activity(entries: state.activity),
                    _Settings(state: state),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.controller, required this.colors});

  static const _labels = ['Overview', 'Activity', 'Settings'];

  final TabController controller;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _labels.length; index++)
            Expanded(
              child: _SegmentButton(
                label: _labels[index],
                selected: controller.index == index,
                colors: colors,
                onTap: () => controller.animateTo(index),
              ),
            ),
        ],
      ),
    ),
  );
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius - 4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? colors.textPrimary : colors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
      ),
    ),
  );
}

class _Overview extends StatelessWidget {
  const _Overview({required this.state});
  final ProfileState state;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 4, 24, 120),
    children: [
      _ProfileHero(profile: state.profile),
      const SizedBox(height: 24),
      Text(
        'Your connection',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.05,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _StatTile(
            icon: Icons.casino_outlined,
            label: 'Dice rolls',
            value: state.stats.diceRolls,
          ),
          _StatTile(
            icon: Icons.style_outlined,
            label: 'Truth / Dare',
            value: state.stats.truthDareCompleted,
          ),
          _StatTile(
            icon: Icons.local_fire_department_outlined,
            label: 'Challenges',
            value: state.stats.challengesCompleted,
          ),
          _StatTile(
            icon: Icons.chat_bubble_outline,
            label: 'Conversations',
            value: state.stats.conversationsAnswered,
          ),
          _StatTile(
            icon: Icons.theater_comedy_outlined,
            label: 'Roleplays',
            value: state.stats.roleplaysCompleted,
          ),
          _StatTile(
            icon: Icons.calendar_today_outlined,
            label: 'Daily',
            value: state.stats.dailyCompletions,
          ),
        ],
      ),
      const SizedBox(height: 28),
      Text(
        'Achievements',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      for (final item in state.achievements)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _AchievementCard(achievement: item),
        ),
    ],
  );
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});
  final CoupleProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
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
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.favorite_border_rounded,
              size: 120,
              color: colors.primary.withValues(alpha: .16),
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Avatar(
                    letter: profile.nameA.isEmpty ? '?' : profile.nameA[0],
                    color: colors.primary,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.favorite, size: 18),
                  ),
                  _Avatar(
                    letter: profile.nameB.isEmpty ? '?' : profile.nameB[0],
                    color: colors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '${profile.nameA} & ${profile.nameB}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (profile.relationshipStart != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${profile.togetherDays(DateTime.now())} days together',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.letter, required this.color});
  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 22,
    backgroundColor: color,
    child: Text(
      letter.toUpperCase(),
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
        border: Border.all(
          color: achievement.unlocked
              ? colors.primary.withValues(alpha: .5)
              : colors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: achievement.unlocked
                  ? colors.primary.withValues(alpha: .18)
                  : colors.divider.withValues(alpha: .4),
            ),
            child: Icon(
              achievement.unlocked ? Icons.verified : Icons.lock_outline,
              color: achievement.unlocked ? colors.primary : colors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
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

class _Activity extends StatelessWidget {
  const _Activity({required this.entries});
  final List<ActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'Play a game to start your activity.',
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 120),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = entries[index];
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
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: .16),
                ),
                child: Icon(Icons.auto_awesome, size: 18, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      '${item.gameId} · ${_date(item.timestamp)}',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Settings extends ConsumerWidget {
  const _Settings({required this.state});
  final ProfileState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final settings = state.settings;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 120),
      children: [
        _SettingsGroup(
          colors: colors,
          children: [
            _SettingsSwitch(
              icon: Icons.vibration,
              label: 'Haptics',
              value: settings.haptics,
              colors: colors,
              onChanged: (value) => ref
                  .read(profileControllerProvider.notifier)
                  .updateSettings(settings.copyWith(haptics: value)),
            ),
            _SettingsSwitch(
              icon: Icons.volume_up_outlined,
              label: 'Sound',
              subtitle: 'Audio effects arrive in the release polish phase.',
              value: settings.sound,
              colors: colors,
              onChanged: (value) => ref
                  .read(profileControllerProvider.notifier)
                  .updateSettings(settings.copyWith(sound: value)),
            ),
            _SettingsSwitch(
              icon: Icons.notifications_none,
              label: 'Notifications',
              value: settings.notifications,
              colors: colors,
              onChanged: (value) => ref
                  .read(profileControllerProvider.notifier)
                  .updateSettings(settings.copyWith(notifications: value)),
            ),
            _SettingsRow(
              icon: Icons.language,
              label: 'Language',
              trailing: 'English',
              colors: colors,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SettingsGroup(
          colors: colors,
          children: [
            _SettingsRow(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy policy',
              trailing: 'Coming soon',
              colors: colors,
            ),
            _SettingsRow(
              icon: Icons.description_outlined,
              label: 'Terms of service',
              trailing: 'Coming soon',
              colors: colors,
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.colors, required this.children});
  final AppColors colors;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
      border: Border.all(color: colors.divider),
    ),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) Divider(height: 1, color: colors.divider),
        ],
      ],
    ),
  );
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final bool value;
  final AppColors colors;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        Icon(icon, color: colors.textSecondary, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colors.primary,
        ),
      ],
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final String trailing;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Icon(icon, color: colors.textSecondary, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(label)),
        Text(trailing, style: TextStyle(color: colors.textSecondary)),
      ],
    ),
  );
}

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
