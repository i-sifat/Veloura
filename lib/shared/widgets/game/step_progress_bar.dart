import 'package:flutter/material.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_design_tokens.dart';

/// Decorative session-progress indicator for short guided game flows, e.g.
/// "1 -- 2 -- 3" above the Creative Connections turn chip bar. Purely visual:
/// it does not gate or limit the underlying (random, non-repeating) content
/// queue, it simply gives players a sense of rhythm within a short session.
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    required this.stepCount,
    required this.activeStep,
    super.key,
  }) : assert(
         activeStep >= 1 && activeStep <= stepCount,
         'activeStep must be within 1..stepCount',
       );

  final int stepCount;
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var step = 1; step <= stepCount; step++) ...[
          _StepDot(label: '$step', active: step == activeStep, colors: colors),
          if (step != stepCount)
            Container(
              width: AppDesignTokens.spaceXxl,
              height: 1,
              margin: const EdgeInsets.symmetric(
                horizontal: AppDesignTokens.spaceXs,
              ),
              color: colors.divider,
            ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.label, required this.active, required this.colors});

  final String label;
  final bool active;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Container(
    width: AppDesignTokens.stepDotSize,
    height: AppDesignTokens.stepDotSize,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      // `buttonFill` (not `primary`) so the active-step number clears WCAG
      // AAA against its white label, same reasoning as the primary CTA.
      color: active ? colors.buttonFill : colors.surface,
      border: active ? null : Border.all(color: colors.divider),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: active ? Colors.white : colors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
