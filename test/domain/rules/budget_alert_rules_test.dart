import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/domain/rules/budget_alert_rules.dart';

void main() {
  group('evaluateBudgetAlert', () {
    test('does not proactively notify below 80%', () {
      const input = BudgetAlertInput(
        totalBudgetAmount: 10000,
        usedAmount: 7900,
        daysLeftInMonth: 12,
      );

      final result = evaluateBudgetAlert(input);

      expect(result.type, BudgetAlertType.none);
      expect(result.shouldNotify, isFalse);
      expect(result.title, isNull);
      expect(result.reason, isNull);
    });

    test('shows remaining amount and days left between 80% and 99%', () {
      const input = BudgetAlertInput(
        totalBudgetAmount: 10000,
        usedAmount: 8500,
        daysLeftInMonth: 6,
      );

      final result = evaluateBudgetAlert(input);

      expect(result.type, BudgetAlertType.nearingLimit);
      expect(result.shouldNotify, isTrue);
      expect(result.reason, isNotNull);
      expect(result.reason, contains('還剩 1500 元'));
      expect(result.reason, contains('6 天'));
    });

    test('uses neutral wording when usage is at or above 100%', () {
      const input = BudgetAlertInput(
        totalBudgetAmount: 10000,
        usedAmount: 10000,
        daysLeftInMonth: 8,
      );

      final result = evaluateBudgetAlert(input);

      expect(result.type, BudgetAlertType.overBudget);
      expect(result.shouldNotify, isTrue);
      expect(result.reason, isNotNull);
      expect(result.reason, contains('可先安排'));
      expect(result.reason, isNot(contains('警告')));
      expect(result.reason, isNot(contains('危險')));
      expect(result.reason, isNot(contains('錯誤')));
    });

    test('shows month-end adjustment prompt when usage is above 120%', () {
      const input = BudgetAlertInput(
        totalBudgetAmount: 10000,
        usedAmount: 12500,
        daysLeftInMonth: 1,
        isMonthEnd: true,
      );

      final result = evaluateBudgetAlert(input);

      expect(result.type, BudgetAlertType.monthEndAllocationAdjustment);
      expect(result.shouldNotify, isTrue);
      expect(result.reason, contains('月底'));
      expect(result.reason, contains('下月分配'));
    });

    test('keeps over-budget wording before month-end even above 120%', () {
      const input = BudgetAlertInput(
        totalBudgetAmount: 10000,
        usedAmount: 12500,
        daysLeftInMonth: 4,
      );

      final result = evaluateBudgetAlert(input);

      expect(result.type, BudgetAlertType.overBudget);
      expect(result.reason, contains('預算上限以上'));
    });
  });
}
