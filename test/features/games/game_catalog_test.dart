import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';

void main() {
  test('Passionate Roleplay hub entry is directly accessible', () {
    final roleplay = kGameCatalog.singleWhere(
      (entry) => entry.id == 'passionate_roleplay',
    );

    expect(roleplay.isPremium, isFalse);
    expect(roleplay.route, '/games/passionate-roleplay');
  });
}
