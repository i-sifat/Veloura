import 'package:hive_ce/hive.dart';
import 'package:veloura/services/storage_service.dart';

/// Versioned local schema migration scaffold.
class SchemaMigrationService {
  SchemaMigrationService(this.storage);

  static const currentVersion = 1;
  static const _boxName = 'app_metadata';
  static const _versionKey = 'schema_version';

  final StorageService storage;

  Future<int> migrate() async {
    final box = await storage.box<int>(_boxName);
    var version = box.get(_versionKey, defaultValue: 0) ?? 0;
    while (version < currentVersion) {
      switch (version + 1) {
        case 1:
          await _toVersion1();
      }
      version++;
      await box.put(_versionKey, version);
    }
    return version;
  }

  /// Version 1 records the baseline. Existing Dice and Session boxes already
  /// use field-indexed adapters, so no data rewrite is required.
  Future<void> _toVersion1() async {}
}

/// Testable migration runner independent of Hive I/O.
int nextSchemaVersion(int stored, {int current = currentVersionForTests}) {
  if (stored < 0 || stored > current) {
    throw StateError('Unsupported schema version $stored.');
  }
  return current;
}

const currentVersionForTests = SchemaMigrationService.currentVersion;
