import 'package:veloura/features/profile/domain/profile_models.dart';

/// Pure rules evaluated over existing aggregate data.
List<Achievement> evaluateAchievements(ProfileStats stats) => [
  Achievement(
    id: 'first_spark',
    title: 'First spark',
    description: 'Complete your first shared activity.',
    unlocked: stats.totalPlays >= 1,
  ),
  Achievement(
    id: 'seven_daily',
    title: 'A week together',
    description: 'Complete seven daily connections.',
    unlocked: stats.dailyCompletions >= 7,
  ),
  Achievement(
    id: 'dice_ten',
    title: 'Lucky pair',
    description: 'Roll the dice ten times.',
    unlocked: stats.diceRolls >= 10,
  ),
  Achievement(
    id: 'truth_twenty',
    title: 'Open book',
    description: 'Complete twenty Truth or Dare prompts.',
    unlocked: stats.truthDareCompleted >= 20,
  ),
  Achievement(
    id: 'challenge_ten',
    title: 'Challenge accepted',
    description: 'Finish ten challenge cards.',
    unlocked: stats.challengesCompleted >= 10,
  ),
  Achievement(
    id: 'talk_twenty',
    title: 'Deep listeners',
    description: 'Answer twenty conversation starters.',
    unlocked: stats.conversationsAnswered >= 20,
  ),
  Achievement(
    id: 'roleplay_first',
    title: 'Scene partners',
    description: 'Finish a roleplay scene.',
    unlocked: stats.roleplaysCompleted >= 1,
  ),
  Achievement(
    id: 'favorites_ten',
    title: 'Keepers',
    description: 'Save ten favorites.',
    unlocked: stats.favorites >= 10,
  ),
  Achievement(
    id: 'fifty_plays',
    title: 'Connection ritual',
    description: 'Complete fifty activities together.',
    unlocked: stats.totalPlays >= 50,
  ),
  Achievement(
    id: 'all_core',
    title: 'Try everything',
    description: 'Play Dice, Truth or Dare, Cards, Conversation, Daily, and Roleplay.',
    unlocked: stats.diceRolls > 0 &&
        stats.truthDareCompleted > 0 &&
        stats.challengesCompleted > 0 &&
        stats.conversationsAnswered > 0 &&
        stats.dailyCompletions > 0 &&
        stats.roleplaysCompleted > 0,
  ),
];
