import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/money.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../models/budget_category.dart';
import '../models/budget_month.dart';

class NextMonthPlanningPanel extends StatelessWidget {
  const NextMonthPlanningPanel({required this.month, super.key});

  final BudgetMonth month;

  @override
  Widget build(BuildContext context) {
    final plans = month.categories.map(_buildPlan).toList(growable: false);
    final suggestedTotal = Money.twd(
      plans.fold<num>(0, (total, item) => total + item.recommended.amount),
    );
    final rolloverPool = Money.twd(
      month.categories
          .where(
            (category) => category.rollover && category.remainingAmount > 0,
          )
          .fold<num>(0, (total, category) => total + category.remainingAmount),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '下月預算規劃',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '把本月觀察轉成下月分配方向，先調整比例再看細項。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < plans.length; index++) ...[
              _PlanningRow(plan: plans[index]),
              if (index != plans.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
            const Divider(height: AppSpacing.lg),
            _PlanningMetric(label: '建議可分配總額', amount: suggestedTotal),
            const SizedBox(height: AppSpacing.sm),
            _PlanningMetric(label: '可滾入下月緩衝', amount: rolloverPool),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '月底前可先確認固定支出，再依生活與彈性區塊做小幅微調。',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  _CategoryPlan _buildPlan(BudgetCategory category) {
    final multiplier = switch (category.type) {
      BudgetCategoryType.fixed => 1.0,
      _ =>
        category.usageRate >= 0.95
            ? 1.05
            : category.usageRate <= 0.7
            ? 0.95
            : 1.0,
    };
    final recommendedAmount = Money.twd(
      (category.budgetAmount.amount * multiplier).round(),
    );

    final direction = switch (multiplier) {
      > 1.0 => '微調 +5%',
      < 1.0 => '微調 -5%',
      _ => '維持',
    };

    final hint = switch (category.type) {
      BudgetCategoryType.fixed => '固定項先保留穩定支出',
      BudgetCategoryType.living => '生活項依本月節奏校正',
      BudgetCategoryType.flex =>
        category.rollover ? '彈性項搭配 rollover 形成緩衝' : '彈性項保留可調空間',
    };

    return _CategoryPlan(
      name: category.name,
      recommended: recommendedAmount,
      direction: direction,
      hint: hint,
    );
  }
}

class _PlanningRow extends StatelessWidget {
  const _PlanningRow({required this.plan});

  final _CategoryPlan plan;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        plan.direction,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    plan.hint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            MoneyDisplay(
              amount: plan.recommended,
              size: 16,
              weight: FontWeight.w700,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanningMetric extends StatelessWidget {
  const _PlanningMetric({required this.label, required this.amount});

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        MoneyDisplay(amount: amount, size: 16, weight: FontWeight.w700),
      ],
    );
  }
}

class _CategoryPlan {
  const _CategoryPlan({
    required this.name,
    required this.recommended,
    required this.direction,
    required this.hint,
  });

  final String name;
  final Money recommended;
  final String direction;
  final String hint;
}
