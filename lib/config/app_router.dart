import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/config/navigation_shell.dart';
import 'package:veloura/features/cards/presentation/challenge_screen.dart';
import 'package:veloura/features/cards/presentation/fan/card_challenge_fan_screen.dart';
import 'package:veloura/features/conversation/presentation/conversation_screen.dart';
import 'package:veloura/features/conversation/presentation/stack/creative_connections_screen.dart';
import 'package:veloura/features/daily/presentation/daily_screen.dart';
import 'package:veloura/features/dice/presentation/dice_screen.dart';
import 'package:veloura/features/games/presentation/games_hub_screen.dart';
import 'package:veloura/features/home/presentation/home_screen.dart';
import 'package:veloura/features/positions/presentation/creative_positions_screen.dart';
import 'package:veloura/features/premium/presentation/premium_paywall_screen.dart';
import 'package:veloura/features/profile/presentation/favorites_screen.dart';
import 'package:veloura/features/profile/presentation/profile_screen.dart';
import 'package:veloura/features/roleplay/presentation/flow/roleplay_flow_screen.dart';
import 'package:veloura/features/tempo/presentation/follow_the_tempo_screen.dart';
import 'package:veloura/features/truth_dare/presentation/truth_dare_screen.dart';
import 'package:veloura/features/truth_dare/presentation/wheel/truth_or_dare_wheel_screen.dart';

/// Application router with state-preserving bottom-navigation branches.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/premium',
        builder: (_, state) => PremiumPaywallScreen(
          source: state.uri.queryParameters['source'] ?? 'unknown',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => NavigationShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'conversation',
                    builder: (_, _) => const CreativeConnectionsScreen(),
                    routes: [
                      GoRoute(path: 'browse', builder: (_, _) => const ConversationScreen()),
                    ],
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
                  GoRoute(path: 'lustful-rolls', builder: (_, _) => const DiceScreen()),
                  GoRoute(
                    path: 'card-challenge',
                    builder: (_, _) => const CardChallengeFanScreen(),
                    routes: [GoRoute(path: 'browse', builder: (_, _) => const ChallengeScreen())],
                  ),
                  GoRoute(
                    path: 'truth-or-dare',
                    builder: (_, _) => const TruthOrDareWheelScreen(),
                    routes: [GoRoute(path: 'browse', builder: (_, _) => const TruthDareScreen())],
                  ),
                  GoRoute(
                    path: 'creative-connections',
                    builder: (_, _) => const CreativePositionsScreen(),
                    routes: [GoRoute(path: 'browse', builder: (_, _) => const ConversationScreen())],
                  ),
                  GoRoute(path: 'follow-the-tempo', builder: (_, _) => const FollowTheTempoScreen()),
                  GoRoute(path: 'passionate-roleplay', builder: (_, _) => const RoleplayFlowScreen()),
                  GoRoute(path: 'dice', redirect: (_, _) => '/games/lustful-rolls'),
                  GoRoute(path: 'challenges', redirect: (_, _) => '/games/card-challenge'),
                  GoRoute(path: 'conversation', redirect: (_, _) => '/home/conversation'),
                  GoRoute(path: 'roleplay', redirect: (_, _) => '/games/passionate-roleplay'),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/daily', builder: (_, _) => const DailyScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
