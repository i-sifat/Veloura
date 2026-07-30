import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared haptic boundary governed by the persisted Profile setting.
abstract final class AppHaptics {
  static Future<bool> get enabled async =>
      (await SharedPreferences.getInstance()).getBool('game_vibration') ?? true;

  static Future<void> lightImpact() async {
    if (await enabled) await HapticFeedback.lightImpact();
  }

  static Future<void> mediumImpact() async {
    if (await enabled) await HapticFeedback.mediumImpact();
  }

  static Future<void> heavyImpact() async {
    if (await enabled) await HapticFeedback.heavyImpact();
  }

  static Future<void> selectionClick() async {
    if (await enabled) await HapticFeedback.selectionClick();
  }
}
