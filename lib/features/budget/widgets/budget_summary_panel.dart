import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../../../shared/widgets/data_display/progress_bar.dart';
import '../models/budget_month.dart';

class BudgetSummaryPanel extends StatelessWidget {
  const BudgetSummaryPanel({required this.month, super.key});

  final BudgetMonth month;

  @override
  Widget build(BuildContext context) {
    final usageTone = _toneFor(month.totalUsageRate);
    final usageColor = switch (usageTone) {
      ProgressTone.calm => AppColors.textSecondary,
      ProgressTone.near => AppColors.near,
      ProgressTone.review => AppColors.review,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '本月總覽',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                Text(
                  month.month.zhLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ProgressBar(
              value: month.totalUsed.amount.toDouble(),
              max: month.totalBudget.amount.toDouble(),
              tone: usageTone,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(
                  '已分配 ${month.totalUsagePercent}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: usageColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _summaryCopy(month.totalUsageRate),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 620;
                final items = [
                  _SummaryMetric(label: '總預算', amount: month.totalBudget),
                  _SummaryMetric(label: '已使用', amount: month.totalUsed),
                  _SummaryMetric(label: '可調整空間', amount: month.totalRemaining),
                ];

                if (isCompact) {
                  return Column(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        items[index],
                        if (index != items.length - 1)
                          const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      Expanded(child: items[index]),
                      if (index != items.length - 1)
                        const SizedBox(width: AppSpacing.md),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  ProgressTone _toneFor(double usageRate) {
    if (usageRate >= 0.95) {
      return ProgressTone.review;
    }
    if (usageRate >= 0.8) {
      return ProgressTone.near;
    }
    return ProgressTone.calm;
  }

  String _summaryCopy(double usageRate) {
    if (usageRate >= 0.95) {
      return '本月分配接近上限，先保留必要支出，並整理下月優先順序。';
    }
    if (usageRate >= 0.8) {
      return '本月執行節奏接近規劃，月底前可逐步收斂非必要花費。';
    }
    return '本月仍保有彈性空間，可提早設計下月想加強的項目。';
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.amount});

  final String label;
  final Object amount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            MoneyDisplay(amount: amount, size: 18, weight: FontWeight.w700),
          ],
        ),
      ),
    );
  }
}
