import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/config/navigation_shell.dart';
import 'package:veloura/features/cards/presentation/challenge_screen.dart';
import 'package:veloura/features/conversation/presentation/conversation_screen.dart';
import 'package:veloura/features/dice/presentation/dice_screen.dart';
import 'package:veloura/features/games/presentation/games_hub_screen.dart';
import 'package:veloura/features/games/presentation/tempo_placeholder_screen.dart';
import 'package:veloura/features/home/presentation/home_screen.dart';
import 'package:veloura/features/roleplay/presentation/roleplay_screen.dart';
import 'package:veloura/features/truth_dare/presentation/truth_dare_screen.dart';
import 'package:veloura/features/truth_dare/presentation/wheel/truth_or_dare_wheel_screen.dart';
import 'package:veloura/shared/widgets/placeholder_screen.dart';

/// Application router with state-preserving bottom-navigation branches.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => NavigationShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/games',
                builder: (_, _) => const GamesHubScreen(),
                routes: [
                  GoRoute(path: 'lustful-rolls', builder: (_, _) => const DiceScreen()),
                  GoRoute(path: 'card-challenge', builder: (_, _) => const ChallengeScreen()),
                  GoRoute(
                    path: 'truth-or-dare',
                    builder: (_, _) => const TruthOrDareWheelScreen(),
                    routes: [
                      GoRoute(path: 'browse', builder: (_, _) => const TruthDareScreen()),
                    ],
                  ),
                  GoRoute(
                    path: 'creative-connections',
                    builder: (_, _) => const ConversationScreen(),
                  ),
                  GoRoute(
                    path: 'follow-the-tempo',
                    builder: (_, _) => const TempoPlaceholderScreen(),
                  ),
                  GoRoute(
                    path: 'passionate-roleplay',
                    builder: (_, _) => const RoleplayScreen(),
                  ),
                  GoRoute(path: 'dice', redirect: (_, _) => '/games/lustful-rolls'),
                  GoRoute(path: 'challenges', redirect: (_, _) => '/games/card-challenge'),
                  GoRoute(path: 'conversation', redirect: (_, _) => '/games/creative-connections'),
                  GoRoute(path: 'roleplay', redirect: (_, _) => '/games/passionate-roleplay'),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/daily',
                builder: (_, _) => const PlaceholderScreen(
                  title: 'Daily',
                  icon: Icons.calendar_today_outlined,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (_, _) => const PlaceholderScreen(
                  title: 'Favorites',
                  icon: Icons.favorite_outline,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const PlaceholderScreen(
                  title: 'Profile',
                  icon: Icons.person_outline,
                ),
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
