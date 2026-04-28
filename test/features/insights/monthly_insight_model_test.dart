import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/features/insights/models/monthly_insight.dart';
import 'package:networth_cockpit/shared/models/month_key.dart';

void main() {
  test('monthly insight serializes and restores quant metrics + ai trace', () {
    const insight = MonthlyInsight(
      month: MonthKey(2026, 4),
      netWorthCurrent: 1462000,
      netWorthDelta: 42000,
      savingsRate: 0.284,
      savingsRateTarget: 0.3,
      budgetCompletion: 0.9,
      budgetHighlights: [
        BudgetRecapItem(label: '固定', completion: 0.94, note: '維持原本節奏即可'),
      ],
      allocationChanges: [
        AllocationChangeItem(
          label: '股票',
          previousWeight: 0.58,
          currentWeight: 0.6,
          targetWeight: 0.6,
        ),
      ],
      quantMetrics: QuantMetrics(
        returnRate: 0.032,
        volatility: 0.14,
        sharpeRatio: 1.24,
        maxDrawdown: 0.09,
        benchmarkReturnRate: 0.026,
        benchmarkExcessReturn: 0.006,
        stressTests: [
          StressTestScenario(
            name: '中度衝擊',
            shockRate: 0.15,
            projectedDrawdown: 0.18,
            projectedReturnRate: -0.11,
          ),
        ],
      ),
      aiTrace: AiGovernanceTrace(
        model: 'gpt-5-mini',
        source: 'fastapi_l2',
        status: 'ok',
        contextHash: 'ctx-202604',
      ),
      aiInterpretation: ['本月報酬率 3.20%，基準 2.60%，超額 0.60%。'],
      outlook: '維持既有節奏。',
    );

    final json = insight.toJson();
    final restored = MonthlyInsight.fromJson(json);

    expect(restored.month, const MonthKey(2026, 4));
    expect(restored.quantMetrics.returnRate, closeTo(0.032, 0.000001));
    expect(restored.quantMetrics.sharpeRatio, closeTo(1.24, 0.000001));
    expect(restored.quantMetrics.stressTests.first.name, '中度衝擊');
    expect(restored.aiTrace.model, 'gpt-5-mini');
    expect(restored.aiTrace.source, 'fastapi_l2');
    expect(restored.aiTrace.status, 'ok');
    expect(restored.aiTrace.contextHash, 'ctx-202604');
  });
}
