import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/money_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/forms/app_text_field.dart';
import '../controllers/onboarding_controller.dart';
import '../models/onboarding_step.dart';
import '../widgets/onboarding_progress.dart';

class BudgetSetupPage extends ConsumerStatefulWidget {
  const BudgetSetupPage({super.key});

  @override
  ConsumerState<BudgetSetupPage> createState() => _BudgetSetupPageState();
}

class _BudgetSetupPageState extends ConsumerState<BudgetSetupPage> {
  late final TextEditingController _incomeController;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(onboardingControllerProvider);
    _incomeController = TextEditingController(
      text: initialState.hasMonthlyIncome
          ? initialState.monthlyIncome.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _incomeController.dispose();
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
                    step: OnboardingStep.budgetSetup,
                    onSkip: () {
                      final next = controller.skipFrom(
                        OnboardingStep.budgetSetup,
                      );
                      context.go(next.routePath);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '預算設定',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '先用簡單模板建立固定、生活、彈性三類預算，後續可再調整。',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: '每月可分配收入',
                    controller: _incomeController,
                    hintText: '例如 60000',
                    helperText: '會先套用 50/30/20 的示意模板',
                    keyboardType: TextInputType.number,
                    onChanged: controller.setMonthlyIncomeFromText,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (!state.hasMonthlyIncome)
                    Text(
                      '尚未輸入時，先用示意模板展示，不會影響後續操作。',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _BudgetPreviewCard(
                    fixed: state.budgetFixed,
                    living: state.budgetLiving,
                    flex: state.budgetFlex,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () {
                      final next = controller.continueFrom(
                        OnboardingStep.budgetSetup,
                      );
                      context.go(next.routePath);
                    },
                    child: const Text('套用這個預算'),
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

class _BudgetPreviewCard extends StatelessWidget {
  const _BudgetPreviewCard({
    required this.fixed,
    required this.living,
    required this.flex,
  });

  final int fixed;
  final int living;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.auto_graph_outlined, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '本月預算模板',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _BudgetRow(label: '固定 50%', amount: fixed),
            const SizedBox(height: AppSpacing.xs),
            _BudgetRow(label: '生活 30%', amount: living),
            const SizedBox(height: AppSpacing.xs),
            _BudgetRow(label: '彈性 20%', amount: flex),
          ],
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          MoneyFormatter.twd(amount),
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
