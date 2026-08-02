import 'package:flutter/material.dart';

/// One face of a [WordDie]: an ivory rounded panel showing a single
/// centered, auto-sized word - no pips, no numbers.
class WordDieFace extends StatelessWidget {
  const WordDieFace({
    required this.word,
    required this.size,
    this.brightness = 1,
    super.key,
  });

  final String word;
  final double size;

  /// 0..1 lighting factor from the cube's depth/lighting model; darkens
  /// faces angled away from the "light" so the cube doesn't look flat.
  final double brightness;

  static const _ivory = Color(0xFFFBF6EF);
  static const _ivoryShadow = Color(0xFFDCD2C4);
  static const _textColor = Color(0xFF2A0A2E);

  @override
  Widget build(BuildContext context) {
    final shade = brightness.clamp(0.55, 1.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(_ivory, Colors.white, 0.35 * shade)!,
            Color.lerp(_ivoryShadow, _ivory, shade)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18 * shade),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          word,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            color: _textColor.withValues(alpha: shade),
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}
