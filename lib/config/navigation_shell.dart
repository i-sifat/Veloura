import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_theme.dart';

/// Five-tab application shell with a reserved random-game action.
class NavigationShell extends StatelessWidget {
  const NavigationShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _select(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      body: shell,
      floatingActionButton: Semantics(
        button: true,
        label: 'Random game, coming soon',
        child: FloatingActionButton(
          onPressed: null,
          backgroundColor: colors.primary,
          disabledElevation: 0,
          tooltip: 'Random game — coming soon',
          child: const Icon(Icons.shuffle),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(boxShadow: [AppTheme.pinkGlow]),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.casino_outlined),
              selectedIcon: Icon(Icons.casino),
              label: 'Games',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Daily',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
