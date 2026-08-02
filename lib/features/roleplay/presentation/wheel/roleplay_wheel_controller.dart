import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/premium/provider.dart';
import 'package:veloura/features/roleplay/data/asset_roleplay_scenario_repository.dart';
import 'package:veloura/features/roleplay/domain/roleplay_scenario.dart';
import 'package:veloura/features/roleplay/domain/roleplay_scenario_repository.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/models/difficulty.dart';

/// Injectable random source for deterministic wheel tests.
final roleplayWheelRandomProvider = Provider<Random>((ref) => Random());

/// Scenario repository dependency for the spin-wheel experience.
final roleplayScenarioRepositoryProvider =
    FutureProvider<RoleplayScenarioRepository>(
      (ref) async => AssetRoleplayScenarioRepository(
        await SharedPreferences.getInstance(),
        random: ref.read(roleplayWheelRandomProvider),
      ),
    );

/// The three editorial categories, laid out twice around the six-segment
/// wheel so opposite segments never repeat a category back-to-back.
const _wheelCategories = [
  RoleplayCategory.fantasy,
  RoleplayCategory.romance,
  RoleplayCategory.adventure,
  RoleplayCategory.fantasy,
  RoleplayCategory.romance,
  RoleplayCategory.adventure,
];

/// Pure landing calculations shared by animation and tests. Mirrors the
/// Truth or Dare wheel's math (see `truth_dare/presentation/wheel/
/// wheel_controller.dart`) scaled to this wheel's six segments.
abstract final class RoleplayWheelMath {
  static const segmentCount = 6;
  static const segmentDegrees = 360 / segmentCount;

  static double endDegrees({required int target, required int turns}) {
    assert(target >= 0 && target < segmentCount);
    final centre = target * segmentDegrees + segmentDegrees / 2;
    return turns * 360 + (360 - centre);
  }

  /// Like [endDegrees], but always measured forward from [currentDegrees],
  /// guaranteeing the wheel only ever spins clockwise, never backward.
  static double nextEndDegrees({
    required double currentDegrees,
    required int target,
    required int turns,
  }) {
    assert(target >= 0 && target < segmentCount);
    assert(turns >= 1);
    final centre = target * segmentDegrees + segmentDegrees / 2;
    final targetMod = (360 - centre) % 360;
    final currentMod = currentDegrees % 360;
    var forwardDelta = targetMod - currentMod;
    if (forwardDelta <= 0) forwardDelta += 360;
    return currentDegrees + forwardDelta + turns * 360;
  }

  static RoleplayCategory categoryForTarget(int target) =>
      _wheelCategories[target % _wheelCategories.length];
}

/// Current roulette round for the Passionate Roleplay wheel.
class RoleplayWheelState {
  const RoleplayWheelState({
    this.target = 0,
    this.turns = 7,
    this.spinning = false,
    this.scenario,
    this.characterASecond = false,
  });

  final int target;
  final int turns;
  final bool spinning;
  final RoleplayScenario? scenario;

  /// When true, the session's second player (`b`) is cast as
  /// `@CharacterA` and the first player (`a`) as `@CharacterB`. Re-rolled
  /// on every spin so who plays which role is always a fresh surprise.
  final bool characterASecond;

  RoleplayCategory get category => RoleplayWheelMath.categoryForTarget(target);

  RoleplayWheelState copyWith({
    int? target,
    int? turns,
    bool? spinning,
    RoleplayScenario? Function()? scenario,
    bool? characterASecond,
  }) => RoleplayWheelState(
    target: target ?? this.target,
    turns: turns ?? this.turns,
    spinning: spinning ?? this.spinning,
    scenario: scenario == null ? this.scenario : scenario(),
    characterASecond: characterASecond ?? this.characterASecond,
  );
}

/// Selects wheel outcomes and casts roles while preserving favorites.
class RoleplayWheelController extends AsyncNotifier<RoleplayWheelState> {
  late RoleplayScenarioRepository _repository;
  late Random _random;
  final List<String> _recentIds = [];

  @override
  Future<RoleplayWheelState> build() async {
    _repository = await ref.watch(roleplayScenarioRepositoryProvider.future);
    _random = ref.watch(roleplayWheelRandomProvider);
    return const RoleplayWheelState();
  }

  /// Chooses a segment and exact axis-aligned landing angle.
  void prepareSpin() {
    final current = state.asData?.value;
    if (current == null || current.spinning) return;
    final target = _random.nextInt(RoleplayWheelMath.segmentCount);
    final turns = 7 + _random.nextInt(4);
    state = AsyncData(
      current.copyWith(
        target: target,
        turns: turns,
        spinning: true,
        scenario: () => null,
        characterASecond: _random.nextBool(),
      ),
    );
  }

  /// Draws a scenario matching the category where the wheel landed.
  Future<void> resolveScenario() async {
    final current = state.asData?.value;
    if (current == null) return;
    final result = await _repository.getAll();
    switch (result) {
      case AppSuccess<List<RoleplayScenario>>(:final value):
        final premium = ref.read(isPremiumProvider);
        var pool = value
            .where((item) => item.roleplayCategory == current.category)
            .where((item) => premium || item.difficulty != Difficulty.extreme)
            .where((item) => !_recentIds.contains(item.id))
            .toList();
        if (pool.isEmpty) {
          _recentIds.clear();
          pool = value
              .where((item) => item.roleplayCategory == current.category)
              .where(
                (item) => premium || item.difficulty != Difficulty.extreme,
              )
              .toList();
        }
        if (pool.isEmpty) throw StateError('No matching scenarios');
        final scenario = pool[_random.nextInt(pool.length)];
        _recentIds
          ..add(scenario.id)
          ..removeRange(0, max(0, _recentIds.length - 12));
        state = AsyncData(
          current.copyWith(spinning: false, scenario: () => scenario),
        );
      case AppFailure<List<RoleplayScenario>>(:final message, :final cause):
        state = AsyncError(message, StackTrace.fromString('$cause'));
    }
  }

  /// Draws another scenario from the same category without re-spinning.
  Future<void> another() => resolveScenario();

  Future<void> toggleFavorite() async {
    final current = state.asData?.value;
    final scenario = current?.scenario;
    if (current == null || scenario == null) return;
    final result = await _repository.toggleFavorite(scenario.id);
    if (result case AppSuccess<RoleplayScenario>(:final value)) {
      state = AsyncData(current.copyWith(scenario: () => value));
    }
  }
}

final roleplayWheelControllerProvider =
    AsyncNotifierProvider<RoleplayWheelController, RoleplayWheelState>(
      RoleplayWheelController.new,
    );
