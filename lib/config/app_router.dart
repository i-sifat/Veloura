import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/config/navigation_shell.dart';
import 'package:veloura/features/cards/presentation/challenge_screen.dart';
import 'package:veloura/features/cards/presentation/fan/card_challenge_fan_screen.dart';
import 'package:veloura/features/conversation/presentation/conversation_screen.dart';
import 'package:veloura/features/conversation/presentation/stack/creative_connections_screen.dart';
import 'package:veloura/features/daily/presentation/daily_screen.dart';
import 'package:veloura/features/dice/presentation/dice_screen.dart';
import 'package:veloura/features/dice/presentation/love_dice_intro_screen.dart';
import 'package:veloura/features/games/presentation/games_hub_screen.dart';
import 'package:veloura/features/home/presentation/home_screen.dart';
import 'package:veloura/features/onboarding/data/onboarding_repository.dart';
import 'package:veloura/features/onboarding/presentation/onboarding_screen.dart';
import 'package:veloura/features/positions/presentation/creative_positions_screen.dart';
import 'package:veloura/features/premium/presentation/premium_paywall_screen.dart';
import 'package:veloura/features/profile/presentation/favorites_screen.dart';
import 'package:veloura/features/profile/presentation/profile_screen.dart';
import 'package:veloura/features/roleplay/presentation/wheel/roleplay_spin_screen.dart';
import 'package:veloura/features/tempo/presentation/follow_the_tempo_screen.dart';
import 'package:veloura/features/truth_dare/presentation/truth_dare_screen.dart';
import 'package:veloura/features/truth_dare/presentation/wheel/truth_or_dare_wheel_screen.dart';
import 'package:veloura/shared/widgets/navigation/confirm_exit_scope.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

Widget _protectedGame(Widget child) => ConfirmExitScope(child: child);

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) async {
      final onboarding = OnboardingRepository(
        await SharedPreferences.getInstance(),
      );
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!onboarding.isComplete && !onOnboarding) return '/onboarding';
      if (onboarding.isComplete && onOnboarding) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/daily', builder: (_, _) => const DailyScreen()),
      GoRoute(
        path: '/premium',
        builder: (_, state) => PremiumPaywallScreen(
          source: state.uri.queryParameters['source'] ?? 'unknown',
        ),
      ),
      // Flat, top-level routes for every screen that gets `push()`-ed from a
      // screen that itself already lives on the root navigator (via
      // `parentNavigatorKey`). These must NOT be declared as nested child
      // `routes:` under that screen's GoRoute.
      //
      // Why: go_router's `push()` resolves a location by matching the
      // *entire* route chain down to the target and building a Page for
      // every matched segment bound to a given Navigator. If the target is
      // a child of a route that's already on the root navigator (e.g.
      // 'play' under 'lustful-rolls'), every push to the child re-matches
      // and re-builds a brand-new Page for the parent too, stacking a
      // second copy of it underneath the child on the root navigator -
      // even though a page for that parent is already there from the
      // earlier navigation that opened it. Popping the child then lands on
      // that fresh duplicate parent, not the real previous screen, which
      // reads as navigation being stuck in a loop (this was the actual
      // cause of Love Dice's "Start game" screen reappearing after leaving
      // the dice game - see the flattened '/games/lustful-rolls/play'
      // below). Declaring the target as its own flat, absolute-path route
      // instead means push() only ever matches and builds that one page.
      GoRoute(
        path: '/games/lustful-rolls/play',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => _protectedGame(const DiceScreen()),
      ),
      GoRoute(
        path: '/games/card-challenge/browse',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => _protectedGame(const ChallengeScreen()),
      ),
      GoRoute(
        path: '/games/truth-or-dare/browse',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => _protectedGame(const TruthDareScreen()),
      ),
      GoRoute(
        path: '/games/creative-connections/browse',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => _protectedGame(const ConversationScreen()),
      ),
      GoRoute(
        path: '/home/conversation/browse',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => _protectedGame(const ConversationScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => NavigationShell(
          shell: shell,
          location: state.uri.path,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'conversation',
                    builder: (_, _) =>
                        _protectedGame(const CreativeConnectionsScreen()),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/games',
                builder: (_, _) => const GamesHubScreen(),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'lustful-rolls',
                    builder: (_, _) => const LoveDiceIntroScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'card-challenge',
                    builder: (_, _) =>
                        _protectedGame(const CardChallengeFanScreen()),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'truth-or-dare',
                    builder: (_, _) =>
                        _protectedGame(const TruthOrDareWheelScreen()),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'creative-connections',
                    builder: (_, _) =>
                        _protectedGame(const CreativePositionsScreen()),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'follow-the-tempo',
                    builder: (_, _) =>
                        _protectedGame(const FollowTheTempoScreen()),
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'passionate-roleplay',
                    builder: (_, _) =>
                        _protectedGame(const RoleplaySpinScreen()),
                  ),
                  GoRoute(
                    path: 'dice',
                    redirect: (_, _) => '/games/lustful-rolls',
                  ),
                  GoRoute(
                    path: 'challenges',
                    redirect: (_, _) => '/games/card-challenge',
                  ),
                  GoRoute(
                    path: 'conversation',
                    redirect: (_, _) => '/home/conversation',
                  ),
                  GoRoute(
                    path: 'roleplay',
                    redirect: (_, _) => '/games/passionate-roleplay',
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (_, _) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
