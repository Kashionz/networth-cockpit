import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/domain/rules/health_rule_engine.dart';

void main() {
  const baseInput = HealthRuleInput(
    cardPaymentDueAmount: 10000,
    availableCashAmount: 20000,
    emergencyFundMonths: 6,
    savingsRate: 0.2,
    allocationDriftRate: 0.03,
  );

  const restrictedTerms = <String>['警告', '危險', '錯誤'];

  group('HealthRuleEngine', () {
    test('evaluates in order and first match wins', () {
      final engine = HealthRuleEngine();
      final result = engine.evaluate(
        const HealthRuleInput(
          cardPaymentDueAmount: 25000,
          availableCashAmount: 10000,
          emergencyFundMonths: 1,
          savingsRate: 0.05,
          allocationDriftRate: 0.2,
        ),
      );

      expect(result.type, HealthRuleType.cardPaymentDueOverCash);
    });

    test('returns emergency fund rule when months are below 3', () {
      final engine = HealthRuleEngine();
      final result = engine.evaluate(
        baseInput.copyWith(emergencyFundMonths: 2.5),
      );

      expect(result.type, HealthRuleType.emergencyFundMonthsLow);
    });

    test('returns savings rate rule when rate is below 10%', () {
      final engine = HealthRuleEngine();
      final result = engine.evaluate(baseInput.copyWith(savingsRate: 0.09));

      expect(result.type, HealthRuleType.savingsRateLow);
    });

    test('returns allocation drift rule when drift is above 10%', () {
      final engine = HealthRuleEngine();
      final result = engine.evaluate(
        baseInput.copyWith(allocationDriftRate: 0.11),
      );

      expect(result.type, HealthRuleType.allocationDriftHigh);
    });

    test('returns healthy fallback when all indicators are in range', () {
      final engine = HealthRuleEngine();
      final result = engine.evaluate(baseInput);

      expect(result.type, HealthRuleType.healthy);
    });

    test('each output has neutral title and reason', () {
      final engine = HealthRuleEngine();
      final outputs = <HealthRuleResult>[
        engine.evaluate(
          baseInput.copyWith(
            cardPaymentDueAmount: 25000,
            availableCashAmount: 10000,
          ),
        ),
        engine.evaluate(baseInput.copyWith(emergencyFundMonths: 2.5)),
        engine.evaluate(baseInput.copyWith(savingsRate: 0.09)),
        engine.evaluate(baseInput.copyWith(allocationDriftRate: 0.11)),
        engine.evaluate(baseInput),
      ];

      for (final output in outputs) {
        expect(output.title.trim(), isNotEmpty);
        expect(output.reason.trim(), isNotEmpty);
        for (final term in restrictedTerms) {
          expect(output.title, isNot(contains(term)));
          expect(output.reason, isNot(contains(term)));
        }
      }
    });
  });
}
