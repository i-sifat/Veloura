import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/premium/provider.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/features/roleplay/presentation/roleplay_controller.dart';
import 'package:veloura/shared/widgets/empty_state.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/glass_card.dart';
import 'package:veloura/shared/widgets/loading_shimmer.dart';
import 'package:veloura/shared/widgets/primary_button.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/models/difficulty.dart';

/// Roleplay story discovery and paced session experience.
class RoleplayScreen extends ConsumerWidget {
  const RoleplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleplayControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Roleplay Stories')),
      body: state.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingShimmer(height: 420),
        ),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(roleplayControllerProvider),
        ),
        data: (value) => value.inSession
            ? _StorySession(state: value)
            : _StoryPicker(state: value),
      ),
    );
  }
}

class _StoryPicker extends ConsumerWidget {
  const _StoryPicker({required this.state});

  final RoleplayState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(roleplayControllerProvider.notifier);
    final isPremium = ref.watch(isPremiumProvider);
    final items = state.items
        .where(
          (item) =>
              (state.category == null ||
                  item.roleplayCategory == state.category) &&
              (state.difficulty == null ||
                  item.difficulty == state.difficulty),
        )
        .toList(growable: false);
    final available = items.where((item) => isPremium || !item.premium).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        Text(
          'Choose a world, assign your roles, and reveal the story together.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: state.category == null,
              onSelected: (_) => controller.setCategory(null),
            ),
            ...RoleplayCategory.values.map(
              (category) => ChoiceChip(
                label: Text(_categoryTitle(category)),
                selected: state.category == category,
                onSelected: (_) => controller.setCategory(category),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<Difficulty?>(
          initialValue: state.difficulty,
          decoration: const InputDecoration(labelText: 'Intensity'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All tiers')),
            ...Difficulty.values.map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(_title(value.name)),
              ),
            ),
          ],
          onChanged: controller.setDifficulty,
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Surprise us',
          onPressed: available.isEmpty
              ? null
              : () => controller.randomize(isPremium: isPremium),
        ),
        if (state.current case final story?) ...[
          const SizedBox(height: 18),
          _SelectedStory(story: story, isPremium: isPremium),
        ],
        const SizedBox(height: 24),
        Text('Story packs', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const EmptyState(
            title: 'No stories match',
            message: 'Try another category or intensity tier.',
            icon: Icons.theater_comedy_outlined,
          )
        else
          ...items.map(
            (story) => Card(
              child: ListTile(
                onTap: story.premium && !isPremium
                    ? () => _showPremiumMessage(context)
                    : () => controller.select(story),
                leading: Icon(_categoryIcon(story.roleplayCategory)),
                title: Text(story.title),
                subtitle: Text(
                  '${story.packTitle} · ${story.estimatedDuration}',
                ),
                trailing: story.premium && !isPremium
                    ? const Icon(Icons.lock_outline)
                    : Icon(
                        story.favorite
                            ? Icons.favorite
                            : Icons.chevron_right,
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SelectedStory extends ConsumerWidget {
  const _SelectedStory({required this.story, required this.isPremium});

  final RoleplayStory story;
  final bool isPremium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(roleplayControllerProvider.notifier);
    final locked = story.premium && !isPremium;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(label: Text(_categoryTitle(story.roleplayCategory))),
              const Spacer(),
              IconButton(
                tooltip: story.favorite ? 'Remove favorite' : 'Favorite story',
                onPressed: locked ? null : () => controller.toggleFavorite(story),
                icon: Icon(
                  story.favorite ? Icons.favorite : Icons.favorite_border,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(story.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(story.setting),
          const SizedBox(height: 16),
          Text('Goal', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(story.goal),
          const SizedBox(height: 18),
          PrimaryButton(
            label: locked ? 'Premium story' : 'Assign roles',
            onPressed: locked
                ? () => _showPremiumMessage(context)
                : controller.startSession,
          ),
        ],
      ),
    );
  }
}

class _StorySession extends ConsumerWidget {
  const _StorySession({required this.state});

  final RoleplayState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = state.current!;
    final controller = ref.read(roleplayControllerProvider.notifier);
    final first = state.rolesSwapped ? story.characterB : story.characterA;
    final second = state.rolesSwapped ? story.characterA : story.characterB;
    final colors = AppColors.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        Text(story.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text('${story.estimatedDuration} · ${_title(story.difficulty.name)}'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _RoleCard(label: 'Partner one', role: first)),
            IconButton(
              tooltip: 'Swap roles',
              onPressed: controller.swapRoles,
              icon: const Icon(Icons.swap_horiz),
            ),
            Expanded(child: _RoleCard(label: 'Partner two', role: second)),
          ],
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Setting', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(story.setting),
              const SizedBox(height: 16),
              Text('Your goal', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(story.goal),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Twist beats', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (state.revealedTwists == 0)
          Text(
            'Reveal a twist whenever the scene needs a spark.',
            style: TextStyle(color: colors.textSecondary),
          ),
        for (var index = 0; index < state.revealedTwists; index++)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(story.twists[index]),
            ),
          ),
        const SizedBox(height: 12),
        if (state.revealedTwists < story.twists.length)
          PrimaryButton(
            label: 'Reveal next twist',
            onPressed: controller.revealNextTwist,
          )
        else
          PrimaryButton(label: 'Finish story', onPressed: controller.endSession),
        const SizedBox(height: 8),
        TextButton(
          onPressed: controller.endSession,
          child: const Text('Back to stories'),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.label, required this.role});

  final String label;
  final RoleplayCharacter role;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            role.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            role.description,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

void _showPremiumMessage(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('This story pack unlocks with Veloura Premium.'),
    ),
  );
}

String _categoryTitle(RoleplayCategory category) => switch (category) {
  RoleplayCategory.fantasy => 'Fantasy',
  RoleplayCategory.romance => 'Romance',
  RoleplayCategory.adventure => 'Adventure',
};

IconData _categoryIcon(RoleplayCategory category) => switch (category) {
  RoleplayCategory.fantasy => Icons.auto_awesome_outlined,
  RoleplayCategory.romance => Icons.favorite_outline,
  RoleplayCategory.adventure => Icons.explore_outlined,
};

String _title(String value) => '${value[0].toUpperCase()}${value.substring(1)}';
