import 'package:veloura/features/session/data/game_session_adapter.dart';
import 'package:veloura/features/session/data/player_adapter.dart';
import 'package:veloura/services/hive_adapter_registry.dart';

/// Registers session-owned Hive adapters.
void registerSessionAdapters(HiveAdapterRegistry registry) {
  registry
    ..register(PlayerAdapter())
    ..register(GameSessionAdapter());
}
