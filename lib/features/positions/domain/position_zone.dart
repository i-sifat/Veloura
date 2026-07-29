import 'package:flutter/material.dart';

/// Body-arrangement zones used by the Creative Positions dial.
enum PositionZone {
  close,
  above,
  behind,
  seated,
  standing,
  wild;

  String get label => name.toUpperCase();

  IconData get icon => switch (this) {
    close => Icons.favorite_outline,
    above => Icons.keyboard_arrow_up,
    behind => Icons.repeat,
    seated => Icons.chair_outlined,
    standing => Icons.accessibility_new,
    wild => Icons.local_fire_department,
  };

  Color get color => switch (this) {
    close => const Color(0xFFC2185B),
    above => const Color(0xFF8E4BD1),
    behind => const Color(0xFF6C1450),
    seated => const Color(0xFFB01047),
    standing => const Color(0xFF7A1D8F),
    wild => const Color(0xFF8E0B2E),
  };
}
