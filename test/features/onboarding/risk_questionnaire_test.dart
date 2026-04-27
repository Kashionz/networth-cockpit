import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/features/onboarding/controllers/onboarding_controller.dart';
import 'package:networth_cockpit/features/onboarding/models/risk_answer.dart';
import 'package:networth_cockpit/features/onboarding/pages/target_allocation_page.dart';

void main() {
  void answerAllQuestionsAtScore(OnboardingController controller, int score) {
    for (final question in kRiskQuestions) {
      final choice = question.choices.firstWhere(
        (option) => option.score == score,
      );
      controller.answerRiskQuestion(questionId: question.id, choice: choice);
    }
  }

  final scenarios = <_RiskScenario>[
    const _RiskScenario(
      score: 1,
      expectedLevel: RiskLevel.l1,
      expectedAllocation: AssetAllocation(equity: 20, bond: 50, cash: 30),
    ),
    const _RiskScenario(
      score: 2,
      expectedLevel: RiskLevel.l2,
      expectedAllocation: AssetAllocation(equity: 40, bond: 40, cash: 20),
    ),
    const _RiskScenario(
      score: 3,
      expectedLevel: RiskLevel.l3,
      expectedAllocation: AssetAllocation(equity: 60, bond: 30, cash: 10),
    ),
    const _RiskScenario(
      score: 4,
      expectedLevel: RiskLevel.l4,
      expectedAllocation: AssetAllocation(equity: 75, bond: 20, cash: 5),
    ),
    const _RiskScenario(
      score: 5,
      expectedLevel: RiskLevel.l5,
      expectedAllocation: AssetAllocation(equity: 90, bond: 5, cash: 5),
    ),
  ];

  for (final scenario in scenarios) {
    test('score ${scenario.score} maps to ${scenario.expectedLevel.code}', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(onboardingControllerProvider.notifier);
      answerAllQuestionsAtScore(controller, scenario.score);

      final state = container.read(onboardingControllerProvider);

      expect(state.riskLevel, scenario.expectedLevel);
      expect(state.targetAllocation.equity, scenario.expectedAllocation.equity);
      expect(state.targetAllocation.bond, scenario.expectedAllocation.bond);
      expect(state.targetAllocation.cash, scenario.expectedAllocation.cash);
      expect(state.targetAllocation.total, 100);
    });
  }

  testWidgets('allocation sliders are manually adjustable', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TargetAllocationPage()),
      ),
    );
    await tester.pumpAndSettle();

    final before = container
        .read(onboardingControllerProvider)
        .targetAllocation;
    final equitySlider = find.byKey(const ValueKey('allocation-slider-equity'));

    expect(equitySlider, findsOneWidget);

    await tester.drag(equitySlider, const Offset(-160, 0));
    await tester.pumpAndSettle();

    final after = container.read(onboardingControllerProvider);
    expect(after.allocationManuallyAdjusted, isTrue);
    expect(after.targetAllocation.equity, isNot(equals(before.equity)));
    expect(after.targetAllocation.total, 100);
  });
}

class _RiskScenario {
  const _RiskScenario({
    required this.score,
    required this.expectedLevel,
    required this.expectedAllocation,
  });

  final int score;
  final RiskLevel expectedLevel;
  final AssetAllocation expectedAllocation;
}
