import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../models/budget_category.dart';
import '../models/budget_month.dart';

class LargeExpenseList extends StatelessWidget {
  const LargeExpenseList({required this.expenses, super.key});

  final List<LargeExpense> expenses;

  @override
  Widget build(BuildContext context) {
    final notableExpenses = expenses
        .where((expense) => expense.amount.amount >= 5000)
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本月大額支出',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '顯示單筆 5,000 以上紀錄，協助下月配置更完整。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.md),
            if (notableExpenses.isEmpty)
              Text(
                '本月尚無大額支出，月底可用這個區塊回顧是否需要調整緩衝預算。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (var index = 0; index < notableExpenses.length; index++) ...[
                _LargeExpenseRow(expense: notableExpenses[index]),
                if (index != notableExpenses.length - 1)
                  const Divider(height: AppSpacing.lg),
              ],
          ],
        ),
      ),
    );
  }
}

class _LargeExpenseRow extends StatelessWidget {
  const _LargeExpenseRow({required this.expense});

  final LargeExpense expense;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('M/d').format(expense.recordedAt);
    final typeLabel = switch (expense.categoryType) {
      BudgetCategoryType.fixed => '固定',
      BudgetCategoryType.living => '生活',
      BudgetCategoryType.flex => '彈性',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  _CategoryPill(label: typeLabel, type: expense.categoryType),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        MoneyDisplay(amount: expense.amount, size: 16, weight: FontWeight.w700),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.type});

  final String label;
  final BudgetCategoryType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      BudgetCategoryType.fixed => AppColors.budgetFixed,
      BudgetCategoryType.living => AppColors.budgetLiving,
      BudgetCategoryType.flex => AppColors.budgetFlex,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
