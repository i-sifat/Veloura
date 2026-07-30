import 'package:veloura/services/storage_service.dart';

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

  Future<void> _toVersion1() async {}
}

int nextSchemaVersion(int stored, {int current = currentVersionForTests}) {
  if (stored < 0 || stored > current) {
    throw StateError('Unsupported schema version $stored.');
  }
  return current;
}

const currentVersionForTests = SchemaMigrationService.currentVersion;
