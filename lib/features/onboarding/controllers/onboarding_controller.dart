import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/onboarding_step.dart';
import '../models/risk_answer.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => OnboardingState.initial();

  OnboardingStep continueFrom(OnboardingStep step) {
    final next = step.next ?? OnboardingStep.completed;
    state = state.copyWith(currentStep: next);
    return next;
  }

  OnboardingStep skipFrom(OnboardingStep step) {
    final next = step.next ?? OnboardingStep.completed;
    final skipped = {...state.skippedSteps, step};
    state = state.copyWith(currentStep: next, skippedSteps: skipped);
    return next;
  }

  void setRiskQuestionIndex(int index) {
    final clamped = index.clamp(0, kRiskQuestions.length - 1);
    state = state.copyWith(activeRiskQuestionIndex: clamped);
  }

  void moveToNextRiskQuestion() {
    if (state.activeRiskQuestionIndex >= kRiskQuestions.length - 1) {
      return;
    }
    setRiskQuestionIndex(state.activeRiskQuestionIndex + 1);
  }

  void moveToPreviousRiskQuestion() {
    if (state.activeRiskQuestionIndex <= 0) {
      return;
    }
    setRiskQuestionIndex(state.activeRiskQuestionIndex - 1);
  }

  void answerRiskQuestion({
    required String questionId,
    required RiskChoice choice,
  }) {
    final nextAnswers = Map<String, RiskAnswer>.from(state.riskAnswers);
    nextAnswers[questionId] = RiskAnswer(
      questionId: questionId,
      choiceId: choice.id,
      score: choice.score,
    );

    final nextLevel = classifyRiskLevelFromAnswers(nextAnswers);
    final nextAllocation = state.allocationManuallyAdjusted
        ? state.targetAllocation
        : AssetAllocation.fromRiskLevel(nextLevel);

    state = state.copyWith(
      riskAnswers: nextAnswers,
      riskLevel: nextLevel,
      targetAllocation: nextAllocation,
    );
  }

  void updateAllocationBucket(AllocationBucket bucket, double value) {
    final nextAllocation = state.targetAllocation.rebalanced(bucket, value);
    state = state.copyWith(
      targetAllocation: nextAllocation,
      allocationManuallyAdjusted: true,
    );
  }

  void resetAllocationToRiskDefault() {
    state = state.copyWith(
      targetAllocation: AssetAllocation.fromRiskLevel(state.riskLevel),
      allocationManuallyAdjusted: false,
    );
  }

  void setMonthlyIncomeFromText(String input) {
    final parsed = int.tryParse(input.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsed == null || parsed <= 0) {
      state = state.copyWith(monthlyIncome: 0);
      return;
    }

    final fixed = (parsed * 0.5).round();
    final living = (parsed * 0.3).round();
    final flex = parsed - fixed - living;

    state = state.copyWith(
      monthlyIncome: parsed,
      budgetFixed: fixed,
      budgetLiving: living,
      budgetFlex: flex,
    );
  }

  void setFirstAssetName(String name) {
    state = state.copyWith(firstAssetName: name.trim());
  }

  void setFirstAssetAmountFromText(String input) {
    final parsed = int.tryParse(input.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    state = state.copyWith(firstAssetAmount: parsed);
  }

  void completeOnboarding() {
    state = state.copyWith(currentStep: OnboardingStep.completed);
  }
}

class OnboardingState {
  OnboardingState({
    required this.currentStep,
    required Map<String, RiskAnswer> riskAnswers,
    required Set<OnboardingStep> skippedSteps,
    required this.activeRiskQuestionIndex,
    required this.riskLevel,
    required this.targetAllocation,
    required this.allocationManuallyAdjusted,
    required this.monthlyIncome,
    required this.budgetFixed,
    required this.budgetLiving,
    required this.budgetFlex,
    required this.firstAssetName,
    required this.firstAssetAmount,
  }) : riskAnswers = UnmodifiableMapView(riskAnswers),
       skippedSteps = UnmodifiableSetView(skippedSteps);

  factory OnboardingState.initial() => OnboardingState(
    currentStep: OnboardingStep.welcome,
    riskAnswers: const {},
    skippedSteps: const {},
    activeRiskQuestionIndex: 0,
    riskLevel: RiskLevel.l3,
    targetAllocation: AssetAllocation.fromRiskLevel(RiskLevel.l3),
    allocationManuallyAdjusted: false,
    monthlyIncome: 0,
    budgetFixed: 30000,
    budgetLiving: 18000,
    budgetFlex: 12000,
    firstAssetName: '',
    firstAssetAmount: 0,
  );

  final OnboardingStep currentStep;
  final Map<String, RiskAnswer> riskAnswers;
  final Set<OnboardingStep> skippedSteps;
  final int activeRiskQuestionIndex;
  final RiskLevel riskLevel;
  final AssetAllocation targetAllocation;
  final bool allocationManuallyAdjusted;
  final int monthlyIncome;
  final int budgetFixed;
  final int budgetLiving;
  final int budgetFlex;
  final String firstAssetName;
  final int firstAssetAmount;

  int get answeredRiskQuestionCount => riskAnswers.length;
  bool get hasMonthlyIncome => monthlyIncome > 0;
  bool get hasFirstAssetDraft =>
      firstAssetName.isNotEmpty || firstAssetAmount > 0;

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    Map<String, RiskAnswer>? riskAnswers,
    Set<OnboardingStep>? skippedSteps,
    int? activeRiskQuestionIndex,
    RiskLevel? riskLevel,
    AssetAllocation? targetAllocation,
    bool? allocationManuallyAdjusted,
    int? monthlyIncome,
    int? budgetFixed,
    int? budgetLiving,
    int? budgetFlex,
    String? firstAssetName,
    int? firstAssetAmount,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      riskAnswers: riskAnswers ?? this.riskAnswers,
      skippedSteps: skippedSteps ?? this.skippedSteps,
      activeRiskQuestionIndex:
          activeRiskQuestionIndex ?? this.activeRiskQuestionIndex,
      riskLevel: riskLevel ?? this.riskLevel,
      targetAllocation: targetAllocation ?? this.targetAllocation,
      allocationManuallyAdjusted:
          allocationManuallyAdjusted ?? this.allocationManuallyAdjusted,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      budgetFixed: budgetFixed ?? this.budgetFixed,
      budgetLiving: budgetLiving ?? this.budgetLiving,
      budgetFlex: budgetFlex ?? this.budgetFlex,
      firstAssetName: firstAssetName ?? this.firstAssetName,
      firstAssetAmount: firstAssetAmount ?? this.firstAssetAmount,
    );
  }
}
