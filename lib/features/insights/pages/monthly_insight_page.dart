import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/feedback/disclaimer_banner.dart';
import '../controllers/insights_controller.dart';
import '../widgets/ai_interpretation_panel.dart';
import '../widgets/allocation_change_recap.dart';
import '../widgets/budget_recap.dart';
import '../widgets/monthly_summary_header.dart';
import '../widgets/savings_rate_recap.dart';

class MonthlyInsightPage extends ConsumerWidget {
  const MonthlyInsightPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightState = ref.watch(insightsControllerProvider);
    final insight = insightState.displayInsight;

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
                  const SizedBox(height: AppSpacing.lg),
                  MonthlySummaryHeader(insight: insight),
                  const SizedBox(height: AppSpacing.md),
                  _InsightGrid(
                    savingsRecap: SavingsRateRecap(insight: insight),
                    budgetRecap: BudgetRecap(insight: insight),
                    allocationRecap: AllocationChangeRecap(
                      items: insight.allocationChanges,
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

class _InsightGrid extends StatelessWidget {
  const _InsightGrid({
    required this.savingsRecap,
    required this.budgetRecap,
    required this.allocationRecap,
    required this.aiPanel,
  });

  final Widget savingsRecap;
  final Widget budgetRecap;
  final Widget allocationRecap;
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
                Expanded(child: aiPanel),
              ],
            ),
          ],
        );
      },
    );
  }
}
