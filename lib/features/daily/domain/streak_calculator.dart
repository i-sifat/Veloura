import 'package:veloura/features/daily/domain/daily_selector.dart';

/// Computes a transparent hard-reset streak from unique completion days.
///
/// Product rule: a missed calendar day resets the streak. We intentionally do
/// not spend a hidden freeze or premium currency; the behavior is predictable,
/// local-first, and easy to explain. This remains flagged for product sign-off.
class StreakCalculator {
  const StreakCalculator();

  int calculate({
    required Iterable<DateTime> completions,
    required DateTime today,
  }) {
    final days = completions.map(dateOnly).toSet();
    if (days.isEmpty) return 0;
    final currentDay = dateOnly(today);
    var cursor = days.contains(currentDay)
        ? currentDay
        : currentDay.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
