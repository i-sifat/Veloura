import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/conversation/domain/conversation_item.dart';
import 'package:veloura/features/conversation/presentation/conversation_controller.dart';
import 'package:veloura/shared/widgets/empty_state.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/glass_card.dart';
import 'package:veloura/shared/widgets/loading_shimmer.dart';
import 'package:veloura/theme/app_colors.dart';

/// Conversation Starters random and browse experience.
class ConversationScreen extends ConsumerWidget {
  const ConversationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Conversation Starters')),
      body: state.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingShimmer(height: 360),
        ),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(conversationControllerProvider),
        ),
        data: (value) => _ConversationBody(state: value),
      ),
    );
  }
}

class _ConversationBody extends ConsumerWidget {
  const _ConversationBody({required this.state});

  final ConversationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(conversationControllerProvider.notifier);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: SegmentedButton<ConversationMode>(
            segments: const [
              ButtonSegment(
                value: ConversationMode.random,
                icon: Icon(Icons.shuffle),
                label: Text('Random'),
              ),
              ButtonSegment(
                value: ConversationMode.browse,
                icon: Icon(Icons.grid_view),
                label: Text('Browse'),
              ),
            ],
            selected: {state.mode},
            onSelectionChanged: (selection) => controller.setMode(selection.first),
          ),
        ),
        Expanded(
          child: state.mode == ConversationMode.random
              ? _RandomMode(state: state)
              : _BrowseMode(state: state),
        ),
      ],
    );
  }
}

class _RandomMode extends ConsumerWidget {
  const _RandomMode({required this.state});

  final ConversationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = state.current;
    final controller = ref.read(conversationControllerProvider.notifier);
    if (item == null) {
      return const EmptyState(
        title: 'No prompts match',
        message: 'Choose another category.',
      );
    }
    final answered = state.answered.containsKey(item.id);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      children: [
        DropdownButtonFormField<ConversationCategory?>(
          initialValue: state.category,
          decoration: const InputDecoration(labelText: 'Category'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All categories')),
            ...ConversationCategory.values.map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(_categoryTitle(value)),
              ),
            ),
          ],
          onChanged: controller.setCategory,
        ),
        const SizedBox(height: 24),
        _PromptCard(item: item, answered: answered),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: item.favorite ? 'Remove favorite' : 'Favorite prompt',
              onPressed: () => controller.toggleFavorite(item),
              icon: Icon(
                item.favorite ? Icons.favorite : Icons.favorite_border,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => controller.markAnswered(item),
              icon: Icon(answered ? Icons.check_circle : Icons.done),
              label: Text(answered ? 'Answered' : 'Answered together'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: controller.randomize,
          icon: const Icon(Icons.shuffle),
          label: const Text('Another prompt'),
        ),
      ],
    );
  }
}

class _BrowseMode extends ConsumerWidget {
  const _BrowseMode({required this.state});

  final ConversationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(conversationControllerProvider.notifier);
    final items = state.items
        .where((item) =>
            state.category == null ||
            item.conversationCategory == state.category)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: state.category == null,
              onSelected: (_) => controller.setCategory(null),
            ),
            ...ConversationCategory.values.map(
              (category) => ChoiceChip(
                label: Text(_categoryTitle(category)),
                selected: state.category == category,
                onSelected: (_) => controller.setCategory(category),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => Card(
            child: ListTile(
              onTap: () {
                controller.select(item);
                controller.setMode(ConversationMode.random);
              },
              title: Text(item.prompt, maxLines: 3),
              subtitle: Text(
                '${item.difficulty.name} · ${state.answered.containsKey(item.id) ? 'answered' : 'new'}',
              ),
              trailing: Icon(
                item.favorite ? Icons.favorite : Icons.chevron_right,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.item, required this.answered});

  final ConversationItem item;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GlassCard(
      child: SizedBox(
        height: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(_categoryTitle(item.conversationCategory))),
                const Spacer(),
                if (answered)
                  Icon(Icons.check_circle, color: colors.success),
              ],
            ),
            const Spacer(),
            Icon(Icons.forum_outlined, color: colors.accent, size: 38),
            const SizedBox(height: 18),
            Text(
              item.prompt,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            Text('Depth: ${item.difficulty.name}'),
          ],
        ),
      ),
    );
  }
}

String _categoryTitle(ConversationCategory value) => switch (value) {
  ConversationCategory.deep => 'Deep',
  ConversationCategory.funny => 'Funny',
  ConversationCategory.romantic => 'Romantic',
  ConversationCategory.future => 'Future',
  ConversationCategory.rediscover => 'Getting to know you again',
};
