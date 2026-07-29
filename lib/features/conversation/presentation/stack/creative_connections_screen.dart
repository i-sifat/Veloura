import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/conversation/presentation/stack/stack_controller.dart';
import 'package:veloura/features/conversation/presentation/stack/widgets/question_stack.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/shared/widgets/empty_state.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/game/game_shell.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Home-owned Conversation Starters hero experience.
class CreativeConnectionsScreen extends ConsumerWidget {
  const CreativeConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stack = ref.watch(conversationStackControllerProvider);
    return stack.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(conversationStackControllerProvider),
        ),
      ),
      data: (value) => GameShell(
        title: 'Creative connections',
        onInfo: () => _showInfo(context),
        hero: value.queue.isEmpty
            ? const EmptyState(
                title: 'No prompts available',
                message: 'Try again after restarting the app.',
              )
            : QuestionStack(
                items: value.queue,
                showSwipeHint: !value.hasAdvanced,
                onAdvance: () => _advance(ref),
              ),
        footnote: AnimatedOpacity(
          duration: GameTokens.fadeDuration,
          opacity: value.hasAdvanced ? 0 : 1,
          child: Text(
            'Swipe when you’ve answered',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ),
        cta: PrimaryCta(
          label: 'Next question',
          icon: Icons.arrow_forward,
          onPressed: value.queue.isEmpty ? null : () => _advance(ref),
        ),
      ),
    );
  }

  Future<void> _advance(WidgetRef ref) async {
    await ref.read(conversationStackControllerProvider.notifier).advance();
    await ref.read(sessionControllerProvider.notifier).nextTurn();
  }

  void _showInfo(BuildContext context) {
    final colors = AppColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GameTokens.sheet,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Talk, then swipe',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Answer together, then swipe either way or tap Next. Every prompt automatically passes the turn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push('/home/conversation/browse');
              },
              icon: const Icon(Icons.grid_view_outlined),
              label: const Text('Browse all prompts'),
            ),
          ],
        ),
      ),
    );
  }
}
