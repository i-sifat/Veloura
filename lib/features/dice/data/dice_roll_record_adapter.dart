import 'package:hive_ce/hive.dart';
import 'package:veloura/features/dice/domain/dice_roll_record.dart';

/// Hive adapter for [DiceRollRecord].
class DiceRollRecordAdapter extends TypeAdapter<DiceRollRecord> {
  @override
  int get typeId => 1;

  @override
  DiceRollRecord read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var index = 0; index < reader.readByte(); index++)
        reader.readByte(): reader.read(),
    };
    return DiceRollRecord(
      id: fields[0] as String,
      action: fields[1] as String,
      body: fields[2] as String,
      extra: fields[3] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      favorite: fields[5] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, DiceRollRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.action)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.extra)
      ..writeByte(4)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.favorite);
  }
}
