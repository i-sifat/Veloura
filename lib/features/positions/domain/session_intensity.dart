/// How intensely the couple moves during one revealed position session,
/// chosen from the current session heat.
enum PositionSessionIntensity {
  soft('SOFT', Duration(milliseconds: 1000)),
  fast('FAST', Duration(milliseconds: 500)),
  hardcore('HARDCORE', Duration(milliseconds: 350));

  const PositionSessionIntensity(this.label, this.beatPeriod);

  /// The word shown on the timer ring.
  final String label;

  /// Time between heartbeat pulses while this session runs.
  final Duration beatPeriod;

  static PositionSessionIntensity forHeat(int heat) => switch (heat) {
    <= 2 => soft,
    3 => fast,
    _ => hardcore,
  };
}

/// How long the couple holds a revealed position, scaled by heat. Colder
/// rounds get a shorter, softer window; hot rounds run long and intense.
int positionSessionSeconds(int heat) => switch (heat) {
  <= 2 => 60,
  3 => 90,
  _ => 120,
};
