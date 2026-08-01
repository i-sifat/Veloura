import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/l10n/app_localizations.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_design_tokens.dart';

/// Whether a route belongs to one of the four root destinations.
bool shouldShowRootNavigation(String location) =>
    !location.startsWith('/games/') &&
    location != '/home/conversation' &&
    !location.startsWith('/home/conversation/');

/// Four-tab application shell shown only at root-level destinations.
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
    final destinations = [
      (Icons.home_outlined, Icons.home_rounded, strings.homeTab),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, strings.gamesTab),
      (Icons.favorite_border, Icons.favorite, strings.favoritesTab),
      (Icons.person_outline, Icons.person, strings.profileTab),
    ];

    return Scaffold(
      body: shell,
      bottomNavigationBar: showNavigation
          ? Container(
              height: AppDesignTokens.navHeight +
                  MediaQuery.paddingOf(context).bottom,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.divider)),
                boxShadow: const [AppDesignTokens.surfaceShadow],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var index = 0; index < destinations.length; index++)
                    _NavItem(
                      icon: destinations[index].$1,
                      selectedIcon: destinations[index].$2,
                      label: destinations[index].$3,
                      selected: shell.currentIndex == index,
                      onTap: () => _select(index),
                    ),
                ],
              ),
            )
          : null,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    // `buttonFill` (deep, AAA-safe red) instead of the lighter `primary`
    // pink, matching the red already used for the "Let's play" CTA and the
    // Games hub category pills.
    final color = selected ? colors.buttonFill : colors.textSecondary;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, color: color, size: 27),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
