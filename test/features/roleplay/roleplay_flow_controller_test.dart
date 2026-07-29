import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/features/roleplay/presentation/flow/roleplay_flow_controller.dart';
import 'package:veloura/models/difficulty.dart';

void main() {
  final story = RoleplayStory(
    id: 'story',
    title: 'Scene',
    roleplayCategory: RoleplayCategory.romance,
    difficulty: Difficulty.romantic,
    characterA: const RoleplayCharacter(name: 'A', description: 'First'),
    characterB: const RoleplayCharacter(name: 'B', description: 'Second'),
    setting: 'Setting beat',
    goal: 'Goal beat',
    twists: const ['Twist one', 'Twist two'],
    estimatedDuration: '15 min',
    packId: 'pack',
    packTitle: 'Pack',
    premium: false,
    createdAt: DateTime(2026),
  );

  test('scene and role choices gate play', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(roleplayFlowControllerProvider.notifier);
    controller.selectScene(story);
    controller.confirmScene();
    expect(container.read(roleplayFlowControllerProvider).step, RoleplayFlowStep.roles);
    controller.begin();
    expect(container.read(roleplayFlowControllerProvider).step, RoleplayFlowStep.roles);
    controller.assignActiveRole(1);
    controller.begin();
    expect(container.read(roleplayFlowControllerProvider).step, RoleplayFlowStep.play);
  });

  test('twists append on demand and never exceed authored count', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(roleplayFlowControllerProvider.notifier);
    controller.selectScene(story);
    controller.confirmScene();
    controller.assignActiveRole(0);
    controller.begin();
    expect(container.read(roleplayFlowControllerProvider).beats, ['Setting beat', 'Goal beat']);
    controller.revealTwist();
    controller.revealTwist();
    controller.revealTwist();
    final state = container.read(roleplayFlowControllerProvider);
    expect(state.revealedTwists, 2);
    expect(state.beats, ['Setting beat', 'Goal beat', 'Twist one', 'Twist two']);
  });
}
