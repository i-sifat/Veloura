import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/l10n/app_localizations.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_theme.dart';

/// Whether a route belongs to one of the five root destinations.
bool shouldShowRootNavigation(String location) =>
    !location.startsWith('/games/') && location != '/home/conversation' &&
    !location.startsWith('/home/conversation/');

/// Five-tab application shell shown only at root-level destinations.
class NavigationShell extends StatelessWidget {
  const NavigationShell({
    required this.shell,
    required this.location,
    super.key,
  });

  final StatefulNavigationShell shell;
  final String location;

  void _select(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppLocalizations.of(context);
    final showNavigation = shouldShowRootNavigation(location);
    return Scaffold(
      body: shell,
      floatingActionButton: showNavigation
          ? Semantics(
              button: true,
              label: strings.randomGame,
              child: FloatingActionButton(
                onPressed: null,
                backgroundColor: colors.primary,
                disabledElevation: 0,
                tooltip: strings.randomGame,
                child: const Icon(Icons.shuffle),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: showNavigation
          ? DecoratedBox(
              decoration: const BoxDecoration(boxShadow: [AppTheme.pinkGlow]),
              child: NavigationBar(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _select,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: strings.homeTab,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.casino_outlined),
                    selectedIcon: const Icon(Icons.casino),
                    label: strings.gamesTab,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.calendar_today_outlined),
                    selectedIcon: const Icon(Icons.calendar_today),
                    label: strings.dailyTab,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.favorite_outline),
                    selectedIcon: const Icon(Icons.favorite),
                    label: strings.favoritesTab,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: const Icon(Icons.person),
                    label: strings.profileTab,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
