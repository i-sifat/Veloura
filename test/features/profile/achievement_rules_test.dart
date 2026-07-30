import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/profile/domain/achievement_rules.dart';
import 'package:veloura/features/profile/domain/profile_models.dart';

void main() {
  test('all-core achievement requires activity in every core module', () {
    const stats = ProfileStats(
      diceRolls: 1,
      truthDareCompleted: 1,
      challengesCompleted: 1,
      conversationsAnswered: 1,
      roleplaysCompleted: 1,
      dailyCompletions: 1,
      favorites: 0,
    );

    final achievements = evaluateAchievements(stats);
    expect(
      achievements.singleWhere((item) => item.id == 'all_core').unlocked,
      isTrue,
    );
    expect(
      achievements.singleWhere((item) => item.id == 'fifty_plays').unlocked,
      isFalse,
    );
  });

  test('profile together days never returns a negative number', () {
    final profile = CoupleProfile(
      nameA: 'A',
      nameB: 'B',
      relationshipStart: DateTime(2027),
    );

    expect(profile.togetherDays(DateTime(2026)), 0);
  });
}
