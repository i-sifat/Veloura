import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/app.dart';
import 'package:veloura/features/dice/data/dice_hive_registration.dart';
import 'package:veloura/features/session/data/session_hive_registration.dart';
import 'package:veloura/services/hive_adapter_registry.dart';
import 'package:veloura/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = StorageService();
  await storageService.initialize();
  final registry = HiveAdapterRegistry();
  registerDiceAdapters(registry);
  registerSessionAdapters(registry);

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storageService)],
      child: const VelouraApp(),
    ),
  );
}
