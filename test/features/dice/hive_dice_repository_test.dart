import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/dice/data/dice_roll_record_adapter.dart';
import 'package:veloura/features/dice/data/hive_dice_repository.dart';
import 'package:veloura/features/dice/domain/dice_repository.dart';
import 'package:veloura/features/dice/domain/dice_roll_record.dart';

void main() {
  late Directory directory;
  late HiveDiceRepository repository;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('veloura_dice_test');
    Hive.init(directory.path);
    Hive.registerAdapter(DiceRollRecordAdapter());
    repository = HiveDiceRepository(
      historyBox: await Hive.openBox<DiceRollRecord>('history'),
      settingsBox: await Hive.openBox<String>('settings'),
    );
  });

  tearDown(() async {
    await repository.historyBox.clear();
    await repository.settingsBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('persists history newest first and toggles favorites', () async {
    final older = DiceRollRecord(
      id: 'older',
      action: 'Hold',
      body: 'their hand',
      createdAt: DateTime(2026),
    );
    final newer = DiceRollRecord(
      id: 'newer',
      action: 'Kiss',
      body: 'their cheek',
      createdAt: DateTime(2026, 1, 2),
    );

    expect(await repository.saveRoll(older), isA<AppSuccess<DiceRollRecord>>());
    await repository.saveRoll(newer);
    final history = await repository.getHistory() as AppSuccess<List<DiceRollRecord>>;

    expect(history.value.map((roll) => roll.id), ['newer', 'older']);

    final favorite = await repository.toggleFavorite('newer') as AppSuccess<DiceRollRecord>;
    expect(favorite.value.favorite, isTrue);
    expect(repository.historyBox.get('newer')!.favorite, isTrue);
  });

  test('persists premium custom face sets', () async {
    const faces = DiceFaceSet(
      actions: ['Smile', 'Dance'],
      bodies: ['together', 'nearby'],
    );

    await repository.saveCustomFaces(faces);
    final loaded = await repository.getCustomFaces() as AppSuccess<DiceFaceSet?>;

    expect(loaded.value!.actions, faces.actions);
    expect(loaded.value!.bodies, faces.bodies);
  });

  test('record summary includes optional third die', () {
    final record = DiceRollRecord(
      id: 'one',
      action: 'Whisper to',
      body: 'their ear',
      extra: 'for 10 seconds',
      createdAt: DateTime(2026),
    );

    expect(record.summary, 'Whisper to • their ear • for 10 seconds');
  });
}
