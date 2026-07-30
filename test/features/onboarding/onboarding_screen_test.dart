import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/app.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/session_repository.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/services/storage_service.dart';

class _MemorySessionRepository implements SessionRepository {
  GameSession? value;
  @override
  Future<AppResult<GameSession?>> load() async => AppResult.success(value);
  @override
  Future<AppResult<void>> save(GameSession session) async {
    value = session;
    return const AppResult.success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new install opens onboarding and advances through three steps', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.initialize();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          sessionRepositoryProvider.overrideWith(
            (ref) async => _MemorySessionRepository(),
          ),
        ],
        child: const VelouraApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Make space for each other'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Private by default'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text("Who's playing?"), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
