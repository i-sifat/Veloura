/// One timed section in a Follow the Tempo round.
class TempoStage {
  const TempoStage({
    required this.bpm,
    required this.length,
    required this.label,
  });

  final int bpm;
  final Duration length;
  final String label;

  /// Time between visual beats for this stage.
  Duration get beatPeriod => Duration(
    microseconds: Duration.microsecondsPerMinute ~/ bpm,
  );
}
