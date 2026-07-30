import 'package:flutter/services.dart';
import 'package:veloura/services/storage_service.dart';

class ContentSeedService {
  ContentSeedService(this.storage, {AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const seedVersion = 1;
  static const _boxName = 'content_seed_cache';
  static const _versionKey = '__seed_version__';
  static const assets = <String>[
    'lib/features/truth_dare/data/truth_dare_seed.json',
    'lib/features/cards/data/challenge_seed.json',
    'lib/features/conversation/data/conversation_seed.json',
    'lib/features/roleplay/data/roleplay_seed.json',
  ];

  final StorageService storage;
  final AssetBundle _bundle;

  Future<bool> seedIfNeeded() async {
    final box = await storage.box<String>(_boxName);
    final stored = int.tryParse(box.get(_versionKey) ?? '') ?? 0;
    if (!shouldSeed(storedVersion: stored, targetVersion: seedVersion)) {
      return false;
    }
    final values = <String, String>{};
    for (final asset in assets) {
      values[asset] = await _bundle.loadString(asset);
    }
    await box.putAll(values);
    await box.put(_versionKey, '$seedVersion');
    return true;
  }
}

bool shouldSeed({required int storedVersion, required int targetVersion}) =>
    storedVersion < targetVersion;
