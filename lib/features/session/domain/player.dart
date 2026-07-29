/// One participant in the shared two-player game session.
class Player {
  const Player({required this.id, required this.name, required this.colorValue});

  final String id;
  final String name;
  final int colorValue;

  Player copyWith({String? name, int? colorValue}) => Player(
    id: id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
  );
}
