import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';

enum RoleplayFlowStep { scenes, roles, play }

/// State for the single-route Passionate Roleplay experience.
class RoleplayFlowState {
  const RoleplayFlowState({
    this.step = RoleplayFlowStep.scenes,
    this.selectedScene,
    this.activeRoleIndex,
    this.beatIndex = 0,
    this.revealedTwists = 0,
  });

  final RoleplayFlowStep step;
  final RoleplayStory? selectedScene;
  final int? activeRoleIndex;
  final int beatIndex;
  final int revealedTwists;

  List<String> get beats {
    final story = selectedScene;
    if (story == null) return const [];
    return [story.setting, story.goal, ...story.twists.take(revealedTwists)];
  }

  RoleplayFlowState copyWith({
    RoleplayFlowStep? step,
    RoleplayStory? Function()? selectedScene,
    int? Function()? activeRoleIndex,
    int? beatIndex,
    int? revealedTwists,
  }) => RoleplayFlowState(
    step: step ?? this.step,
    selectedScene: selectedScene == null
        ? this.selectedScene
        : selectedScene(),
    activeRoleIndex: activeRoleIndex == null
        ? this.activeRoleIndex
        : activeRoleIndex(),
    beatIndex: beatIndex ?? this.beatIndex,
    revealedTwists: revealedTwists ?? this.revealedTwists,
  );
}

/// Owns scene choice, role assignment, beat progress, and on-demand twists.
class RoleplayFlowController extends Notifier<RoleplayFlowState> {
  @override
  RoleplayFlowState build() => const RoleplayFlowState();

  void selectScene(RoleplayStory story) {
    state = state.copyWith(selectedScene: () => story);
  }

  void confirmScene() {
    if (state.selectedScene == null) return;
    state = state.copyWith(step: RoleplayFlowStep.roles);
  }

  void assignActiveRole(int index) {
    if (index != 0 && index != 1) return;
    state = state.copyWith(activeRoleIndex: () => index);
  }

  void begin() {
    if (state.selectedScene == null || state.activeRoleIndex == null) return;
    state = state.copyWith(step: RoleplayFlowStep.play, beatIndex: 0);
  }

  void nextBeat() {
    if (state.beatIndex >= state.beats.length - 1) return;
    state = state.copyWith(beatIndex: state.beatIndex + 1);
  }

  void revealTwist() {
    final story = state.selectedScene;
    if (story == null || state.revealedTwists >= story.twists.length) return;
    state = state.copyWith(
      revealedTwists: state.revealedTwists + 1,
      beatIndex: state.beats.length,
    );
  }

  void reset() => state = const RoleplayFlowState();
}

final roleplayFlowControllerProvider =
    NotifierProvider<RoleplayFlowController, RoleplayFlowState>(
      RoleplayFlowController.new,
    );
