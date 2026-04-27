import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/onboarding_step.dart';

class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    required this.step,
    required this.onSkip,
    super.key,
  });

  final OnboardingStep step;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = step.order / step.totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '步驟 ${step.order}/${step.totalSteps}',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(onPressed: onSkip, child: const Text('跳過此步')),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.surfaceSoft,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}
