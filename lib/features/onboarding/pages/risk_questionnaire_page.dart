import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/onboarding_controller.dart';
import '../models/onboarding_step.dart';
import '../models/risk_answer.dart';
import '../widgets/onboarding_progress.dart';
import '../widgets/risk_question_card.dart';

class RiskQuestionnairePage extends ConsumerWidget {
  const RiskQuestionnairePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final question = kRiskQuestions[state.activeRiskQuestionIndex];
    final selectedAnswer = state.riskAnswers[question.id];
    final isLastQuestion =
        state.activeRiskQuestionIndex == kRiskQuestions.length - 1;
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
                    step: OnboardingStep.riskQuestionnaire,
                    onSkip: () {
                      final next = controller.skipFrom(
                        OnboardingStep.riskQuestionnaire,
                      );
                      context.go(next.routePath);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '風險屬性問卷',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '用中性問題協助產生 L1-L5 的配置起點，之後也能隨時調整。',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RiskResultBanner(
                    level: state.riskLevel,
                    answeredCount: state.answeredRiskQuestionCount,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (state.answeredRiskQuestionCount == 0) ...[
                    Text(
                      '可以先用預設配置，稍後再補填問卷也可以。',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  RiskQuestionCard(
                    question: question,
                    questionNumber: state.activeRiskQuestionIndex + 1,
                    totalQuestions: kRiskQuestions.length,
                    selectedChoiceId: selectedAnswer?.choiceId,
                    onChoiceSelected: (choice) {
                      controller.answerRiskQuestion(
                        questionId: question.id,
                        choice: choice,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: state.activeRiskQuestionIndex == 0
                            ? null
                            : controller.moveToPreviousRiskQuestion,
                        child: const Text('上一題'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (!isLastQuestion) {
                              controller.moveToNextRiskQuestion();
                              return;
                            }
                            final next = controller.continueFrom(
                              OnboardingStep.riskQuestionnaire,
                            );
                            context.go(next.routePath);
                          },
                          child: Text(isLastQuestion ? '完成問卷' : '下一題'),
                        ),
                      ),
                    ],
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

class _RiskResultBanner extends StatelessWidget {
  const _RiskResultBanner({required this.level, required this.answeredCount});

  final RiskLevel level;
  final int answeredCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.insights_outlined, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '目前結果: ${level.code} ${level.label}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$answeredCount/${kRiskQuestions.length}',
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
