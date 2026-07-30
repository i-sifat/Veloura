import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/app.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/session_repository.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';

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

  testWidgets('onboarding saves names locally and opens Home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _MemorySessionRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWith((ref) async => repository),
        ],
        child: const VelouraApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Make space for each other'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Private by default'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Take turns, stay connected'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text("Who's playing?"), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, 'Alex');
    await tester.enterText(find.byType(TextField).last, 'Jamie');
    await tester.tap(find.text('Start connecting'));
    await tester.pumpAndSettle();

    expect(repository.value?.a.name, 'Alex');
    expect(repository.value?.b.name, 'Jamie');
    expect(find.text('Make time for each other'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
