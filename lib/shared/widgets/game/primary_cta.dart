import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Single prominent game action with consistent press feedback.
class PrimaryCta extends StatefulWidget {
  const PrimaryCta({
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  State<PrimaryCta> createState() => _PrimaryCtaState();
}

class _PrimaryCtaState extends State<PrimaryCta> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: AnimatedScale(
        duration: GameTokens.tapScaleDuration,
        curve: Curves.easeOut,
        scale: _pressed ? 0.97 : 1,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: enabled
              ? (_) {
                  setState(() => _pressed = false);
                  HapticFeedback.lightImpact();
                  widget.onPressed!();
                }
              : null,
          child: AnimatedOpacity(
            duration: GameTokens.fadeDuration,
            opacity: enabled ? 1 : 0.38,
            child: Container(
              height: GameTokens.ctaHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GameTokens.ctaRadius),
                gradient: const LinearGradient(
                  colors: [GameTokens.rose, GameTokens.roseDeep],
                ),
                boxShadow: enabled ? const [GameTokens.ctaShadow] : null,
              ),
              alignment: Alignment.center,
              child: widget.busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
