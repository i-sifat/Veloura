import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/app.dart';
import 'package:veloura/features/dice/data/dice_hive_registration.dart';
import 'package:veloura/features/session/data/session_hive_registration.dart';
import 'package:veloura/services/analytics_service.dart';
import 'package:veloura/services/content_seed_service.dart';
import 'package:veloura/services/crash_reporting_service.dart';
import 'package:veloura/services/firebase_bootstrap.dart';
import 'package:veloura/services/hive_adapter_registry.dart';
import 'package:veloura/services/schema_migration_service.dart';
import 'package:veloura/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = StorageService();
  await storageService.initialize();

  final registry = HiveAdapterRegistry();
  registerDiceAdapters(registry);
  registerSessionAdapters(registry);
  assert(registry.registeredIds.length == 3);

  await SchemaMigrationService(storageService).migrate();
  await ContentSeedService(storageService).seedIfNeeded();
  final firebase = await initializeFirebaseSafely();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        analyticsServiceProvider.overrideWithValue(firebase.analytics),
        crashReportingServiceProvider.overrideWithValue(
          firebase.crashReporting,
        ),
      ],
      child: const VelouraApp(),
    ),
  );
}
