import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/rules/health_rule_projection.dart';
import '../../../shared/models/month_key.dart';
import '../../../shared/widgets/feedback/disclaimer_banner.dart';
import '../controllers/insights_controller.dart';
import '../widgets/ai_interpretation_panel.dart';
import '../widgets/allocation_change_recap.dart';
import '../widgets/budget_recap.dart';
import '../widgets/monthly_summary_header.dart';
import '../widgets/quant_metrics_panel.dart';
import '../widgets/savings_rate_recap.dart';

class MonthlyInsightPage extends ConsumerWidget {
  const MonthlyInsightPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightState = ref.watch(insightsControllerProvider);
    final selectedReport = insightState.selectedReport;
    final insight = selectedReport.insight;
    final l1Conclusion = HealthRuleProjection.evaluateMonthlyInsight(insight);

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
                    '月度報告',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '整理本月指標與配置變化，協助規劃下一步。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _MonthSelector(
                    months: insightState.availableMonths,
                    selectedMonth: insightState.selectedMonth,
                    onChanged: (month) {
                      ref
                          .read(insightsControllerProvider.notifier)
                          .selectMonth(month);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _L1ConclusionCard(
                    title: l1Conclusion.title,
                    reason: l1Conclusion.reason,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MonthlySummaryHeader(insight: insight),
                  const SizedBox(height: AppSpacing.md),
                  _InsightGrid(
                    savingsRecap: SavingsRateRecap(insight: insight),
                    budgetRecap: BudgetRecap(insight: insight),
                    allocationRecap: AllocationChangeRecap(
                      items: insight.allocationChanges,
                    ),
                    quantRecap: QuantMetricsPanel(
                      metrics: insight.quantMetrics,
                    ),
                    aiPanel: AiInterpretationPanel(
                      lines: insight.aiInterpretation,
                      sourceLabel: insightState.sourceLabel,
                      statusMessage: insightState.usedFallback
                          ? insightState.statusMessage
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const DisclaimerBanner(text: '本資訊僅供參考,不構成投資建議'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _L1ConclusionCard extends StatelessWidget {
  const _L1ConclusionCard({required this.title, required this.reason});

  final String title;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'L1 健康提示',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              reason,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.months,
    required this.selectedMonth,
    required this.onChanged,
  });

  final List<MonthKey> months;
  final MonthKey selectedMonth;
  final ValueChanged<MonthKey> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: DropdownButtonFormField<MonthKey>(
          key: const Key('insights-month-selector'),
          initialValue: selectedMonth,
          decoration: const InputDecoration(
            labelText: '查看月份',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            for (final month in months)
              DropdownMenuItem<MonthKey>(
                value: month,
                child: Text(month.zhLabel),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

class _InsightGrid extends StatelessWidget {
  const _InsightGrid({
    required this.savingsRecap,
    required this.budgetRecap,
    required this.allocationRecap,
    required this.quantRecap,
    required this.aiPanel,
  });

  final Widget savingsRecap;
  final Widget budgetRecap;
  final Widget allocationRecap;
  final Widget quantRecap;
  final Widget aiPanel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 860;
        if (!isWide) {
          return Column(
            children: [
              savingsRecap,
              const SizedBox(height: AppSpacing.md),
              budgetRecap,
              const SizedBox(height: AppSpacing.md),
              allocationRecap,
              const SizedBox(height: AppSpacing.md),
              quantRecap,
              const SizedBox(height: AppSpacing.md),
              aiPanel,
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: savingsRecap),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: budgetRecap),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: allocationRecap),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: quantRecap),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: aiPanel),
                const SizedBox(width: AppSpacing.md),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
        );
      },
    );
  }
}
