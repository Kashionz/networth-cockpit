import '../../../core/routing/route_paths.dart';

enum OnboardingStep {
  welcome,
  riskQuestionnaire,
  targetAllocation,
  budgetSetup,
  firstAsset,
  completed,
}

extension OnboardingStepX on OnboardingStep {
  static const int _totalInteractiveSteps = 5;

  int get order {
    return switch (this) {
      OnboardingStep.welcome => 1,
      OnboardingStep.riskQuestionnaire => 2,
      OnboardingStep.targetAllocation => 3,
      OnboardingStep.budgetSetup => 4,
      OnboardingStep.firstAsset => 5,
      OnboardingStep.completed => _totalInteractiveSteps,
    };
  }

  int get totalSteps => _totalInteractiveSteps;

  bool get isCompleted => this == OnboardingStep.completed;

  OnboardingStep? get next {
    return switch (this) {
      OnboardingStep.welcome => OnboardingStep.riskQuestionnaire,
      OnboardingStep.riskQuestionnaire => OnboardingStep.targetAllocation,
      OnboardingStep.targetAllocation => OnboardingStep.budgetSetup,
      OnboardingStep.budgetSetup => OnboardingStep.firstAsset,
      OnboardingStep.firstAsset => OnboardingStep.completed,
      OnboardingStep.completed => null,
    };
  }

  String get routePath {
    return switch (this) {
      OnboardingStep.welcome => RoutePaths.onboardingWelcome,
      OnboardingStep.riskQuestionnaire =>
        RoutePaths.onboardingRiskQuestionnaire,
      OnboardingStep.targetAllocation => RoutePaths.onboardingTargetAllocation,
      OnboardingStep.budgetSetup => RoutePaths.onboardingBudgetSetup,
      OnboardingStep.firstAsset => RoutePaths.onboardingFirstAsset,
      OnboardingStep.completed => RoutePaths.dashboard,
    };
  }
}
