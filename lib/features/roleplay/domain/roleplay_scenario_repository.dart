import 'package:veloura/core/content_repository.dart';
import 'package:veloura/features/roleplay/domain/roleplay_scenario.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/models/difficulty.dart';

/// Scenario queries and persisted favorite operations for the spin-wheel
/// Passionate Roleplay experience.
abstract interface class RoleplayScenarioRepository
    implements ContentRepository<RoleplayScenario> {
  Future<List<RoleplayScenario>> getFiltered({
    RoleplayCategory? category,
    Difficulty? difficulty,
    required bool includePremium,
  });
}
