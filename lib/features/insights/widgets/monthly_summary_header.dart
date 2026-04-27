import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/money.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../models/monthly_insight.dart';

class MonthlySummaryHeader extends StatelessWidget {
  const MonthlySummaryHeader({required this.insight, super.key});

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
              '${insight.monthLabel} 月度回顧',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '淨值變化',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            MoneyDisplay(amount: Money.twd(insight.netWorthCurrent), size: 30),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  insight.netWorthIncreased
                      ? Icons.trending_up
                      : Icons.trending_flat,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.xs),
                MoneyDisplay(
                  amount: Money.twd(insight.netWorthDelta),
                  showSign: true,
                  muted: true,
                  size: 14,
                ),
                const SizedBox(width: AppSpacing.xs),
                const Text(
                  '較上月',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              insight.outlook,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
