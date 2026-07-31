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

  testWidgets('onboarding captures the couple and opens Home', (tester) async {
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

    expect(find.text('Stronger together'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Deep conversations'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Track your journey'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('What are your names?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Alex');
    await tester.enterText(find.byType(TextField).last, 'Jamie');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Select sex'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text("You're all set!"), findsOneWidget);
    await tester.tap(find.text('Go to Home'));
    await tester.pumpAndSettle();

    expect(repository.value?.a.name, 'Alex');
    expect(repository.value?.b.name, 'Jamie');
    expect(find.text('Good evening'), findsOneWidget);
    expect(find.text('Angelina 💕'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
