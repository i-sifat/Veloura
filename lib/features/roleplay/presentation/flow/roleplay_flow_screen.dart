import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/premium/provider.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/features/roleplay/presentation/flow/roleplay_flow_controller.dart';
import 'package:veloura/features/roleplay/presentation/flow/widgets/beat_view.dart';
import 'package:veloura/features/roleplay/presentation/flow/widgets/role_pick_row.dart';
import 'package:veloura/features/roleplay/presentation/flow/widgets/scene_carousel.dart';
import 'package:veloura/features/roleplay/presentation/roleplay_controller.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/game/game_shell.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/shared/widgets/game/result_sheet.dart';
import 'package:veloura/shared/widgets/game/secondary_text_button.dart';

/// Three-step Passionate Roleplay flow contained in one route.
class RoleplayFlowScreen extends ConsumerWidget {
  const RoleplayFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(roleplayControllerProvider);
    final flow = ref.watch(roleplayFlowControllerProvider);
    final controller = ref.read(roleplayFlowControllerProvider.notifier);
    return catalog.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: ErrorState(message: '$error', onRetry: () => ref.invalidate(roleplayControllerProvider))),
      data: (roleplay) {
        if (flow.selectedScene == null && roleplay.items.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => controller.selectScene(roleplay.items.first));
        }
        return switch (flow.step) {
          RoleplayFlowStep.scenes => _SceneStep(stories: roleplay.items),
          RoleplayFlowStep.roles => const _RoleStep(),
          RoleplayFlowStep.play => const _PlayStep(),
        };
      },
    );
  }
}

class _SceneStep extends ConsumerWidget {
  const _SceneStep({required this.stories});
  final List<RoleplayStory> stories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(roleplayFlowControllerProvider);
    final premium = ref.watch(isPremiumProvider);
    final controller = ref.read(roleplayFlowControllerProvider.notifier);
    return GameShell(
      title: 'Passionate roleplay',
      headline: Text('CHOOSE A SCENE', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      hero: SceneCarousel(stories: stories, isPremium: premium, onChanged: controller.selectScene),
      cta: PrimaryCta(label: 'Choose this scene', onPressed: flow.selectedScene == null ? null : () {
        if (flow.selectedScene!.premium && !premium) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This scene unlocks with Veloura Premium.')));
        } else {
          controller.confirmScene();
        }
      }),
    );
  }
}

class _RoleStep extends ConsumerWidget {
  const _RoleStep();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(roleplayFlowControllerProvider);
    final session = ref.watch(sessionControllerProvider).value;
    final controller = ref.read(roleplayFlowControllerProvider.notifier);
    return GameShell(
      title: 'Passionate roleplay',
      headline: Text('WHO IS WHO', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      hero: session == null ? const CircularProgressIndicator() : RolePickRow(story: flow.selectedScene!, session: session, selectedIndex: flow.activeRoleIndex, onSelected: controller.assignActiveRole),
      cta: PrimaryCta(label: 'Begin', onPressed: flow.activeRoleIndex == null ? null : controller.begin),
    );
  }
}

class _PlayStep extends ConsumerWidget {
  const _PlayStep();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(roleplayFlowControllerProvider);
    final controller = ref.read(roleplayFlowControllerProvider.notifier);
    final story = flow.selectedScene!;
    final last = flow.beatIndex == flow.beats.length - 1;
    final roleAActive = flow.activeRoleIndex == 0;
    final speakerA = flow.beatIndex.isEven;
    final speaker = speakerA == roleAActive ? story.characterA.name : story.characterB.name;
    return GameShell(
      title: story.title,
      leading: IconButton(icon: const Icon(Icons.close, size: 22), onPressed: () => context.pop()),
      hero: BeatView(line: flow.beats[flow.beatIndex], speaker: speaker, index: flow.beatIndex, total: flow.beats.length),
      cta: Column(mainAxisSize: MainAxisSize.min, children: [
        PrimaryCta(label: last ? 'Finish' : 'Next', onPressed: last ? () => _finish(context, ref, story.id) : controller.nextBeat),
        if (flow.revealedTwists < story.twists.length)
          SecondaryTextButton(label: 'Reveal a twist', onPressed: controller.revealTwist),
      ]),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref, String storyId) async {
    await ref.read(roleplayControllerProvider.notifier).recordPlay(storyId);
    await ref.read(sessionControllerProvider.notifier).nextTurn();
    if (!context.mounted) return;
    await ResultSheet.show<void>(context, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Scene complete', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 20),
      PrimaryCta(label: 'Back to games', onPressed: () { Navigator.of(context).pop(); context.pop(); }),
    ]));
    ref.read(roleplayFlowControllerProvider.notifier).reset();
  }
}
