import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/forms/app_text_field.dart';
import '../controllers/onboarding_controller.dart';
import '../models/onboarding_step.dart';
import '../widgets/onboarding_progress.dart';

class FirstAssetPage extends ConsumerStatefulWidget {
  const FirstAssetPage({super.key});

  @override
  ConsumerState<FirstAssetPage> createState() => _FirstAssetPageState();
}

class _FirstAssetPageState extends ConsumerState<FirstAssetPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingControllerProvider);
    _nameController = TextEditingController(text: state.firstAssetName);
    _amountController = TextEditingController(
      text: state.firstAssetAmount > 0 ? state.firstAssetAmount.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    step: OnboardingStep.firstAsset,
                    onSkip: () {
                      final next = controller.skipFrom(
                        OnboardingStep.firstAsset,
                      );
                      context.go(next.routePath);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '第一筆資產',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '先記錄一筆最熟悉的資產就可以，之後再慢慢補齊也沒關係。',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: '資產名稱',
                    controller: _nameController,
                    hintText: '例如 台股 ETF',
                    onChanged: controller.setFirstAssetName,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: '目前估值',
                    controller: _amountController,
                    hintText: '例如 120000',
                    keyboardType: TextInputType.number,
                    onChanged: controller.setFirstAssetAmountFromText,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (!state.hasFirstAssetDraft) const _GentleEmptyState(),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () {
                      final next = controller.continueFrom(
                        OnboardingStep.firstAsset,
                      );
                      context.go(next.routePath);
                    },
                    child: const Text('完成設定'),
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

class _GentleEmptyState extends StatelessWidget {
  const _GentleEmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '先從一筆熟悉的資產開始就很好，之後會越來越完整。',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
