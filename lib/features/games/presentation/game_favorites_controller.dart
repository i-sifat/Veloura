import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/features/games/data/game_favorites_repository.dart';

/// Tracks which whole games are starred for the Favorites > Games tab.
class GameFavoritesController extends AsyncNotifier<Set<String>> {
  late GameFavoritesRepository _repository;

  @override
  Future<Set<String>> build() async {
    _repository = GameFavoritesRepository(
      await SharedPreferences.getInstance(),
    );
    return _repository.load();
  }

  Future<void> toggle(String gameId) async {
    final current = state.asData?.value ?? <String>{};
    final updated = {...current};
    if (!updated.remove(gameId)) updated.add(gameId);
    state = AsyncData(updated);
    await _repository.save(updated);
  }

  Future<void> clear() async {
    state = const AsyncData(<String>{});
    await _repository.save(const <String>{});
  }
}

/// Starred whole-game ids, shared by the Games hub and Favorites screens.
final gameFavoritesControllerProvider =
    AsyncNotifierProvider<GameFavoritesController, Set<String>>(
      GameFavoritesController.new,
    );
