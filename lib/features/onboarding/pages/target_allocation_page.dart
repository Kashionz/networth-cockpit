import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/onboarding_controller.dart';
import '../models/onboarding_step.dart';
import '../models/risk_answer.dart';
import '../widgets/allocation_slider_group.dart';
import '../widgets/onboarding_progress.dart';

class TargetAllocationPage extends ConsumerWidget {
  const TargetAllocationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingProgress(
                    step: OnboardingStep.targetAllocation,
                    onSkip: () {
                      final next = controller.skipFrom(
                        OnboardingStep.targetAllocation,
                      );
                      context.go(next.routePath);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '目標配置',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '設定股、債、現金的目標比例。這是起點，後續可再慢慢調整。',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RiskMappingBanner(
                    riskCode: state.riskLevel.code,
                    riskLabel: state.riskLevel.label,
                    answeredCount: state.answeredRiskQuestionCount,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (state.answeredRiskQuestionCount == 0) ...[
                    Text(
                      '尚未填問卷時，會先用 L3 平衡配置作為起點。',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AllocationSliderGroup(
                    allocation: state.targetAllocation,
                    onChanged: controller.updateAllocationBucket,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '總和 ${state.targetAllocation.total}%',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.allocationManuallyAdjusted)
                    TextButton(
                      onPressed: controller.resetAllocationToRiskDefault,
                      child: Text('回到 ${state.riskLevel.code} 建議配置'),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () {
                      final next = controller.continueFrom(
                        OnboardingStep.targetAllocation,
                      );
                      context.go(next.routePath);
                    },
                    child: const Text('使用這個配置'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskMappingBanner extends StatelessWidget {
  const _RiskMappingBanner({
    required this.riskCode,
    required this.riskLabel,
    required this.answeredCount,
  });

  final String riskCode;
  final String riskLabel;
  final int answeredCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.tune, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '目前建議: $riskCode $riskLabel',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '已答 $answeredCount 題',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
