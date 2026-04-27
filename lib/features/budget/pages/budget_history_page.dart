import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../../../shared/widgets/data_display/progress_bar.dart';
import '../controllers/budget_controller.dart';
import '../models/budget_month.dart';
import 'budget_month_detail_page.dart';

class BudgetHistoryPage extends ConsumerWidget {
  const BudgetHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyMonths = ref.watch(budgetHistoryControllerProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '預算歷史',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '從近期月度回顧提取可延續做法，讓下月分配更穩定。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (
                    var index = 0;
                    index < historyMonths.length;
                    index++
                  ) ...[
                    _HistoryMonthCard(
                      month: historyMonths[index],
                      onOpenDetail: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BudgetMonthDetailPage(
                              month: historyMonths[index],
                            ),
                          ),
                        );
                      },
                    ),
                    if (index != historyMonths.length - 1)
                      const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMonthCard extends StatelessWidget {
  const _HistoryMonthCard({required this.month, required this.onOpenDetail});

  final BudgetMonth month;
  final VoidCallback onOpenDetail;

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
                  month.month.zhLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                Text(
                  '${month.totalUsagePercent}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: usageColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ProgressBar(
              value: month.totalUsed.amount.toDouble(),
              max: month.totalBudget.amount.toDouble(),
              tone: usageTone,
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 560;
                final metrics = [
                  _HistoryMetric(label: '總預算', amount: month.totalBudget),
                  _HistoryMetric(label: '已使用', amount: month.totalUsed),
                  _HistoryMetric(label: '剩餘空間', amount: month.totalRemaining),
                ];

                if (isCompact) {
                  return Column(
                    children: [
                      for (var index = 0; index < metrics.length; index++) ...[
                        metrics[index],
                        if (index != metrics.length - 1)
                          const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var index = 0; index < metrics.length; index++) ...[
                      Expanded(child: metrics[index]),
                      if (index != metrics.length - 1)
                        const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _historyHint(month.totalUsageRate),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: onOpenDetail,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('查看月份詳情'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              ),
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

  String _historyHint(double usageRate) {
    if (usageRate >= 0.95) {
      return '接近分配上限，下一個月可優先準備緩衝金額。';
    }
    if (usageRate >= 0.8) {
      return '節奏接近原規劃，下月可先保留必要支出再微調。';
    }
    return '仍有餘裕，下月可把多出的空間提前放進重點目標。';
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({required this.label, required this.amount});

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
            MoneyDisplay(amount: amount, size: 16, weight: FontWeight.w700),
          ],
        ),
      ),
    );
  }
}
