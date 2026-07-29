import 'package:veloura/features/session/domain/player.dart';

/// Persisted two-player session shared by all game modules.
class GameSession {
  const GameSession({
    required this.a,
    required this.b,
    required this.activeIndex,
    required this.startedAt,
  }) : assert(activeIndex == 0 || activeIndex == 1);

  final Player a;
  final Player b;
  final int activeIndex;
  final DateTime startedAt;

  Player get active => activeIndex == 0 ? a : b;
  Player get passive => activeIndex == 0 ? b : a;

  GameSession copyWith({Player? a, Player? b, int? activeIndex}) => GameSession(
    a: a ?? this.a,
    b: b ?? this.b,
    activeIndex: activeIndex ?? this.activeIndex,
    startedAt: startedAt,
  );

  GameSession advanced() => copyWith(activeIndex: 1 - activeIndex);
}
