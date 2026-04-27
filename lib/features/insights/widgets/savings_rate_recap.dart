import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/progress_bar.dart';
import '../models/monthly_insight.dart';

class SavingsRateRecap extends StatelessWidget {
  const SavingsRateRecap({required this.insight, super.key});

  final MonthlyInsight insight;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '儲蓄率回顧',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              insight.savingsRateLabel,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '目標 ${insight.savingsTargetLabel}，保持穩定即可逐步靠近。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.md),
            ProgressBar(
              value: insight.savingsRate,
              max: 1,
              target: insight.savingsRateTarget,
              tone: insight.savingsRate >= insight.savingsRateTarget
                  ? ProgressTone.calm
                  : ProgressTone.near,
            ),
          ],
        ),
      ),
    );
  }
}
