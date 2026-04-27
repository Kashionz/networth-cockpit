import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/budget_controller.dart';
import '../widgets/budget_category_column.dart';
import '../widgets/budget_summary_panel.dart';
import '../widgets/large_expense_list.dart';
import '../widgets/next_month_planning_panel.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(budgetControllerProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageHeader(onHistoryTap: () => _openHistory(context)),
                      const SizedBox(height: AppSpacing.lg),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 920;
                          if (!isWide) {
                            return Column(
                              children: [
                                BudgetSummaryPanel(month: month),
                                const SizedBox(height: AppSpacing.md),
                                BudgetCategoryColumn(
                                  categories: month.categories,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                LargeExpenseList(expenses: month.largeExpenses),
                                const SizedBox(height: AppSpacing.md),
                                NextMonthPlanningPanel(month: month),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: BudgetSummaryPanel(month: month),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    flex: 4,
                                    child: NextMonthPlanningPanel(month: month),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: BudgetCategoryColumn(
                                      categories: month.categories,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: LargeExpenseList(
                                      expenses: month.largeExpenses,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openHistory(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(RoutePaths.budgetHistory);
      return;
    }
    Navigator.of(context).pushNamed(RoutePaths.budgetHistory);
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onHistoryTap});

  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '本月預算',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '先掌握本月節奏，再把觀察轉成下月更順手的分配。',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onHistoryTap,
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: const Text('查看歷史月份'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
        ),
      ],
    );
  }
}
