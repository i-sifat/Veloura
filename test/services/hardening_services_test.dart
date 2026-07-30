import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:veloura/services/content_seed_service.dart';
import 'package:veloura/services/hive_adapter_registry.dart';
import 'package:veloura/services/schema_migration_service.dart';

class _ValueA {
  const _ValueA();
}

class _ValueB {
  const _ValueB();
}

class _AdapterA extends TypeAdapter<_ValueA> {
  @override
  int get typeId => 201;
  @override
  _ValueA read(BinaryReader reader) => const _ValueA();
  @override
  void write(BinaryWriter writer, _ValueA obj) {}
}

class _AdapterB extends TypeAdapter<_ValueB> {
  @override
  int get typeId => 201;
  @override
  _ValueB read(BinaryReader reader) => const _ValueB();
  @override
  void write(BinaryWriter writer, _ValueB obj) {}
}

void main() {
  test('adapter registry rejects semantic type ID collisions', () {
    final registry = HiveAdapterRegistry()..register(_AdapterA());

    expect(() => registry.register(_AdapterB()), throwsStateError);
    expect(registry.registeredIds[201], _AdapterA);
  });

  test('seed version check is idempotent', () {
    expect(shouldSeed(storedVersion: 0, targetVersion: 1), isTrue);
    expect(shouldSeed(storedVersion: 1, targetVersion: 1), isFalse);
    expect(shouldSeed(storedVersion: 2, targetVersion: 1), isFalse);
  });

  test('schema version rejects unsupported future data', () {
    expect(nextSchemaVersion(0), SchemaMigrationService.currentVersion);
    expect(() => nextSchemaVersion(2), throwsStateError);
  });
}
