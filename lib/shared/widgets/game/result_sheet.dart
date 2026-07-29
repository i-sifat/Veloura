import 'package:flutter/material.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Consistent modal result surface used by game-specific flows.
abstract final class ResultSheet {
  static Future<T?> show<T>(BuildContext context, {required Widget child}) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        barrierColor: GameTokens.scrim,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          decoration: const BoxDecoration(
            color: GameTokens.sheet,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(GameTokens.sheetRadius),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      );
}
