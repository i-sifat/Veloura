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

Future<void> _skipToNamesPage(WidgetTester tester) async {
  // The intro action button is now an icon-only circle on all three intro
  // pages, so tap it by key rather than by the removed "Get started" label.
  await tester.tap(find.byKey(const ValueKey('onboarding-next')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('onboarding-next')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('onboarding-next')));
  await tester.pumpAndSettle();
}

Future<void> _selectBothSexes(WidgetTester tester) async {
  await tester.tap(find.text('Female').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Male').last);
  await tester.pumpAndSettle();
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
    await _skipToNamesPage(tester);

    expect(find.text('What are your names?'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Alex');
    await tester.enterText(find.byType(TextFormField).last, 'Jamie');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Select sex'), findsOneWidget);
    await _selectBothSexes(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text("You're all set!"), findsOneWidget);
    await tester.tap(find.text('Go to Home'));
    await tester.pumpAndSettle();

    expect(repository.value?.a.name, 'Alex');
    expect(repository.value?.b.name, 'Jamie');
    expect(find.text('Good evening'), findsOneWidget);
    // The greeting now uses the couple's real captured name, not a
    // hardcoded placeholder.
    expect(find.text('Alex \u{1F495}'), findsOneWidget);
    for (final label in ['Home', 'Games', 'Favorites', 'Profile']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('names page rejects blank names and blocks navigation', (
    tester,
  ) async {
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

    await _skipToNamesPage(tester);
    expect(find.text('What are your names?'), findsOneWidget);

    // Neither field has been touched - tapping Continue must not advance.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What are your names?'), findsOneWidget);
    expect(find.text('Select sex'), findsNothing);
    expect(find.text('Please enter a name'), findsNWidgets(2));

    // Filling only one field still blocks navigation.
    await tester.enterText(find.byType(TextFormField).first, 'Alex');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What are your names?'), findsOneWidget);
    expect(find.text('Please enter a name'), findsNWidgets(1));

    // Filling both fields lets Continue proceed.
    await tester.enterText(find.byType(TextFormField).last, 'Jamie');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Select sex'), findsOneWidget);
  });

  testWidgets('sex page requires both selections before continuing', (
    tester,
  ) async {
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

    await _skipToNamesPage(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Alex');
    await tester.enterText(find.byType(TextFormField).last, 'Jamie');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Select sex'), findsOneWidget);

    // Nothing selected yet - Continue must not advance.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Select sex'), findsOneWidget);
    expect(find.text("You're all set!"), findsNothing);

    // Selecting only one side still blocks navigation.
    await tester.tap(find.text('Female').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Select sex'), findsOneWidget);

    // Selecting both lets Continue proceed.
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text("You're all set!"), findsOneWidget);
  });
}
