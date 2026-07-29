import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/config/navigation_shell.dart';
import 'package:veloura/features/cards/presentation/challenge_screen.dart';
import 'package:veloura/features/conversation/presentation/conversation_screen.dart';
import 'package:veloura/features/dice/presentation/dice_screen.dart';
import 'package:veloura/features/games/presentation/games_screen.dart';
import 'package:veloura/features/home/presentation/home_screen.dart';
import 'package:veloura/features/truth_dare/presentation/truth_dare_screen.dart';
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
                builder: (_, _) => const GamesScreen(),
                routes: [
                  GoRoute(path: 'dice', builder: (_, _) => const DiceScreen()),
                  GoRoute(
                    path: 'truth-dare',
                    builder: (_, _) => const TruthDareScreen(),
                  ),
                  GoRoute(
                    path: 'challenges',
                    builder: (_, _) => const ChallengeScreen(),
                  ),
                  GoRoute(
                    path: 'conversation',
                    builder: (_, _) => const ConversationScreen(),
                  ),
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
