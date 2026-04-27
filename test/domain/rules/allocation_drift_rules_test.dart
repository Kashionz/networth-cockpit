import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/domain/rules/allocation_drift_rules.dart';

void main() {
  group('evaluateAllocationDriftRules', () {
    test('prompts when drift is above 5% for 7 days', () {
      const inputs = <AllocationDriftInput>[
        AllocationDriftInput(category: '股票', driftRate: 0.06, sustainedDays: 7),
      ];

      final results = evaluateAllocationDriftRules(inputs);

      expect(results, hasLength(1));
      expect(results.first.category, '股票');
      expect(results.first.severity, AllocationDriftSeverity.prompt);
    });

    test('highlights when drift is above 10%', () {
      const inputs = <AllocationDriftInput>[
        AllocationDriftInput(category: '債券', driftRate: 0.11, sustainedDays: 2),
      ];

      final results = evaluateAllocationDriftRules(inputs);

      expect(results, hasLength(1));
      expect(results.first.severity, AllocationDriftSeverity.highlight);
      expect(results.first.shouldHighlight, isTrue);
      expect(results.first.shouldFlagMonthlyReport, isFalse);
    });

    test('flags monthly report chapter when drift is above 15%', () {
      const inputs = <AllocationDriftInput>[
        AllocationDriftInput(category: '現金', driftRate: 0.16, sustainedDays: 1),
      ];

      final results = evaluateAllocationDriftRules(inputs);

      expect(results, hasLength(1));
      expect(results.first.severity, AllocationDriftSeverity.monthlyReportFlag);
      expect(results.first.shouldHighlight, isTrue);
      expect(results.first.shouldFlagMonthlyReport, isTrue);
    });

    test('ignores categories that do not pass rule thresholds', () {
      const inputs = <AllocationDriftInput>[
        AllocationDriftInput(
          category: '黃金',
          driftRate: 0.05,
          sustainedDays: 12,
        ),
        AllocationDriftInput(
          category: '不動產',
          driftRate: 0.08,
          sustainedDays: 6,
        ),
      ];

      final results = evaluateAllocationDriftRules(inputs);

      expect(results, isEmpty);
    });

    test(
      'keeps output at category level without investment-target wording',
      () {
        const inputs = <AllocationDriftInput>[
          AllocationDriftInput(
            category: '股票',
            driftRate: 0.12,
            sustainedDays: 5,
          ),
        ];

        final results = evaluateAllocationDriftRules(inputs);

        expect(results, hasLength(1));
        expect(results.first.title, contains('股票'));
        expect(results.first.reason, contains('類別'));

        const restrictedTerms = <String>['標的', '買進', '賣出', '代號', 'ETF'];
        for (final term in restrictedTerms) {
          expect(results.first.title, isNot(contains(term)));
          expect(results.first.reason, isNot(contains(term)));
        }
      },
    );
  });
}
