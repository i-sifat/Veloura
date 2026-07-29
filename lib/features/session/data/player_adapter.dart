import 'package:hive_ce/hive.dart';
import 'package:veloura/features/session/domain/player.dart';

/// Hive adapter for [Player].
class PlayerAdapter extends TypeAdapter<Player> {
  @override
  int get typeId => 2;

  @override
  Player read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var index = 0; index < reader.readByte(); index++)
        reader.readByte(): reader.read(),
    };
    return Player(
      id: fields[0] as String,
      name: fields[1] as String,
      colorValue: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorValue);
  }
}
