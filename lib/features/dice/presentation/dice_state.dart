import 'package:veloura/features/dice/domain/dice_roll_record.dart';

/// Dice roll lifecycle.
enum DiceRollStatus { idle, rolling, result }

/// Immutable state rendered by the Dice screen.
class DiceState {
  const DiceState({
    required this.status,
    required this.history,
    required this.actions,
    required this.bodies,
    required this.extras,
    this.current,
    this.useThirdDie = false,
    this.customFacesEnabled = false,
  });

  final DiceRollStatus status;
  final DiceRollRecord? current;
  final List<DiceRollRecord> history;
  final List<String> actions;
  final List<String> bodies;
  final List<String> extras;
  final bool useThirdDie;
  final bool customFacesEnabled;

  DiceState copyWith({
    DiceRollStatus? status,
    DiceRollRecord? current,
    List<DiceRollRecord>? history,
    List<String>? actions,
    List<String>? bodies,
    bool? useThirdDie,
    bool? customFacesEnabled,
  }) => DiceState(
    status: status ?? this.status,
    current: current ?? this.current,
    history: history ?? this.history,
    actions: actions ?? this.actions,
    bodies: bodies ?? this.bodies,
    extras: extras,
    useThirdDie: useThirdDie ?? this.useThirdDie,
    customFacesEnabled: customFacesEnabled ?? this.customFacesEnabled,
  );
}
