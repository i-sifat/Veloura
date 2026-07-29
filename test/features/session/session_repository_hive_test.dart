import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/session/data/game_session_adapter.dart';
import 'package:veloura/features/session/data/player_adapter.dart';
import 'package:veloura/features/session/data/session_repository_hive.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/player.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('veloura_session_test_');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PlayerAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(GameSessionAdapter());
  });

  tearDown(() async {
    await Hive.close();
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test('maps a closed-box write failure to AppResult.failure', () async {
    final box = await Hive.openBox<GameSession>('session_failure');
    final repository = SessionRepositoryHive(box);
    await box.close();

    final result = await repository.save(
      GameSession(
        a: const Player(id: 'a', name: 'You', colorValue: 1),
        b: const Player(id: 'b', name: 'Partner', colorValue: 2),
        activeIndex: 0,
        startedAt: DateTime(2026),
      ),
    );

    expect(result, isA<AppFailure<void>>());
  });
}
