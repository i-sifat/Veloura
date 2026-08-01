import 'package:flutter/material.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_design_tokens.dart';

/// Decorative session-progress indicator for guided game flows.
///
/// Renders one labeled dot per step ("1 -- 2 -- 3") when [stepCount] is
/// small enough to fit comfortably on screen. Longer sessions (e.g. a
/// 20-question Creative Connections round) switch to a compact linear bar
/// with a "Question X of N" label instead of rendering every step as its
/// own dot, which would overflow narrow phones. Purely visual either way:
/// it does not gate or limit the underlying content queue.
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

  /// Above this many steps, individual dots stop fitting comfortably and
  /// this widget switches to the compact linear-bar presentation.
  static const _maxDots = 6;

  @override
  Widget build(BuildContext context) => stepCount <= _maxDots
      ? _DotRow(stepCount: stepCount, activeStep: activeStep)
      : _CompactBar(stepCount: stepCount, activeStep: activeStep);
}

class _DotRow extends StatelessWidget {
  const _DotRow({required this.stepCount, required this.activeStep});

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

class _CompactBar extends StatelessWidget {
  const _CompactBar({required this.stepCount, required this.activeStep});

  final int stepCount;
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: activeStep / stepCount,
            minHeight: 6,
            backgroundColor: colors.divider,
            // `buttonFill` (not `primary`) for the same AAA-contrast reasons
            // documented on the dot mode below.
            valueColor: AlwaysStoppedAnimation<Color>(colors.buttonFill),
          ),
        ),
        const SizedBox(height: AppDesignTokens.spaceXs),
        Text(
          'Question $activeStep of $stepCount',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
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
