import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/progress_bar.dart';
import '../models/monthly_insight.dart';

class BudgetRecap extends StatelessWidget {
  const BudgetRecap({required this.insight, super.key});

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
              '預算達成',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              insight.budgetCompletionLabel,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '大多數項目與原定分配接近，下月可沿用同樣結構。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in insight.budgetHighlights) ...[
              _BudgetItemRow(item: item),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetItemRow extends StatelessWidget {
  const _BudgetItemRow({required this.item});

  final BudgetRecapItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(width: 42, child: Text(item.label)),
            Expanded(
              child: ProgressBar(
                value: item.completion,
                max: 1,
                tone: item.completion >= 0.95
                    ? ProgressTone.calm
                    : item.completion >= 0.85
                    ? ProgressTone.near
                    : ProgressTone.review,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              item.completionLabel,
              style: const TextStyle(color: AppColors.textTertiary),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Text(
            item.note,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}
