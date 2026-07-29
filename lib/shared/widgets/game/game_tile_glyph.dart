import 'package:flutter/material.dart';

/// Resilient fallback when commissioned game artwork is unavailable.
class GameTileGlyph extends StatelessWidget {
  const GameTileGlyph({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 110,
      height: 110,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x2EFF8FA3), Colors.transparent],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 44, color: Colors.white.withValues(alpha: 0.9)),
    ),
  );
}
