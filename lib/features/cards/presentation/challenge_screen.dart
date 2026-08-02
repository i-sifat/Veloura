import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:veloura/features/cards/domain/challenge_item.dart';
import 'package:veloura/features/cards/presentation/challenge_controller.dart';
import 'package:veloura/features/premium/provider.dart';
import 'package:veloura/shared/widgets/category_card.dart';
import 'package:veloura/shared/widgets/empty_state.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/loading_shimmer.dart';

/// Eight-category Challenge Card experience.
class ChallengeScreen extends ConsumerWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengeControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Challenge Cards')),
      body: state.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingShimmer(height: 420),
        ),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(challengeControllerProvider),
        ),
        data: (value) => value.category == null
            ? _CategoryGrid(state: value)
            : _ChallengeList(state: value),
      ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid({required this.state});

  final ChallengeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Choose a challenge',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Chip(
              avatar: const Icon(Icons.stars_outlined),
              label: Text('${state.rewards}'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...ChallengeCategory.values.map((category) {
          final items = state.items
              .where((item) => item.challengeCategory == category)
              .toList();
          final completed = items
              .where((item) =>
                  state.progress[item.id]?.status == ChallengeStatus.completed)
              .length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CategoryCard(
              title: _title(category),
              subtitle: '$completed of ${items.length} completed',
              icon: _icon(category),
              onTap: () => ref
                  .read(challengeControllerProvider.notifier)
                  .selectCategory(category),
            ),
          );
        }),
      ],
    );
  }
}

class _ChallengeList extends ConsumerWidget {
  const _ChallengeList({required this.state});

  final ChallengeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = state.category!;
    final items = state.items
        .where((item) => item.challengeCategory == category)
        .toList();
    return Column(
      children: [
        ListTile(
          leading: IconButton(
            tooltip: 'Back to categories',
            onPressed: () => ref
                .read(challengeControllerProvider.notifier)
                .selectCategory(null),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(_title(category)),
          subtitle: Text('${items.length} challenges'),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyState(
                  title: 'No challenges yet',
                  message: 'This category is getting more ideas soon.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _ChallengeTile(
                    item: items[index],
                    status: state.progress[items[index].id]?.status ??
                        (items[index].premium
                            ? ChallengeStatus.locked
                            : ChallengeStatus.available),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ChallengeTile extends ConsumerWidget {
  const _ChallengeTile({required this.item, required this.status});

  final ChallengeItem item;
  final ChallengeStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(isPremiumProvider);
    final locked = item.premium && !premium;
    final controller = ref.read(challengeControllerProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.description,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: item.favorite ? 'Remove favorite' : 'Favorite',
                  onPressed: () => controller.toggleFavorite(item),
                  icon: Icon(
                    item.favorite ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(item.difficulty.name),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: 'Veloura challenge:\n${item.description}',
                    ),
                  ),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
                FilledButton(
                  onPressed: locked
                      ? () => _locked(context)
                      : () => status == ChallengeStatus.completed
                            ? controller.setStatus(
                                item,
                                ChallengeStatus.available,
                              )
                            : _complete(context, ref, item),
                  child: Text(
                    locked
                        ? 'Premium'
                        : status == ChallengeStatus.completed
                        ? 'Completed ✓'
                        : status == ChallengeStatus.inProgress
                        ? 'Finish'
                        : 'Start',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _complete(
  BuildContext context,
  WidgetRef ref,
  ChallengeItem item,
) async {
  final reflection = TextEditingController();
  await ref
      .read(challengeControllerProvider.notifier)
      .setStatus(item, ChallengeStatus.inProgress);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Complete challenge'),
      content: TextField(
        controller: reflection,
        decoration: const InputDecoration(
          labelText: 'Optional reflection',
          hintText: 'What did you enjoy?',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () async {
            await ref.read(challengeControllerProvider.notifier).setStatus(
              item,
              ChallengeStatus.completed,
              reflection: reflection.text.trim().isEmpty
                  ? null
                  : reflection.text.trim(),
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Complete +10'),
        ),
      ],
    ),
  );
  reflection.dispose();
}

Future<void> _locked(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Premium challenge'),
    content: const Text(
      'This card unlocks with Veloura Premium. Purchasing arrives in Phase 6.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Got it'),
      ),
    ],
  ),
);

String _title(ChallengeCategory value) => switch (value) {
  ChallengeCategory.romance => 'Romance',
  ChallengeCategory.adventure => 'Adventure',
  ChallengeCategory.connection => 'Connection',
  ChallengeCategory.playful => 'Playful',
  ChallengeCategory.kindness => 'Kindness',
  ChallengeCategory.creativity => 'Creativity',
  ChallengeCategory.wellness => 'Wellness',
  ChallengeCategory.surprise => 'Surprise',
};

IconData _icon(ChallengeCategory value) => switch (value) {
  ChallengeCategory.romance => Icons.favorite_outline,
  ChallengeCategory.adventure => Icons.explore_outlined,
  ChallengeCategory.connection => Icons.forum_outlined,
  ChallengeCategory.playful => Icons.celebration_outlined,
  ChallengeCategory.kindness => Icons.volunteer_activism_outlined,
  ChallengeCategory.creativity => Icons.palette_outlined,
  ChallengeCategory.wellness => Icons.spa_outlined,
  ChallengeCategory.surprise => Icons.redeem_outlined,
};
