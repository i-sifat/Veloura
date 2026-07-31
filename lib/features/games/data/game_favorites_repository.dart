import 'package:shared_preferences/shared_preferences.dart';

/// Persists which whole games the couple starred for quick access.
class GameFavoritesRepository {
  GameFavoritesRepository(this.preferences);

  static const key = 'favorite_game_ids';

  final SharedPreferences preferences;

  Set<String> load() => preferences.getStringList(key)?.toSet() ?? <String>{};

  Future<void> save(Set<String> ids) =>
      preferences.setStringList(key, ids.toList());
}
