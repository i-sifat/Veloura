import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/config/navigation_shell.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';

void main() {
  test('root destinations keep the bottom navigation', () {
    for (final location in [
      '/home',
      '/games',
      '/daily',
      '/favorites',
      '/profile',
    ]) {
      expect(
        shouldShowRootNavigation(location),
        isTrue,
        reason: '$location is a root destination',
      );
    }
  });

  test('every selected game hides the bottom navigation', () {
    for (final game in kGameCatalog) {
      expect(
        shouldShowRootNavigation(game.route),
        isFalse,
        reason: '${game.title} should open as a focused full-screen game',
      );
    }
    expect(
      shouldShowRootNavigation('/games/truth-or-dare/browse'),
      isFalse,
    );
    expect(shouldShowRootNavigation('/home/conversation'), isFalse);
  });
}
