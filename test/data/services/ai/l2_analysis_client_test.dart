import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:networth_cockpit/data/services/ai/l2_analysis_client.dart';
import 'package:networth_cockpit/features/insights/models/monthly_insight.dart';
import 'package:networth_cockpit/shared/models/month_key.dart';

void main() {
  test(
    'analyzeMonthly sends quant + trace fields and parses backend quant response',
    () async {
      String? capturedBody;

      final client = L2AnalysisClient(
        baseUrl: 'https://example.com',
        httpClient: MockClient((request) async {
          capturedBody = request.body;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'recommendations': ['減少外食支出', '提高固定儲蓄額'],
                'llm_insight': '本月現金流與預算執行維持穩定。',
                'quant_metrics': {
                  'return_rate': 0.035,
                  'annualized_volatility': 0.14,
                  'sharpe': 1.42,
                  'max_drawdown': 0.085,
                  'benchmark_return_rate': 0.028,
                  'benchmark_excess_return': 0.007,
                  'stress_tests': [
                    {
                      'name': '中度衝擊',
                      'shock_rate': 0.15,
                      'projected_drawdown': 0.18,
                      'projected_return_rate': -0.12,
                    },
                  ],
                },
                'trace': {
                  'model': 'gpt-5-mini',
                  'source': 'fastapi_l2',
                  'status': 'ok',
                  'contextHash': 'ctx-202604',
                },
              }),
            ),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final result = await client.analyzeMonthly(
        seedInsight: _seedInsight,
        monthlyIncome: 88000,
        priceHistory: const [
          {'date': '2026-04-01', 'close': 1420000},
          {'date': '2026-04-08', 'close': 1435000},
          {'date': '2026-04-15', 'close': 1450000},
        ],
        benchmarkHistory: const [
          {'date': '2026-04-01', 'close': 1390000},
          {'date': '2026-04-08', 'close': 1402000},
          {'date': '2026-04-15', 'close': 1414000},
        ],
      );

      expect(result.usedFallback, isFalse);
      expect(result.source, L2ResultSource.backend);
      expect(result.insight.aiInterpretation.first, contains('本月報酬率'));
      expect(result.insight.outlook, '減少外食支出');
      expect(result.insight.quantMetrics.returnRate, closeTo(0.035, 0.000001));
      expect(result.insight.quantMetrics.volatility, closeTo(0.14, 0.000001));
      expect(result.insight.quantMetrics.sharpeRatio, closeTo(1.42, 0.000001));
      expect(
        result.insight.quantMetrics.stressTests.first.projectedDrawdown,
        closeTo(0.18, 0.000001),
      );
      expect(result.insight.aiTrace.model, 'gpt-5-mini');
      expect(result.insight.aiTrace.source, 'fastapi_l2');
      expect(result.insight.aiTrace.status, 'ok');
      expect(result.insight.aiTrace.contextHash, 'ctx-202604');

      final capturedPayload = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(capturedPayload['month'], '2026-04');
      expect(capturedPayload['income'], 88000);
      expect(capturedPayload['expense'], isA<num>());
      expect(capturedPayload['price_history'], isA<List>());
      expect((capturedPayload['price_history'] as List), hasLength(3));
      expect(capturedPayload['benchmark_history'], isA<List>());
      expect(capturedPayload['top_categories'], isA<List>());
      expect(capturedPayload['quant_metrics'], isA<Map>());
      expect(capturedPayload['trace'], isA<Map>());
      expect(capturedPayload['notes'], isA<String>());
    },
  );

  test(
    'analyzeMonthly fallback keeps flow and emits governance trace',
    () async {
      final client = L2AnalysisClient(
        baseUrl: null,
        httpClient: MockClient((_) async => http.Response('{}', 500)),
      );

      final result = await client.analyzeMonthly(seedInsight: _seedInsight);

      expect(result.usedFallback, isTrue);
      expect(result.reason, contains('FASTAPI_BASE_URL'));
      expect(result.insight.aiInterpretation.first, contains('本月報酬率'));
      expect(result.insight.aiTrace.model, 'local-deterministic');
      expect(result.insight.aiTrace.source, 'l2_fallback');
      expect(result.insight.aiTrace.status, 'fallback');
      expect(result.insight.aiTrace.contextHash, isNot('unknown'));
    },
  );

  test(
    'analyzeMonthly maps top-level quant fields into insight metrics',
    () async {
      final client = L2AnalysisClient(
        baseUrl: 'https://example.com',
        httpClient: MockClient((_) async {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'outlook': '可維持既有節奏並持續觀察。',
                'sharpe_ratio': 1.18,
                'annualized_volatility': 0.19,
                'max_drawdown_pct': -12.4,
                'benchmark_diff_pct': 2.6,
                'stress_test_result': {
                  'market_down_20pct': {
                    'ok': true,
                    'shock_pct': -20.0,
                    'stressed_max_drawdown_pct': -28.0,
                    'stressed_annualized_return_pct': -15.0,
                  },
                },
              }),
            ),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final result = await client.analyzeMonthly(seedInsight: _seedInsight);

      expect(result.usedFallback, isFalse);
      expect(result.insight.quantMetrics.sharpeRatio, closeTo(1.18, 0.000001));
      expect(result.insight.quantMetrics.volatility, closeTo(0.19, 0.000001));
      expect(
        result.insight.quantMetrics.maxDrawdown,
        closeTo(-0.124, 0.000001),
      );
      expect(
        result.insight.quantMetrics.benchmarkExcessReturn,
        closeTo(0.026, 0.000001),
      );
      expect(result.insight.quantMetrics.stressTests, isNotEmpty);
    },
  );
}

const _seedInsight = MonthlyInsight(
  month: MonthKey(2026, 4),
  netWorthCurrent: 1462000,
  netWorthDelta: 42000,
  savingsRate: 0.284,
  savingsRateTarget: 0.3,
  budgetCompletion: 0.9,
  budgetHighlights: [
    BudgetRecapItem(label: '固定', completion: 0.94, note: '維持原本節奏即可'),
    BudgetRecapItem(label: '生活', completion: 0.87, note: '可延續目前分配'),
    BudgetRecapItem(label: '彈性', completion: 0.96, note: '下月可預留一點餘裕'),
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
    returnRate: 0.028,
    volatility: 0.12,
    sharpeRatio: 1.05,
    maxDrawdown: 0.07,
    benchmarkReturnRate: 0.02,
    benchmarkExcessReturn: 0.008,
    stressTests: [
      StressTestScenario(
        name: '溫和衝擊',
        shockRate: 0.08,
        projectedDrawdown: 0.11,
        projectedReturnRate: -0.03,
      ),
    ],
  ),
  aiTrace: AiGovernanceTrace(
    model: 'seed-l1-l2',
    source: 'dashboard_snapshot',
    status: 'seeded',
    contextHash: 'seed-ctx-202604',
  ),
  aiInterpretation: ['seed'],
  outlook: '可考慮在下月維持既有定投與預算配置。',
);
