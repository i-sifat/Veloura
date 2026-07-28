import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Owns Hive initialization and typed box access.
class StorageService {
  var _initialized = false;

  /// Initializes Hive once per process.
  Future<void> initialize() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _initialized = true;
  }

  /// Opens or returns a typed Hive box.
  Future<Box<T>> box<T>(String name) async {
    if (!_initialized) {
      throw StateError('StorageService.initialize must be called first.');
    }
    if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
    return Hive.openBox<T>(name);
  }
}

/// Application storage dependency.
final storageServiceProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError('StorageService must be overridden at root.'),
);
