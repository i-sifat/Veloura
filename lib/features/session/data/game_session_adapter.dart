import 'package:hive_ce/hive.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/player.dart';

/// Hive adapter for [GameSession].
class GameSessionAdapter extends TypeAdapter<GameSession> {
  @override
  int get typeId => 3;

  @override
  GameSession read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var index = 0; index < reader.readByte(); index++)
        reader.readByte(): reader.read(),
    };
    return GameSession(
      a: fields[0] as Player,
      b: fields[1] as Player,
      activeIndex: fields[2] as int,
      startedAt: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
    );
  }

  @override
  void write(BinaryWriter writer, GameSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.a)
      ..writeByte(1)
      ..write(obj.b)
      ..writeByte(2)
      ..write(obj.activeIndex)
      ..writeByte(3)
      ..write(obj.startedAt.millisecondsSinceEpoch);
  }
}
