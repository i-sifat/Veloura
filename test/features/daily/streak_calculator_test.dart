import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/daily/domain/streak_calculator.dart';

void main() {
  const calculator = StreakCalculator();

  test('counts a consecutive streak ending today', () {
    final today = DateTime(2026, 7, 30);
    final streak = calculator.calculate(
      completions: [
        DateTime(2026, 7, 28),
        DateTime(2026, 7, 29),
        DateTime(2026, 7, 30),
      ],
      today: today,
    );

    expect(streak, 3);
  });

  test('keeps yesterday streak alive until today ends', () {
    final streak = calculator.calculate(
      completions: [DateTime(2026, 7, 28), DateTime(2026, 7, 29)],
      today: DateTime(2026, 7, 30, 16),
    );

    expect(streak, 2);
  });

  test('hard resets after a missed day', () {
    final streak = calculator.calculate(
      completions: [DateTime(2026, 7, 27), DateTime(2026, 7, 30)],
      today: DateTime(2026, 7, 30),
    );

    expect(streak, 1);
  });
}
