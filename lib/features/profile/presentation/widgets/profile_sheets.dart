import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/profile/domain/profile_models.dart';
import 'package:veloura/features/profile/presentation/profile_controller.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_design_tokens.dart';

/// Prompts for the couple's names, defaulting blanks to the current values.
Future<void> editNamesDialog(
  BuildContext context,
  WidgetRef ref,
  CoupleProfile profile,
) async {
  final nameA = TextEditingController(text: profile.nameA);
  final nameB = TextEditingController(text: profile.nameB);
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit names'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameA,
            decoration: const InputDecoration(labelText: 'Your name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameB,
            decoration: const InputDecoration(labelText: "Partner's name"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (saved ?? false) {
    await ref.read(profileControllerProvider.notifier).updateProfile(
      CoupleProfile(
        nameA: nameA.text.trim().isEmpty ? profile.nameA : nameA.text.trim(),
        nameB: nameB.text.trim().isEmpty ? profile.nameB : nameB.text.trim(),
        relationshipStart: profile.relationshipStart,
      ),
    );
  }
  nameA.dispose();
  nameB.dispose();
}

/// Lists unlocked and locked achievement badges.
Future<void> showAchievementsSheet(
  BuildContext context,
  List<Achievement> achievements,
) => showModalBottomSheet(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => _AchievementsSheet(achievements: achievements),
);

class _AchievementsSheet extends StatelessWidget {
  const _AchievementsSheet({required this.achievements});

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              'Achievements',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final item in achievements)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
                  border: Border.all(color: colors.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.unlocked ? Icons.emoji_events : Icons.lock_outline,
                      color: item.unlocked ? colors.primary : colors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: item.unlocked ? colors.textPrimary : colors.textSecondary,
                            ),
                          ),
                          Text(
                            item.description,
                            style: TextStyle(color: colors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lists recent shared activity aggregated across every game.
Future<void> showHistorySheet(
  BuildContext context,
  List<ActivityEntry> entries,
) => showModalBottomSheet(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => _HistorySheet(entries: entries),
);

class _HistorySheet extends StatelessWidget {
  const _HistorySheet({required this.entries});

  final List<ActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: entries.isEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                child: Text(
                  'Play a game to start your history.',
                  style: TextStyle(color: colors.textSecondary),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Text(
                    'Game History',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  for (final item in entries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.auto_awesome, color: colors.primary),
                      title: Text(item.label),
                      subtitle: Text(
                        '${item.gameId} · ${_date(item.timestamp)}',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Reuses the existing preference toggles from Profile settings.
Future<void> showSettingsSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  showDragHandle: true,
  builder: (context) => const _SettingsSheet(),
);

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(profileControllerProvider).asData?.value.settings ??
        const ProfileSettings();
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(
            'Settings',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            title: const Text('Haptics'),
            value: settings.haptics,
            onChanged: (value) => ref
                .read(profileControllerProvider.notifier)
                .updateSettings(settings.copyWith(haptics: value)),
          ),
          SwitchListTile.adaptive(
            title: const Text('Sound'),
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
        ],
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
