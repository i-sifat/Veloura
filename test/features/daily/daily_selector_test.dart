import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/daily/domain/daily_challenge.dart';
import 'package:veloura/features/daily/domain/daily_selector.dart';

void main() {
  final pool = List.generate(
    101,
    (index) => DailyChallenge(
      id: 'daily_$index',
      title: 'Challenge $index',
      prompt: 'Prompt $index',
      source: DailyChallengeSource.ritual,
    ),
  );

  test('selection stays stable throughout the same local day', () {
    const selector = DailySelector();
    final morning = selector.select(
      pool: pool,
      deviceSeed: 'device-a',
      date: DateTime(2026, 7, 30, 1),
    );
    final evening = selector.select(
      pool: pool,
      deviceSeed: 'device-a',
      date: DateTime(2026, 7, 30, 23, 59),
    );

    expect(evening.id, morning.id);
  });

  test('date seed changes deterministically', () {
    const selector = DailySelector();
    final ids = {
      for (var day = 1; day <= 14; day++)
        selector
            .select(
              pool: pool,
              deviceSeed: 'device-a',
              date: DateTime(2026, 7, day),
            )
            .id,
    };

    expect(ids.length, greaterThan(1));
  });
}
