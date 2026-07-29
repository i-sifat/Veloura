import 'package:hive_ce/hive.dart';

/// Feature-owned adapter registrar used to avoid a central merge hotspot.
typedef HiveAdapterRegistration = void Function();

/// Registers feature Hive adapters once.
class HiveAdapterRegistry {
  final Set<Type> _registered = <Type>{};

  /// Registers [adapter] unless its runtime type is already registered.
  void register<T>(TypeAdapter<T> adapter) {
    if (_registered.add(adapter.runtimeType)) Hive.registerAdapter<T>(adapter);
  }
}
