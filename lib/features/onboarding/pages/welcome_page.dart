import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/onboarding_controller.dart';
import '../models/onboarding_step.dart';
import '../widgets/onboarding_progress.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    step: OnboardingStep.welcome,
                    onSkip: () {
                      final next = controller.skipFrom(OnboardingStep.welcome);
                      context.go(next.routePath);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '開始設定',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '用幾個步驟建立初始預算、配置與第一筆資產，完成後就能直接看到你的 Dashboard。',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _FlowPreviewCard(),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () {
                      final next = controller.continueFrom(
                        OnboardingStep.welcome,
                      );
                      context.go(next.routePath);
                    },
                    child: const Text('開始設定流程'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '每一步都能先跳過，稍後再回來微調就好。',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
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

class _FlowPreviewCard extends StatelessWidget {
  const _FlowPreviewCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            for (final item in _items) ...[
              Row(
                children: [
                  Icon(item.icon, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.label,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (item != _items.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _FlowItem {
  const _FlowItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

const _items = [
  _FlowItem(Icons.quiz_outlined, '風險屬性問卷'),
  _FlowItem(Icons.pie_chart_outline, '目標配置微調'),
  _FlowItem(Icons.savings_outlined, '預算設定'),
  _FlowItem(Icons.account_balance_wallet_outlined, '加入第一筆資產'),
];
