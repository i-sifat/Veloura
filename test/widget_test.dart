import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/app.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/daily/data/daily_notification_service.dart';
import 'package:veloura/features/daily/domain/daily_challenge.dart';
import 'package:veloura/features/daily/presentation/daily_controller.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';
import 'package:veloura/features/profile/domain/achievement_rules.dart';
import 'package:veloura/features/profile/domain/profile_models.dart';
import 'package:veloura/features/profile/presentation/profile_controller.dart';
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

class _TestDailyController extends DailyController {
  @override
  Future<DailyState> build() async => DailyState(
    challenge: const DailyChallenge(
      id: 'test_daily',
      title: 'A test moment',
      prompt: 'Share one good thing from today.',
      source: DailyChallengeSource.ritual,
      estimatedMinutes: 5,
    ),
    completionDates: const {},
    streak: 0,
    rewardBalance: 0,
    reminder: const DailyReminderSettings(),
    displayedMonth: DateTime(2026, 7),
  );
}

class _TestProfileController extends ProfileController {
  @override
  Future<ProfileState> build() async {
    const stats = ProfileStats(
      diceRolls: 0,
      truthDareCompleted: 0,
      challengesCompleted: 0,
      conversationsAnswered: 0,
      roleplaysCompleted: 0,
      dailyCompletions: 0,
      favorites: 0,
    );
    return ProfileState(
      profile: const CoupleProfile(nameA: 'You', nameB: 'Partner'),
      settings: const ProfileSettings(),
      stats: stats,
      achievements: evaluateAchievements(stats),
      activity: const [],
      favorites: const [],
    );
  }
}

Widget _app() => ProviderScope(
  overrides: [
    sessionRepositoryProvider.overrideWith(
      (ref) async => _MemorySessionRepository(),
    ),
    dailyNotificationServiceProvider.overrideWith(
      (ref) => const NoopDailyNotificationService(),
    ),
    dailyControllerProvider.overrideWith(_TestDailyController.new),
    profileControllerProvider.overrideWith(_TestProfileController.new),
  ],
  child: const VelouraApp(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(
    () => SharedPreferences.setMockInitialValues({
      'session_players_configured': true,
    }),
  );

  testWidgets('Veloura launches into the five-tab Home shell', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Make time for each other'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Home', 'Games', 'Daily', 'Favorites', 'Profile']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('Games exposes all Phase 4.5 catalog entries', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.casino_outlined).last);
    await tester.pumpAndSettle();
    expect(kGameCatalog, hasLength(6));
    final scrollable = find.byType(Scrollable).last;
    for (final entry in kGameCatalog) {
      final tile = find.byKey(ValueKey('game-tile-${entry.id}'));
      await tester.scrollUntilVisible(tile, 180, scrollable: scrollable);
      expect(tile, findsOneWidget);
    }
  });

  testWidgets('selected games open full-screen above the tab shell', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.casino_outlined).last);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey('game-tile-${kGameCatalog.first.id}')),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('remaining navigation branches are reachable', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    expect(find.text('DAILY CONNECTION'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_outline));
    await tester.pumpAndSettle();
    expect(
      find.text('Your saved favorites will appear here.'),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Your connection'), findsOneWidget);
  });
}
