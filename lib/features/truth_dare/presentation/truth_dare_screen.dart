import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/truth_dare/domain/truth_dare_item.dart';
import 'package:veloura/features/truth_dare/presentation/truth_dare_controller.dart';
import 'package:veloura/models/content_category.dart';
import 'package:veloura/models/difficulty.dart';
import 'package:veloura/shared/widgets/empty_state.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/loading_shimmer.dart';
import 'package:veloura/theme/app_colors.dart';

/// Truth or Dare picker and velocity-aware swipe session.
class TruthDareScreen extends ConsumerWidget {
  const TruthDareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(truthDareControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Truth or Dare')),
      body: session.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingShimmer(height: 420),
        ),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(truthDareControllerProvider),
        ),
        data: (state) => _Session(state: state),
      ),
    );
  }
}

class _Session extends ConsumerWidget {
  const _Session({required this.state});

  final TruthDareState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(truthDareControllerProvider.notifier);
    final item = state.current;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: state.kind?.name ?? 'Truth + Dare',
              onTap: () => _showFilters(context, ref, state),
            ),
            _FilterChip(
              label: state.difficulty?.name ?? 'All levels',
              onTap: () => _showFilters(context, ref, state),
            ),
            _FilterChip(
              label: state.category?.name ?? 'All categories',
              onTap: () => _showFilters(context, ref, state),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (item == null)
          const EmptyState(
            title: 'No cards match',
            message: 'Try a wider mix of filters.',
            icon: Icons.style_outlined,
          )
        else
          _SwipeCard(
            key: ValueKey(item.id),
            item: item,
            onDismiss: () => controller.next(),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: item?.favorite == true ? 'Remove favorite' : 'Favorite card',
              onPressed: item == null ? null : controller.toggleFavorite,
              icon: Icon(
                item?.favorite == true ? Icons.favorite : Icons.favorite_border,
              ),
            ),
            const Spacer(),
            Text('${state.completed} completed'),
            const Spacer(),
            FilledButton.icon(
              onPressed: item == null ? null : controller.next,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Swipe with intent or use Next. A fast flick advances the deck.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SwipeCard extends StatefulWidget {
  const _SwipeCard({required this.item, required this.onDismiss, super.key});

  final TruthDareItem item;
  final VoidCallback onDismiss;

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> {
  var _offset = Offset.zero;

  void _end(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (_offset.dx.abs() > 100 || velocity.abs() > 650) {
      widget.onDismiss();
    } else {
      setState(() => _offset = Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final angle = (_offset.dx / 900).clamp(-0.16, 0.16);
    return GestureDetector(
      onPanUpdate: (details) => setState(() => _offset += details.delta),
      onPanEnd: _end,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(_offset.dx, _offset.dy * 0.2, 0, 1)
          ..rotateZ(angle),
        height: 390,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.card, colors.primary.withValues(alpha: 0.32)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: colors.secondary.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.2),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(widget.item.kind.name.toUpperCase())),
                const Spacer(),
                Text(widget.item.difficulty.name.toUpperCase()),
              ],
            ),
            const Spacer(),
            Icon(
              widget.item.kind == TruthDareKind.truth
                  ? Icons.chat_bubble_outline
                  : Icons.bolt,
              color: colors.accent,
              size: 38,
            ),
            const SizedBox(height: 18),
            Text(
              widget.item.prompt,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            Text(widget.item.category.name),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label),
    avatar: const Icon(Icons.tune, size: 18),
    onPressed: onTap,
  );
}

Future<void> _showFilters(
  BuildContext context,
  WidgetRef ref,
  TruthDareState state,
) async {
  var kind = state.kind;
  var difficulty = state.difficulty;
  var category = state.category;
  var shuffle = state.shuffle;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<TruthDareKind?>(
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Truth + Dare')),
                  ...TruthDareKind.values.map(
                    (value) => DropdownMenuItem(value: value, child: Text(value.name)),
                  ),
                ],
                onChanged: (value) => setModalState(() => kind = value),
              ),
              DropdownButtonFormField<Difficulty?>(
                initialValue: difficulty,
                decoration: const InputDecoration(labelText: 'Difficulty'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All levels')),
                  ...Difficulty.values.map(
                    (value) => DropdownMenuItem(value: value, child: Text(value.name)),
                  ),
                ],
                onChanged: (value) => setModalState(() => difficulty = value),
              ),
              DropdownButtonFormField<ContentCategory?>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All categories')),
                  ...const [
                    ContentCategory.relationship,
                    ContentCategory.fantasy,
                    ContentCategory.memories,
                    ContentCategory.deepTalk,
                    ContentCategory.playful,
                  ].map(
                    (value) => DropdownMenuItem(value: value, child: Text(value.name)),
                  ),
                ],
                onChanged: (value) => setModalState(() => category = value),
              ),
              SwitchListTile(
                title: const Text('Shuffle deck'),
                value: shuffle,
                onChanged: (value) => setModalState(() => shuffle = value),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ref.read(truthDareControllerProvider.notifier).applyFilters(
                      kind: kind,
                      difficulty: difficulty,
                      category: category,
                      shuffle: shuffle,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
