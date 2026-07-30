import 'package:hive_ce/hive.dart';

/// Registers feature Hive adapters once and rejects semantic ID collisions.
class HiveAdapterRegistry {
  final Map<int, Type> _registeredIds = <int, Type>{};

  /// Registers [adapter] unless its exact type was already registered.
  ///
  /// A different adapter claiming the same permanent ID fails before any box
  /// opens, preventing silent data corruption.
  void register<T>(TypeAdapter<T> adapter) {
    final existing = _registeredIds[adapter.typeId];
    if (existing == adapter.runtimeType) return;
    if (existing != null) {
      throw StateError(
        'Hive typeId ${adapter.typeId} collision: $existing and '
        '${adapter.runtimeType}.',
      );
    }
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
    _registeredIds[adapter.typeId] = adapter.runtimeType;
  }

  /// Immutable audit snapshot used by startup verification and tests.
  Map<int, Type> get registeredIds => Map.unmodifiable(_registeredIds);
}
