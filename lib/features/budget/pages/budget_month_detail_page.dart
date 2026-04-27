import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/month_key.dart';
import '../controllers/budget_controller.dart';
import '../models/budget_month.dart';
import '../widgets/budget_category_column.dart';
import '../widgets/budget_summary_panel.dart';
import '../widgets/large_expense_list.dart';
import '../widgets/next_month_planning_panel.dart';

class BudgetMonthDetailPage extends ConsumerWidget {
  const BudgetMonthDetailPage({super.key, this.month, this.monthKey});

  static const routePath = '/budget/month-detail';

  final BudgetMonth? month;
  final MonthKey? monthKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedMonth = month ?? _findByMonth(ref);

    if (resolvedMonth == null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              '找不到對應月份資料，請回到歷史頁重新選擇。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

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
                  if (Navigator.canPop(context)) ...[
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('返回預算歷史'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(
                    '${resolvedMonth.month.zhLabel} 月份詳情',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '回顧這個月的配置節奏，整理下一個月可延續的做法。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  BudgetSummaryPanel(month: resolvedMonth),
                  const SizedBox(height: AppSpacing.md),
                  BudgetCategoryColumn(categories: resolvedMonth.categories),
                  const SizedBox(height: AppSpacing.md),
                  LargeExpenseList(expenses: resolvedMonth.largeExpenses),
                  const SizedBox(height: AppSpacing.md),
                  NextMonthPlanningPanel(month: resolvedMonth),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BudgetMonth? _findByMonth(WidgetRef ref) {
    final selectedMonth = monthKey;
    if (selectedMonth == null) {
      return null;
    }
    return ref.watch(budgetMonthDetailProvider(selectedMonth));
  }
}
