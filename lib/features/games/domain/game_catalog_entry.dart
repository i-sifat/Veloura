import 'package:flutter/material.dart';

/// Immutable presentation metadata for one Games hub destination.
class GameCatalogEntry {
  const GameCatalogEntry({
    required this.id,
    required this.title,
    required this.route,
    required this.art,
    required this.gradient,
    required this.fallbackIcon,
    this.isPremium = false,
  });

  final String id;
  final String title;
  final String route;
  final String art;
  final List<Color> gradient;
  final IconData fallbackIcon;
  final bool isPremium;
}
