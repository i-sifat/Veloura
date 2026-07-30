import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/profile/domain/profile_models.dart';
import 'package:veloura/features/profile/presentation/profile_controller.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Couple profile, aggregate statistics, achievements, activity and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(profileControllerProvider),
        ),
        data: (state) => DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Activity'),
                  Tab(text: 'Settings'),
                ],
              ),
              Expanded(
                child: TabBarView(
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

class _Overview extends StatelessWidget {
  const _Overview({required this.state});
  final ProfileState state;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
    children: [
      _ProfileHero(profile: state.profile),
      const SizedBox(height: 20),
      Text('Your connection', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _Metric(label: 'Dice rolls', value: state.stats.diceRolls),
          _Metric(label: 'Truth / Dare', value: state.stats.truthDareCompleted),
          _Metric(label: 'Challenges', value: state.stats.challengesCompleted),
          _Metric(label: 'Conversations', value: state.stats.conversationsAnswered),
          _Metric(label: 'Roleplays', value: state.stats.roleplaysCompleted),
          _Metric(label: 'Daily', value: state.stats.dailyCompletions),
        ],
      ),
      const SizedBox(height: 24),
      Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      for (final item in state.achievements)
        Card(
          child: ListTile(
            leading: Icon(
              item.unlocked ? Icons.verified : Icons.lock_outline,
              color: item.unlocked ? GameTokens.rose : null,
            ),
            title: Text(item.title),
            subtitle: Text(item.description),
          ),
        ),
    ],
  );
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});
  final CoupleProfile profile;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: GameTokens.passionateRoleplay),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        const Icon(Icons.favorite, size: 38),
        const SizedBox(height: 10),
        Text(
          '${profile.nameA} & ${profile.nameB}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (profile.relationshipStart != null)
          Text('${profile.togetherDays(DateTime.now())} days together'),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: GameTokens.glassStrong,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GameTokens.hairline),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$value', style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _Activity extends StatelessWidget {
  const _Activity({required this.entries});
  final List<ActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('Play a game to start your activity.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final item = entries[index];
        return ListTile(
          leading: const Icon(Icons.auto_awesome),
          title: Text(item.label),
          subtitle: Text('${item.gameId} · ${_date(item.timestamp)}'),
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
    final settings = state.settings;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        SwitchListTile.adaptive(
          title: const Text('Haptics'),
          value: settings.haptics,
          onChanged: (value) => ref
              .read(profileControllerProvider.notifier)
              .updateSettings(settings.copyWith(haptics: value)),
        ),
        SwitchListTile.adaptive(
          title: const Text('Sound'),
          subtitle: const Text('Audio effects arrive in the release polish phase.'),
          value: settings.sound,
          onChanged: (value) => ref
              .read(profileControllerProvider.notifier)
              .updateSettings(settings.copyWith(sound: value)),
        ),
        SwitchListTile.adaptive(
          title: const Text('Notifications'),
          value: settings.notifications,
          onChanged: (value) => ref
              .read(profileControllerProvider.notifier)
              .updateSettings(settings.copyWith(notifications: value)),
        ),
        const ListTile(
          leading: Icon(Icons.language),
          title: Text('Language'),
          trailing: Text('English'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy policy'),
          subtitle: Text(
            'Legal URL required before release',
            style: TextStyle(color: AppColors.of(context).textSecondary),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Terms of service'),
          subtitle: Text(
            'Legal URL required before release',
            style: TextStyle(color: AppColors.of(context).textSecondary),
          ),
        ),
      ],
    );
  }
}

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
