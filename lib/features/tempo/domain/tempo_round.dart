import 'dart:math';

/// One short tease task in a Follow the Tempo round.
///
/// Each task tells the couple how fast to move (the tempo word) and runs for
/// a short window. The ring on screen fills clockwise as [duration] elapses,
/// then resets for the next task.
class TempoTask {
  const TempoTask({
    required this.label,
    required this.duration,
    required this.beatPeriod,
  });

  /// The tempo word shown on screen: SLOW, FAST, SLOWER, FASTER, BUILD...
  final String label;

  /// How long this task lasts.
  final Duration duration;

  /// Time between heartbeat pulses while this task is active. Slow tasks
  /// pulse slowly; fast tasks pulse quickly.
  final Duration beatPeriod;
}

/// The tempo words cycled across one round.
const kTempoTaskLabels = <String>[
  'SLOW',
  'FAST',
  'SLOWER',
  'FASTER',
  'BUILD',
];

/// Number of tasks in one round.
const kTempoTaskCount = 5;

/// Average task length in seconds.
const kTempoTaskSeconds = 20;

/// Random jitter in seconds applied to each task's length.
const kTempoTaskJitterSeconds = 5;

/// Heartbeat cadence per tempo word.
Duration tempoBeatPeriod(String label) => switch (label) {
  'SLOW' => const Duration(milliseconds: 1000),
  'SLOWER' => const Duration(milliseconds: 1250),
  'FAST' => const Duration(milliseconds: 500),
  'FASTER' => const Duration(milliseconds: 400),
  _ => const Duration(milliseconds: 650),
};

/// Builds a round of short tease tasks.
///
/// Durations are randomized around [kTempoTaskSeconds] so every round feels
/// different. Pass [random] to make a round deterministic (e.g. in tests).
List<TempoTask> buildTempoRound({
  int count = kTempoTaskCount,
  Random? random,
}) {
  final rng = random ?? Random();
  return [
    for (var index = 0; index < count; index++)
      TempoTask(
        label: kTempoTaskLabels[index % kTempoTaskLabels.length],
        duration: Duration(
          seconds: kTempoTaskSeconds +
              rng.nextInt(kTempoTaskJitterSeconds * 2 + 1) -
              kTempoTaskJitterSeconds,
        ),
        beatPeriod: tempoBeatPeriod(
          kTempoTaskLabels[index % kTempoTaskLabels.length],
        ),
      ),
  ];
}
